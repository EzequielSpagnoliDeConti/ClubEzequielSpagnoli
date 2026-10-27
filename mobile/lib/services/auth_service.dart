import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

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
  static const String _baseUrl = 'http://127.0.0.1:8000';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _tokenKey = 'access_token';

  Future<void> login({required String email, required String password}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AuthException(AuthErrorType.invalidCredentials);
      }

      if (response.statusCode >= 500) {
        throw const AuthException(AuthErrorType.server);
      }

      if (response.statusCode != 200) {
        throw const AuthException(AuthErrorType.server);
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic> ||
          data['access_token'] is! String ||
          (data['access_token'] as String).isEmpty) {
        throw const AuthException(AuthErrorType.server);
      }

      await _storage.write(
        key: _tokenKey,
        value: data['access_token'] as String,
      );
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

  Future<void> requestPasswordReset({required String email}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/forgot-password'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email.trim()}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 422) {
        throw const AuthException(AuthErrorType.validation);
      }

      if (response.statusCode != 202) {
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
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'nombre': nombre.trim(),
              'apellido': apellido.trim(),
              'dni': dni.trim(),
              'fecha_nacimiento': fechaNacimiento,
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 422) {
        throw const AuthException(AuthErrorType.validation);
      }

      if (response.statusCode == 400 || response.statusCode == 409) {
        throw const AuthException(AuthErrorType.registrationFailed);
      }

      if (response.statusCode >= 500 ||
          (response.statusCode != 200 && response.statusCode != 201)) {
        throw const AuthException(AuthErrorType.server);
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic> ||
          data['mensaje'] is! String ||
          data['email'] is! String) {
        throw const AuthException(AuthErrorType.server);
      }

      // El registro no inicia sesión ni guarda un token.
      return data['mensaje'] as String;
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

  Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw const AuthException(AuthErrorType.invalidCredentials);
    }

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/auth/me'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
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

  Map<String, String> _authenticatedHeaders(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<String?> getToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }
}
