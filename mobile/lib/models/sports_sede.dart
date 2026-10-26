class SportsSede {
  const SportsSede({
    required this.id,
    required this.name,
    required this.address,
    required this.openingTime,
    required this.closingTime,
    required this.courts,
  });

  factory SportsSede.fromJson(
    Map<String, dynamic> json, {
    required List<SportsCourt> courts,
  }) {
    final id = json['id'];
    if (id is! int ||
        json['nombre'] is! String ||
        json['direccion'] is! String ||
        json['hora_apertura'] is! String ||
        json['hora_cierre'] is! String) {
      throw const FormatException('Datos de sede inválidos.');
    }

    return SportsSede(
      id: id,
      name: json['nombre'] as String,
      address: json['direccion'] as String,
      openingTime: json['hora_apertura'] as String,
      closingTime: json['hora_cierre'] as String,
      courts: courts,
    );
  }

  final int id;
  final String name;
  final String address;
  final String openingTime;
  final String closingTime;
  final List<SportsCourt> courts;

  List<SportsCourt> get availableCourts => courts;

  List<String> get sports =>
      courts.map((court) => court.sport).toSet().toList();
}

class SportsCourt {
  const SportsCourt({
    required this.id,
    required this.sedeId,
    required this.sport,
    required this.number,
    required this.name,
  });

  factory SportsCourt.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! int ||
        json['sede_id'] is! int ||
        json['tipo'] is! String ||
        json['numero'] is! int ||
        json['nombre'] is! String) {
      throw const FormatException('Datos de cancha inválidos.');
    }

    return SportsCourt(
      id: json['id'] as int,
      sedeId: json['sede_id'] as int,
      sport: json['tipo'] as String,
      number: json['numero'] as int,
      name: json['nombre'] as String,
    );
  }

  final int id;
  final int sedeId;
  final String sport;
  final int number;
  final String name;

  String get sportLabel => switch (sport) {
    'FUTBOL' => 'Fútbol',
    'PADDLE' => 'Pádel',
    'BASQUET' => 'Básquet',
    'TENIS' => 'Tenis',
    'VOLEY' => 'Vóley',
    _ => sport,
  };

  String get courtLabel => name.trim().isEmpty ? 'Cancha $number' : name;
}

class HourlyRate {
  const HourlyRate({required this.sport, required this.pricePerHour});

  factory HourlyRate.fromJson(Map<String, dynamic> json) {
    final price = double.tryParse(json['precio_por_hora']?.toString() ?? '');
    if (json['tipo_espacio'] is! String || price == null || price <= 0) {
      throw const FormatException('Tarifa inválida.');
    }
    return HourlyRate(
      sport: json['tipo_espacio'] as String,
      pricePerHour: price,
    );
  }

  final String sport;
  final double pricePerHour;
}

class AvailableSlot {
  const AvailableSlot({required this.startTime, required this.endTime});

  factory AvailableSlot.fromJson(Map<String, dynamic> json) {
    final startTime = json['hora_inicio'];
    final endTime = json['hora_fin'];
    if (!_isTime(startTime) || !_isTime(endTime)) {
      throw const FormatException('Horario disponible inválido.');
    }
    return AvailableSlot(
      startTime: (startTime as String).substring(0, 5),
      endTime: (endTime as String).substring(0, 5),
    );
  }

  final String startTime;
  final String endTime;

  static bool _isTime(Object? value) =>
      value is String &&
      value.length >= 5 &&
      value[2] == ':' &&
      int.tryParse(value.substring(0, 2)) != null &&
      int.tryParse(value.substring(3, 5)) != null;
}
