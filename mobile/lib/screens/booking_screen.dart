import 'package:flutter/material.dart';

import '../config/app_colors.dart';

import '../models/sports_sede.dart';
import '../services/reservations_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.sede,
    required this.courts,
    required this.initialCourtId,
    required this.rates,
    required this.onSessionExpired,
  });

  final SportsSede sede;
  final List<SportsCourt> courts;
  final int initialCourtId;
  final Map<String, double> rates;
  final VoidCallback onSessionExpired;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const Color _lime = AppColors.yellow;
  static const Color _surface = AppColors.surface;
  static const Color _muted = AppColors.muted;
  static const Color _danger = AppColors.red;

  final ReservationsService _reservationsService = ReservationsService();
  late SportsCourt _selectedCourt;
  DateTime _selectedDate = _today();
  int _durationHours = 1;
  List<AvailableSlot> _availableSlots = [];
  AvailableSlot? _selectedSlot;
  ReservationsErrorType? _error;
  bool _isLoadingSlots = true;
  bool _isSubmitting = false;
  int _availabilityRequest = 0;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  double? get _hourlyRate => widget.rates[_selectedCourt.sport];

  double? get _totalPrice =>
      _hourlyRate == null ? null : _hourlyRate! * _durationHours;

  @override
  void initState() {
    super.initState();
    _selectedCourt = widget.courts.firstWhere(
      (court) => court.id == widget.initialCourtId,
      orElse: () => widget.courts.first,
    );
    _loadAvailableSlots();
  }

  Future<void> _loadAvailableSlots() async {
    final requestId = ++_availabilityRequest;
    setState(() {
      _isLoadingSlots = true;
      _error = null;
      _selectedSlot = null;
      _availableSlots = [];
    });

    try {
      final slots = await _reservationsService.getAvailableSlots(
        courtId: _selectedCourt.id,
        date: _selectedDate,
        durationHours: _durationHours,
      );
      if (!mounted || requestId != _availabilityRequest) return;
      setState(() => _availableSlots = slots);
    } on ReservationsException catch (error) {
      if (!mounted || requestId != _availabilityRequest) return;
      if (error.type == ReservationsErrorType.sessionExpired) {
        widget.onSessionExpired();
        return;
      }
      setState(() => _error = error.type);
    } finally {
      if (mounted && requestId == _availabilityRequest) {
        setState(() => _isLoadingSlots = false);
      }
    }
  }

  Future<void> _bookSelectedSlot() async {
    final slot = _selectedSlot;
    if (slot == null || _hourlyRate == null) return;

    setState(() => _isSubmitting = true);
    try {
      await _reservationsService.createReservation(
        courtId: _selectedCourt.id,
        date: _selectedDate,
        slot: slot,
      );
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _surface,
          icon: const Icon(Icons.check_circle, color: _lime, size: 42),
          title: const Text(
            'Reserva confirmada',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '${widget.sede.name} · ${_selectedCourt.courtLabel}\n'
            '${_formatDate(_selectedDate)} · ${slot.startTime} - '
            '${slot.endTime}\nTotal: ${_formatMoney(_totalPrice!)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ACEPTAR'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ReservationsException catch (error) {
      if (!mounted) return;
      if (error.type == ReservationsErrorType.sessionExpired) {
        widget.onSessionExpired();
        return;
      }
      if (error.type == ReservationsErrorType.slotUnavailable) {
        _showMessage('Ese horario acaba de ocuparse. Actualizando opciones.');
        await _loadAvailableSlots();
      } else {
        _showMessage(_errorMessage(error.type));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _errorMessage(ReservationsErrorType type) => switch (type) {
    ReservationsErrorType.sessionExpired =>
      'La sesión venció. Iniciá sesión nuevamente.',
    ReservationsErrorType.connectivity => 'No hay conexión. Verificá tu red.',
    ReservationsErrorType.server =>
      'No se pudo consultar o confirmar la reserva.',
    ReservationsErrorType.cancellationRejected =>
      'No se puede cancelar esta reserva.',
    ReservationsErrorType.slotUnavailable =>
      'El horario ya no está disponible.',
    ReservationsErrorType.tariffNotConfigured =>
      'Todavía no hay una tarifa cargada para este deporte.',
    ReservationsErrorType.invalidSelection =>
      'La fecha o el horario seleccionado no son válidos.',
  };

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHero(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCourtSelector(),
                    _buildDateSelector(),
                    _buildDurationSelector(),
                    _buildAvailability(),
                  ],
                ),
              ),
            ),
            _buildBookButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 142,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF301A1A), AppColors.background],
              ),
            ),
          ),
          const CustomPaint(painter: _BookingPitchPainter()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: Colors.white,
                      tooltip: 'Volver a sedes',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'NUEVA RESERVA',
                      style: TextStyle(
                        color: AppColors.yellow,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  widget.sede.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${_selectedCourt.sportLabel.toUpperCase()} · '
                  '${_selectedCourt.courtLabel.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 8,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtSelector() {
    return _section(
      title: 'SELECCIONÁ CANCHA',
      child: SizedBox(
        height: 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: widget.courts.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final court = widget.courts[index];
            final selected = court.id == _selectedCourt.id;
            return InkWell(
              onTap: () {
                if (selected) return;
                setState(() => _selectedCourt = court);
                _loadAvailableSlots();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(minWidth: 82, maxWidth: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? _lime : _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? _lime
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Cancha ${court.number}',
                      style: TextStyle(
                        color: selected ? Colors.black : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        court.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? Colors.black54 : _muted,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final dates = List.generate(
      7,
      (index) => _today().add(Duration(days: index)),
    );
    return _section(
      title: 'FECHA',
      child: SizedBox(
        height: 59,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: dates.length,
          separatorBuilder: (_, _) => const SizedBox(width: 7),
          itemBuilder: (context, index) {
            final date = dates[index];
            final selected = _sameDate(date, _selectedDate);
            return InkWell(
              onTap: () {
                if (selected) return;
                setState(() => _selectedDate = date);
                _loadAvailableSlots();
              },
              borderRadius: BorderRadius.circular(11),
              child: Container(
                width: 45,
                decoration: BoxDecoration(
                  color: selected ? _lime : _surface,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: selected
                        ? _lime
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      index == 0 ? 'HOY' : _weekday(date.weekday),
                      style: TextStyle(
                        color: selected ? Colors.black : _muted,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        color: selected ? Colors.black : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return _section(
      title: 'DURACIÓN',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(children: [_durationOption(1), _durationOption(2)]),
      ),
    );
  }

  Widget _durationOption(int duration) {
    final selected = _durationHours == duration;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (selected) return;
          setState(() => _durationHours = duration);
          _loadAvailableSlots();
        },
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _lime : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '$duration ${duration == 1 ? 'hora' : 'horas'}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.black : _muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailability() {
    return _section(
      title: 'HORARIOS DISPONIBLES',
      child: _isLoadingSlots
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: _lime, strokeWidth: 2),
              ),
            )
          : _error != null
          ? Column(
              children: [
                Text(
                  _errorMessage(_error!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                TextButton(
                  onPressed: _loadAvailableSlots,
                  child: const Text('REINTENTAR'),
                ),
              ],
            )
          : _availableSlots.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No hay horarios disponibles para esta fecha.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 8.0;
                final slotWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: _availableSlots
                      .map((slot) => _slotButton(slot, slotWidth))
                      .toList(),
                );
              },
            ),
    );
  }

  Widget _slotButton(AvailableSlot slot, double width) {
    final selected = _selectedSlot?.startTime == slot.startTime;
    return SizedBox(
      width: width,
      child: OutlinedButton(
        onPressed: () => setState(() => _selectedSlot = slot),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? _lime : _surface,
          foregroundColor: selected ? Colors.black : Colors.white,
          side: BorderSide(
            color: selected ? _lime : Colors.white.withValues(alpha: 0.1),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
          textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
        child: Text('${slot.startTime} - ${slot.endTime}'),
      ),
    );
  }

  Widget _buildBookButton() {
    final enabled =
        !_isSubmitting &&
        !_isLoadingSlots &&
        _selectedSlot != null &&
        _hourlyRate != null;
    final total = _totalPrice;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  total == null ? '—' : _formatMoney(total),
                  style: TextStyle(
                    color: total == null ? _muted : Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _hourlyRate == null
                      ? 'Tarifa pendiente'
                      : '${_formatMoney(_hourlyRate!)} × ${_durationHours}h',
                  style: TextStyle(
                    color: _hourlyRate == null ? _danger : _muted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: enabled ? _bookSelectedSlot : null,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  _isSubmitting
                      ? 'CONFIRMANDO'
                      : enabled
                      ? 'RESERVAR'
                      : 'ELEGÍ HORARIO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lime,
                  disabledBackgroundColor: _surface,
                  foregroundColor: Colors.black,
                  disabledForegroundColor: _muted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _lime,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }

  bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  String _weekday(int weekday) => switch (weekday) {
    DateTime.monday => 'LUN',
    DateTime.tuesday => 'MAR',
    DateTime.wednesday => 'MIÉ',
    DateTime.thursday => 'JUE',
    DateTime.friday => 'VIE',
    DateTime.saturday => 'SÁB',
    DateTime.sunday => 'DOM',
    _ => '',
  };

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  String _formatMoney(double amount) {
    final fixed = amount.toStringAsFixed(
      amount.truncateToDouble() == amount ? 0 : 2,
    );
    final parts = fixed.split('.');
    final grouped = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '\$ $grouped${parts.length == 1 ? '' : ',${parts[1]}'}';
  }
}

class _BookingPitchPainter extends CustomPainter {
  const _BookingPitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(
      Rect.fromLTWH(5, 5, size.width - 10, size.height - 10),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 5),
      Offset(size.width / 2, size.height - 5),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height * 0.18,
      paint,
    );
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width * 0.46, size.height * 0.75),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.54, size.height * 0.25),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BookingPitchPainter oldDelegate) => false;
}
