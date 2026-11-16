import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mobile/firebase_options.dart';
import 'package:mobile/config/app_colors.dart';
import 'package:mobile/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ClubApp());
}

class ClubApp extends StatefulWidget {
  const ClubApp({super.key});

  @override
  State<ClubApp> createState() => _ClubAppState();
}

class _ClubAppState extends State<ClubApp> {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSubscription;

  @override
  void initState() {
    super.initState();
    _configurarNotificaciones();
  }

  Future<void> _configurarNotificaciones() async {
    // Notificaciones recibidas con la aplicación abierta.
    _onMessageSubscription = FirebaseMessaging.onMessage.listen(
      _mostrarNotificacion,
    );

    // Notificaciones abiertas desde segundo plano.
    _onMessageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      _mostrarNotificacion(message, mensajeAccion: 'Abriste una notificación');
    });

    // Notificación que abrió la aplicación desde estado cerrado.
    try {
      final mensajeInicial = await FirebaseMessaging.instance
          .getInitialMessage();

      if (mensajeInicial != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mostrarNotificacion(
            mensajeInicial,
            mensajeAccion: 'Abriste una notificación',
          );
        });
      }
    } catch (e) {
      debugPrint('Error al recuperar la notificación inicial: $e');
    }
  }

  void _mostrarNotificacion(RemoteMessage message, {String? mensajeAccion}) {
    final notificacion = message.notification;

    final titulo = notificacion?.title ?? 'Club';
    final cuerpo = notificacion?.body ?? 'Tenés una nueva notificación.';

    final messenger = _messengerKey.currentState;

    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mensajeAccion ?? titulo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(cuerpo),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  void dispose() {
    _onMessageSubscription?.cancel();
    _onMessageOpenedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Club Ezequiel Spagnoli',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: AppColors.yellow,
              brightness: Brightness.dark,
            ).copyWith(
              primary: AppColors.yellow,
              secondary: AppColors.yellow,
              error: AppColors.red,
              surface: AppColors.surface,
              onPrimary: Colors.black,
              onSecondary: Colors.black,
            ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.yellow,
            foregroundColor: Colors.black,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.yellow),
        ),
        dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.surface,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
