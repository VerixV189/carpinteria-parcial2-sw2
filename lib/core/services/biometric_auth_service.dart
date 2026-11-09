import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Verifica si el dispositivo cuenta con lector de huella o biometría configurada.
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Solicita autenticación por huella digital (con respaldo de bloqueo del dispositivo).
  Future<({bool authenticated, String? error})> authenticateWithFingerprint({
    String reason =
        'Coloca tu huella digital en el sensor para ingresar a Carpintería El Roble',
  }) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) {
        return (
          authenticated: false,
          error:
              'Este dispositivo no tiene un sensor de huella activo o configurado.',
        );
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        return (authenticated: true, error: null);
      }
      return (
        authenticated: false,
        error: 'Autenticación por huella cancelada.',
      );
    } on LocalAuthException catch (e) {
      return (
        authenticated: false,
        error: 'No se pudo verificar la huella (${e.code.name}).',
      );
    } on PlatformException catch (e) {
      return (
        authenticated: false,
        error: e.message ?? 'Error al leer el sensor de huella.',
      );
    } catch (e) {
      return (
        authenticated: false,
        error: 'Error en el lector de huella: $e',
      );
    }
  }
}

