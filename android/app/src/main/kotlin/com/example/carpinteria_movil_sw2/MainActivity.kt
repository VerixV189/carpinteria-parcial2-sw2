package com.example.carpinteria_movil_sw2

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.res.AssetManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.atomic.AtomicInteger

class MainActivity : FlutterFragmentActivity() {

    private val METHOD_CHANNEL = "carpinteria/model_copy"
    private val EVENT_CHANNEL  = "carpinteria/model_copy_progress"
    private val PUSH_CHANNEL   = "carpinteria/push_notifications"
    private val NOTIFICATION_CHANNEL_ID = "el_roble_push_channel"

    private var progressSink: EventChannel.EventSink? = null
    private var copyJob: Job? = null
    private val notificationIdCounter = AtomicInteger(1001)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createPushNotificationChannel()

        // ── Native Push Notification channel ──────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PUSH_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "showPushNotification" -> {
                        val title = call.argument<String>("title") ?: "Carpintería El Roble"
                        val body = call.argument<String>("body") ?: ""
                        showNativeNotification(title, body)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

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

    private fun createPushNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Avisos Carpintería El Roble"
            val descriptionText = "Notificaciones de informes, cotizaciones, pedidos, pagos y despachos"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(NOTIFICATION_CHANNEL_ID, name, importance).apply {
                description = descriptionText
                enableVibration(true)
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showNativeNotification(title: String, body: String) {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getActivity(this, 0, intent, pendingIntentFlags)

            val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)

            NotificationManagerCompat.from(this)
                .notify(notificationIdCounter.getAndIncrement(), builder.build())
        } catch (_: SecurityException) {
            // Permiso POST_NOTIFICATIONS aún no concedido en Android 13+
        } catch (_: Exception) {
        }
    }
}
