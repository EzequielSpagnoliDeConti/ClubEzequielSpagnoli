class Reservation {
  const Reservation({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.sedeName,
    required this.spaceName,
    required this.sport,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['fecha']?.toString() ?? '');
    final id = json['id'];
    final startTime = json['hora_inicio'];
    final endTime = json['hora_fin'];

    if (id is! int ||
        date == null ||
        !_isValidTime(startTime) ||
        !_isValidTime(endTime) ||
        json['estado'] is! String ||
        json['sede_nombre'] is! String ||
        json['espacio_nombre'] is! String ||
        json['tipo_espacio'] is! String) {
      throw const FormatException('Datos de reserva inválidos.');
    }

    return Reservation(
      id: id,
      date: date,
      startTime: (startTime as String).substring(0, 5),
      endTime: (endTime as String).substring(0, 5),
      status: json['estado'] as String,
      sedeName: json['sede_nombre'] as String,
      spaceName: json['espacio_nombre'] as String,
      sport: json['tipo_espacio'] as String,
    );
  }

  final int id;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String status;
  final String sedeName;
  final String spaceName;
  final String sport;

  bool get isActive => status == 'ACTIVA';

  bool get isUpcoming {
    final today = DateTime.now();
    final timeParts = startTime.split(':');
    final startsAt = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
    return isActive && !startsAt.isBefore(today);
  }

  String get localizedStatus => switch (status) {
    'ACTIVA' => isUpcoming ? 'Activa' : 'Pasada',
    'CANCELADA' => 'Cancelada',
    'FINALIZADA' => 'Completada',
    _ => 'Desconocida',
  };

  String get formattedDate =>
      '${_weekday(date.weekday)}, ${date.day.toString().padLeft(2, '0')} '
      '${_month(date.month)}';

  static bool _isValidTime(Object? value) =>
      value is String &&
      value.length >= 5 &&
      value[2] == ':' &&
      int.tryParse(value.substring(0, 2)) != null &&
      int.tryParse(value.substring(3, 5)) != null;

  static String _weekday(int day) => switch (day) {
    DateTime.monday => 'lun',
    DateTime.tuesday => 'mar',
    DateTime.wednesday => 'mié',
    DateTime.thursday => 'jue',
    DateTime.friday => 'vie',
    DateTime.saturday => 'sáb',
    DateTime.sunday => 'dom',
    _ => '',
  };

  static String _month(int month) => switch (month) {
    1 => 'ene',
    2 => 'feb',
    3 => 'mar',
    4 => 'abr',
    5 => 'may',
    6 => 'jun',
    7 => 'jul',
    8 => 'ago',
    9 => 'sep',
    10 => 'oct',
    11 => 'nov',
    12 => 'dic',
    _ => '',
  };
}
