import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/reservation.dart';
import '../models/sports_sede.dart';
import 'auth_service.dart';

enum ReservationsErrorType {
  sessionExpired,
  connectivity,
  server,
  cancellationRejected,
  slotUnavailable,
  tariffNotConfigured,
  invalidSelection,
}

class ReservationsException implements Exception {
  const ReservationsException(this.type);

  final ReservationsErrorType type;
}

class ReservationsService {
  static const String _baseUrl = 'http://127.0.0.1:8000';

  final AuthService _authService = AuthService();

  Future<List<Reservation>> getMyReservations() async {
    final token = await _getToken();

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/reservas/mias'), headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      await _checkUnauthorized(response.statusCode);

      if (response.statusCode != 200) {
        throw const ReservationsException(ReservationsErrorType.server);
      }

      final data = jsonDecode(response.body);
      if (data is! List) {
        throw const ReservationsException(ReservationsErrorType.server);
      }

      return data
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const ReservationsException(ReservationsErrorType.server);
            }
            try {
              return Reservation.fromJson(item);
            } on FormatException {
              throw const ReservationsException(ReservationsErrorType.server);
            }
          })
          .toList(growable: false);
    } on ReservationsException {
      rethrow;
    } on SocketException {
      throw const ReservationsException(ReservationsErrorType.connectivity);
    } on TimeoutException {
      throw const ReservationsException(ReservationsErrorType.server);
    } on http.ClientException {
      throw const ReservationsException(ReservationsErrorType.connectivity);
    } on FormatException {
      throw const ReservationsException(ReservationsErrorType.server);
    }
  }

  Future<void> cancelReservation(int reservationId) async {
    final token = await _getToken();

    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/reservas/$reservationId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 15));

      await _checkUnauthorized(response.statusCode);

      if (response.statusCode == 409) {
        throw const ReservationsException(
          ReservationsErrorType.cancellationRejected,
        );
      }

      if (response.statusCode != 204) {
        throw const ReservationsException(ReservationsErrorType.server);
      }
    } on ReservationsException {
      rethrow;
    } on SocketException {
      throw const ReservationsException(ReservationsErrorType.connectivity);
    } on TimeoutException {
      throw const ReservationsException(ReservationsErrorType.server);
    } on http.ClientException {
      throw const ReservationsException(ReservationsErrorType.connectivity);
    }
  }

  Future<List<AvailableSlot>> getAvailableSlots({
    required int courtId,
    required DateTime date,
    required int durationHours,
  }) async {
    final token = await _getToken();

    try {
      final dateValue =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      final uri = Uri.parse('$_baseUrl/reservas/disponibilidad/$courtId')
          .replace(
            queryParameters: {
              'fecha': dateValue,
              'duracion_horas': '$durationHours',
            },
          );
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      await _checkUnauthorized(response.statusCode);

      if (response.statusCode != 200) {
        throw const ReservationsException(ReservationsErrorType.server);
      }

      final data = jsonDecode(response.body);
      if (data is! List) {
        throw const ReservationsException(ReservationsErrorType.server);
      }
      return data
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const ReservationsException(ReservationsErrorType.server);
            }
            try {
              return AvailableSlot.fromJson(item);
            } on FormatException {
              throw const ReservationsException(ReservationsErrorType.server);
            }
          })
          .toList(growable: false);
    } on ReservationsException {
      rethrow;
    } on SocketException {
      throw const ReservationsException(ReservationsErrorType.connectivity);
    } on TimeoutException {
      throw const ReservationsException(ReservationsErrorType.server);
    } on http.ClientException {
      throw const ReservationsException(ReservationsErrorType.connectivity);
    } on FormatException {
      throw const ReservationsException(ReservationsErrorType.server);
    }
  }

  Future<void> createReservation({
    required int courtId,
    required DateTime date,
    required AvailableSlot slot,
  }) async {
    final token = await _getToken();

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/reservas/mias'),
            headers: {..._headers(token), 'Content-Type': 'application/json'},
            body: jsonEncode({
              'espacio_deportivo_id': courtId,
              'fecha':
                  '${date.year.toString().padLeft(4, '0')}-'
                  '${date.month.toString().padLeft(2, '0')}-'
                  '${date.day.toString().padLeft(2, '0')}',
              'hora_inicio': '${slot.startTime}:00',
              'hora_fin': '${slot.endTime}:00',
            }),
          )
          .timeout(const Duration(seconds: 15));

      await _checkUnauthorized(response.statusCode);

      if (response.statusCode == 409) {
        final detail = _responseDetail(response.body);
        if (detail?.contains('tarifa') == true) {
          throw const ReservationsException(
            ReservationsErrorType.tariffNotConfigured,
          );
        }
        throw const ReservationsException(
          ReservationsErrorType.slotUnavailable,
        );
      }

      if (response.statusCode == 422) {
        throw const ReservationsException(
          ReservationsErrorType.invalidSelection,
        );
      }

      if (response.statusCode != 201) {
        throw const ReservationsException(ReservationsErrorType.server);
      }
    } on ReservationsException {
      rethrow;
    } on SocketException {
      throw const ReservationsException(ReservationsErrorType.connectivity);
    } on TimeoutException {
      throw const ReservationsException(ReservationsErrorType.server);
    } on http.ClientException {
      throw const ReservationsException(ReservationsErrorType.connectivity);
    } on FormatException {
      throw const ReservationsException(ReservationsErrorType.server);
    }
  }

  String? _responseDetail(String body) {
    final data = jsonDecode(body);
    if (data is Map<String, dynamic> && data['detail'] is String) {
      return data['detail'] as String;
    }
    return null;
  }

  Future<String> _getToken() async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      throw const ReservationsException(ReservationsErrorType.sessionExpired);
    }
    return token;
  }

  Future<void> _checkUnauthorized(int statusCode) async {
    if (statusCode == 401 || statusCode == 403) {
      await _authService.logout();
      throw const ReservationsException(ReservationsErrorType.sessionExpired);
    }
  }

  Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
