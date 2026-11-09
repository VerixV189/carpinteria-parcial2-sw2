package com.example.carpinteria_movil_sw2

import android.content.res.AssetManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {

    private val METHOD_CHANNEL = "carpinteria/model_copy"
    private val EVENT_CHANNEL  = "carpinteria/model_copy_progress"

    private var progressSink: EventChannel.EventSink? = null
    private var copyJob: Job? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Progress event channel ────────────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                    progressSink = sink
                }
                override fun onCancel(args: Any?) {
                    progressSink = null
                }
            })

        // ── Method channel ────────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // copyAsset(assetPath, destPath) → bool
                    "copyAsset" -> {
                        val assetPath = call.argument<String>("assetPath") ?: run {
                            result.error("MISSING_ARG", "assetPath is required", null)
                            return@setMethodCallHandler
                        }
                        val destPath = call.argument<String>("destPath") ?: run {
                            result.error("MISSING_ARG", "destPath is required", null)
                            return@setMethodCallHandler
                        }

                        copyJob = CoroutineScope(Dispatchers.IO).launch {
                            try {
                                copyAssetStreaming(assetPath, destPath)
                                withContext(Dispatchers.Main) { result.success(true) }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("COPY_ERROR", e.message, null)
                                }
                            }
                        }
                    }

                    // fileExists(path) → bool
                    "fileExists" -> {
                        val path = call.argument<String>("path") ?: run {
                            result.error("MISSING_ARG", "path is required", null)
                            return@setMethodCallHandler
                        }
                        result.success(File(path).exists())
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Copia un asset al destino usando streaming (buffer de 2 MB).
     * Emite progreso [0.0 .. 1.0] por el EventChannel.
     *
     * IMPORTANTE: los assets de Flutter se almacenan bajo "flutter_assets/"
     * dentro del APK, por eso se añade ese prefijo al path.
     */
    private fun copyAssetStreaming(assetPath: String, destPath: String) {
        val am: AssetManager = assets

        // Flutter guarda sus assets bajo "flutter_assets/" en el APK
        val apkPath = "flutter_assets/$assetPath"

        // Intentar obtener el tamaño real; si falla seguimos sin progreso exacto
        val totalBytes: Long = try {
            am.openFd(apkPath).use { it.length }
        } catch (_: Exception) {
            -1L
        }

        val bufSize = 2 * 1024 * 1024   // 2 MB buffer

        // ACCESS_STREAMING es más eficiente para archivos grandes
        am.open(apkPath, AssetManager.ACCESS_STREAMING).use { input ->
            FileOutputStream(File(destPath)).use { output ->
                val buffer = ByteArray(bufSize)
                var written = 0L
                var read: Int

                while (input.read(buffer).also { read = it } != -1) {
                    output.write(buffer, 0, read)
                    written += read

                    val progress = if (totalBytes > 0) written.toDouble() / totalBytes else 0.0
                    CoroutineScope(Dispatchers.Main).launch {
                        progressSink?.success(progress)
                    }
                }
                output.flush()
            }
        }
    }
}
