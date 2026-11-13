import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';

enum AuthErrorType {
  invalidCredentials,
  connectivity,
  server,
  registrationFailed,
  validation,
  sessionExpired,
  profileUpdateFailed,
  accountDeactivationFailed,
  passwordResetFailed,
}

class AuthException implements Exception {
  final AuthErrorType type;

  const AuthException(this.type);
}

class AuthService {
  // Para ejecutar Flutter en Windows y FastAPI en la misma PC.
  static const String _baseUrl = ApiConfig.baseUrl;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> getToken() async {
    return _firebaseAuth.currentUser?.getIdToken();
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  Map<String, String> _authenticatedHeaders(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<void> login({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' ||
          e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-email') {
        throw const AuthException(AuthErrorType.invalidCredentials);
      }

      if (e.code == 'network-request-failed') {
        throw const AuthException(AuthErrorType.connectivity);
      }

      throw const AuthException(AuthErrorType.server);
    }
  }

  Future<void> requestPasswordReset({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        throw const AuthException(AuthErrorType.validation);
      }

      if (e.code == 'network-request-failed') {
        throw const AuthException(AuthErrorType.connectivity);
      }

      throw const AuthException(AuthErrorType.passwordResetFailed);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/reset-password'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim(),
              'token': token.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 400 || response.statusCode == 422) {
        throw const AuthException(AuthErrorType.passwordResetFailed);
      }

      if (response.statusCode != 200) {
        throw const AuthException(AuthErrorType.server);
      }
    } on AuthException {
      rethrow;
    } on SocketException {
      throw const AuthException(AuthErrorType.connectivity);
    } on TimeoutException {
      throw const AuthException(AuthErrorType.server);
    } on http.ClientException {
      throw const AuthException(AuthErrorType.connectivity);
    } on FormatException {
      throw const AuthException(AuthErrorType.server);
    }
  }

  Future<String> register({
    required String nombre,
    required String apellido,
    required String dni,
    required String fechaNacimiento,
    required String email,
    required String password,
  }) async {
    UserCredential? credential;

    try {
      credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const AuthException(AuthErrorType.registrationFailed);
      }

      if (e.code == 'weak-password' || e.code == 'invalid-email') {
        throw const AuthException(AuthErrorType.validation);
      }

      if (e.code == 'network-request-failed') {
        throw const AuthException(AuthErrorType.connectivity);
      }

      throw const AuthException(AuthErrorType.server);
    }

    try {
      final user = credential.user;

      if (user == null) {
        throw const AuthException(AuthErrorType.server);
      }

      final idToken = await user.getIdToken(true);

      if (idToken == null || idToken.isEmpty) {
        throw const AuthException(AuthErrorType.server);
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'nombre': nombre.trim(),
              'apellido': apellido.trim(),
              'dni': dni.trim(),
              'fecha_nacimiento': fechaNacimiento,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 409) {
        throw const AuthException(AuthErrorType.registrationFailed);
      }

      if (response.statusCode == 422) {
        throw const AuthException(AuthErrorType.validation);
      }

      if (response.statusCode != 201) {
        throw const AuthException(AuthErrorType.server);
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic> || data['mensaje'] is! String) {
        throw const AuthException(AuthErrorType.server);
      }

      // El registro no debe dejar la sesión iniciada.
      await _firebaseAuth.signOut();

      return data['mensaje'] as String;
    } on AuthException {
      await _firebaseAuth.signOut();
      rethrow;
    } on SocketException {
      await _firebaseAuth.signOut();
      throw const AuthException(AuthErrorType.connectivity);
    } on TimeoutException {
      await _firebaseAuth.signOut();
      throw const AuthException(AuthErrorType.server);
    } on http.ClientException {
      await _firebaseAuth.signOut();
      throw const AuthException(AuthErrorType.connectivity);
    } on FormatException {
      await _firebaseAuth.signOut();
      throw const AuthException(AuthErrorType.server);
    } catch (_) {
      await _firebaseAuth.signOut();
      throw const AuthException(AuthErrorType.server);
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const AuthException(AuthErrorType.invalidCredentials);
    }

    try {
      final token = await user.getIdToken();

      if (token == null || token.isEmpty) {
        throw const AuthException(AuthErrorType.sessionExpired);
      }

      final response = await http
          .get(
            Uri.parse('$_baseUrl/auth/me'),
            headers: _authenticatedHeaders(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        await logout();
        throw const AuthException(AuthErrorType.sessionExpired);
      }

      if (response.statusCode != 200) {
        throw const AuthException(AuthErrorType.server);
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw const AuthException(AuthErrorType.server);
      }

      return data;
    } on AuthException {
      rethrow;
    } on SocketException {
      throw const AuthException(AuthErrorType.connectivity);
    } on TimeoutException {
      throw const AuthException(AuthErrorType.server);
    } on http.ClientException {
      throw const AuthException(AuthErrorType.connectivity);
    } on FormatException {
      throw const AuthException(AuthErrorType.server);
    }
  }

  Future<Map<String, dynamic>> updateCurrentUser({
    required String nombre,
    required String apellido,
    required String dni,
    required String fechaNacimiento,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw const AuthException(AuthErrorType.invalidCredentials);
    }

    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/auth/me'),
            headers: {
              ..._authenticatedHeaders(token),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'nombre': nombre.trim(),
              'apellido': apellido.trim(),
              'dni': dni.trim(),
              'fecha_nacimiento': fechaNacimiento,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        await logout();
        throw const AuthException(AuthErrorType.sessionExpired);
      }

      if (response.statusCode == 422) {
        throw const AuthException(AuthErrorType.validation);
      }

      if (response.statusCode == 409) {
        throw const AuthException(AuthErrorType.profileUpdateFailed);
      }

      if (response.statusCode != 200) {
        throw const AuthException(AuthErrorType.server);
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw const AuthException(AuthErrorType.server);
      }

      return data;
    } on AuthException {
      rethrow;
    } on SocketException {
      throw const AuthException(AuthErrorType.connectivity);
    } on TimeoutException {
      throw const AuthException(AuthErrorType.server);
    } on http.ClientException {
      throw const AuthException(AuthErrorType.connectivity);
    } on FormatException {
      throw const AuthException(AuthErrorType.server);
    }
  }

  Future<void> deactivateCurrentUser() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw const AuthException(AuthErrorType.invalidCredentials);
    }

    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/auth/me'),
            headers: _authenticatedHeaders(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        await logout();
        throw const AuthException(AuthErrorType.sessionExpired);
      }

      if (response.statusCode != 204) {
        throw const AuthException(AuthErrorType.accountDeactivationFailed);
      }

      await logout();
    } on AuthException {
      rethrow;
    } on SocketException {
      throw const AuthException(AuthErrorType.connectivity);
    } on TimeoutException {
      throw const AuthException(AuthErrorType.server);
    } on http.ClientException {
      throw const AuthException(AuthErrorType.connectivity);
    }
  }
}
