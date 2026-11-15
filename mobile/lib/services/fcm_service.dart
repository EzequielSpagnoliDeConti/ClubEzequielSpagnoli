import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';

class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final AuthService _authService = AuthService();

  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<void> registerDevice() async {
    try {
      // Solicita permiso para recibir notificaciones.
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint('Permiso de notificaciones no concedido.');
        return;
      }

      // Evita registrar múltiples listeners.
      await _tokenRefreshSubscription?.cancel();

      // Escucha los cambios del token FCM.
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
        (newToken) async {
          // Comprueba que todavía exista una sesión Firebase.
          if (FirebaseAuth.instance.currentUser == null) {
            return;
          }

          try {
            await _authService.registerFcmDevice(newToken);
            debugPrint('Token FCM actualizado en el backend.');
          } catch (e) {
            debugPrint('Error al actualizar token FCM: $e');
          }
        },
        onError: (error) {
          debugPrint('Error escuchando cambios del token FCM: $error');
        },
      );

      // Obtiene y registra el token actual.
      final token = await _messaging.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('No se pudo obtener el token FCM.');
        return;
      }

      await _authService.registerFcmDevice(token);

      debugPrint('Dispositivo FCM registrado correctamente.');
    } catch (e) {
      // FCM nunca debe impedir el inicio de sesión.
      debugPrint('Error al registrar dispositivo FCM: $e');
    }
  }

  Future<void> stopListening() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  Future<void> unregisterDevice() async {
    try {
      // Obtiene el token actual del dispositivo.
      final token = await _messaging.getToken();

      if (token != null && token.isNotEmpty) {
        // Desactiva el token en el backend.
        await _authService.deactivateFcmDevice(token);

        debugPrint('Dispositivo FCM desactivado correctamente.');
      }
    } catch (e) {
      // Un error de FCM no debe impedir cerrar la sesión.
      debugPrint('Error al desactivar dispositivo FCM: $e');
    } finally {
      // Detiene la escucha de renovaciones.
      await stopListening();
    }
  }
}
