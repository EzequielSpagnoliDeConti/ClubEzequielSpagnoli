import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/sports_sede.dart';

enum SedeErrorType { connectivity, server }

class SedeException implements Exception {
  const SedeException(this.type);

  final SedeErrorType type;
}

class SedeCatalog {
  const SedeCatalog({required this.sedes, required this.rates});

  final List<SportsSede> sedes;
  final Map<String, double> rates;
}

class SedesService {
  static const String _baseUrl = 'http://127.0.0.1:8000';

  Future<SedeCatalog> getCatalog() async {
    try {
      final responses = await Future.wait([
        http
            .get(Uri.parse('$_baseUrl/sedes'), headers: _headers)
            .timeout(const Duration(seconds: 15)),
        http
            .get(Uri.parse('$_baseUrl/espacios-deportivos'), headers: _headers)
            .timeout(const Duration(seconds: 15)),
        http
            .get(Uri.parse('$_baseUrl/tarifas'), headers: _headers)
            .timeout(const Duration(seconds: 15)),
      ]);

      if (responses.any((response) => response.statusCode != 200)) {
        throw const SedeException(SedeErrorType.server);
      }

      final sedesJson = jsonDecode(responses[0].body);
      final courtsJson = jsonDecode(responses[1].body);
      final ratesJson = jsonDecode(responses[2].body);
      if (sedesJson is! List || courtsJson is! List || ratesJson is! List) {
        throw const SedeException(SedeErrorType.server);
      }

      final courts = courtsJson.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const SedeException(SedeErrorType.server);
        }
        try {
          return SportsCourt.fromJson(item);
        } on FormatException {
          throw const SedeException(SedeErrorType.server);
        }
      }).toList();

      final sedes = sedesJson.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const SedeException(SedeErrorType.server);
        }
        try {
          return SportsSede.fromJson(
            item,
            courts: courts
                .where((court) => court.sedeId == item['id'])
                .toList(),
          );
        } on FormatException {
          throw const SedeException(SedeErrorType.server);
        }
      }).toList();

      final rates = <String, double>{};
      for (final item in ratesJson) {
        if (item is! Map<String, dynamic>) {
          throw const SedeException(SedeErrorType.server);
        }
        try {
          final rate = HourlyRate.fromJson(item);
          rates[rate.sport] = rate.pricePerHour;
        } on FormatException {
          throw const SedeException(SedeErrorType.server);
        }
      }

      return SedeCatalog(sedes: sedes, rates: rates);
    } on SedeException {
      rethrow;
    } on SocketException {
      throw const SedeException(SedeErrorType.connectivity);
    } on TimeoutException {
      throw const SedeException(SedeErrorType.server);
    } on http.ClientException {
      throw const SedeException(SedeErrorType.connectivity);
    } on FormatException {
      throw const SedeException(SedeErrorType.server);
    }
  }

  static const Map<String, String> _headers = {'Accept': 'application/json'};
}
