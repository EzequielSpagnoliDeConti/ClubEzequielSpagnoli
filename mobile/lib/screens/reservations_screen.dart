import 'package:flutter/material.dart';

import '../models/reservation.dart';
import '../services/reservations_service.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key, required this.onSessionExpired});

  final VoidCallback onSessionExpired;

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  static const Color _lime = Color(0xFFD7FF00);
  static const Color _surface = Color(0xFF1B1B1E);
  static const Color _muted = Color(0xFF8A8A90);
  static const Color _danger = Color(0xFFFF5B5B);
  static const Color _success = Color(0xFF65D69A);

  final ReservationsService _reservationsService = ReservationsService();
  List<Reservation> _reservations = [];
  ReservationsErrorType? _error;
  bool _isLoading = true;
  bool _showHistory = false;
  int? _cancellingReservationId;

  List<Reservation> get _upcomingReservations {
    final reservations = _reservations
        .where((reservation) => reservation.isUpcoming)
        .toList();
    reservations.sort((a, b) {
      final dateOrder = a.date.compareTo(b.date);
      return dateOrder != 0 ? dateOrder : a.startTime.compareTo(b.startTime);
    });
    return reservations;
  }

  List<Reservation> get _pastReservations {
    final reservations = _reservations
        .where((reservation) => !reservation.isUpcoming)
        .toList();
    reservations.sort((a, b) {
      final dateOrder = b.date.compareTo(a.date);
      return dateOrder != 0 ? dateOrder : b.startTime.compareTo(a.startTime);
    });
    return reservations;
  }

  List<Reservation> get _visibleReservations =>
      _showHistory ? _pastReservations : _upcomingReservations;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reservations = await _reservationsService.getMyReservations();
      if (!mounted) return;
      setState(() => _reservations = reservations);
    } on ReservationsException catch (error) {
      if (!mounted) return;
      if (error.type == ReservationsErrorType.sessionExpired) {
        widget.onSessionExpired();
        return;
      }
      setState(() => _error = error.type);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelReservation(Reservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text(
          'Cancelar reserva',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Querés cancelar la reserva en ${reservation.sedeName} '
          'del ${reservation.formattedDate}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('VOLVER'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'CANCELAR RESERVA',
              style: TextStyle(color: _danger, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _cancellingReservationId = reservation.id);

    try {
      await _reservationsService.cancelReservation(reservation.id);
      await _loadReservations();
      if (mounted) _showMessage('La reserva fue cancelada.');
    } on ReservationsException catch (error) {
      if (!mounted) return;
      if (error.type == ReservationsErrorType.sessionExpired) {
        widget.onSessionExpired();
        return;
      }
      _showMessage(_errorMessage(error.type));
    } finally {
      if (mounted) setState(() => _cancellingReservationId = null);
    }
  }

  String _errorMessage(ReservationsErrorType type) => switch (type) {
    ReservationsErrorType.sessionExpired =>
      'La sesión venció. Iniciá sesión nuevamente.',
    ReservationsErrorType.connectivity => 'No hay conexión. Verificá tu red.',
    ReservationsErrorType.server => 'No se pudieron cargar las reservas.',
    ReservationsErrorType.cancellationRejected =>
      'No se puede cancelar esta reserva.',
    ReservationsErrorType.slotUnavailable =>
      'El horario seleccionado ya no está disponible.',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MIS RESERVAS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${_upcomingReservations.length} próximas · '
                '${_pastReservations.length} en historial',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    _buildTab(
                      label: 'Próximas (${_upcomingReservations.length})',
                      isSelected: !_showHistory,
                      onTap: () => setState(() => _showHistory = false),
                    ),
                    _buildTab(
                      label: 'Historial',
                      isSelected: _showHistory,
                      onTap: () => setState(() => _showHistory = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: _lime,
            backgroundColor: _surface,
            onRefresh: _loadReservations,
            child: _buildReservationList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: isSelected ? _lime : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReservationList() {
    if (_isLoading && _reservations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _lime, strokeWidth: 2),
      );
    }

    if (_error != null && _reservations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 70),
          const Icon(Icons.cloud_off_outlined, color: _muted, size: 42),
          const SizedBox(height: 12),
          Text(
            _errorMessage(_error!),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _loadReservations,
              icon: const Icon(Icons.refresh),
              label: const Text('REINTENTAR'),
              style: TextButton.styleFrom(foregroundColor: _lime),
            ),
          ),
        ],
      );
    }

    if (_visibleReservations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        children: [
          const SizedBox(height: 90),
          Icon(
            _showHistory
                ? Icons.history_rounded
                : Icons.event_available_outlined,
            color: _muted,
            size: 44,
          ),
          const SizedBox(height: 14),
          Text(
            _showHistory
                ? 'Todavía no tenés reservas en el historial.'
                : 'No se encontraron próximas reservas asociadas a tu cuenta.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _visibleReservations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildReservationCard(_visibleReservations[index]),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    final statusColor = switch (reservation.status) {
      'ACTIVA' => reservation.isUpcoming ? _lime : _muted,
      'FINALIZADA' => _success,
      _ => _danger,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _sportIcon(reservation.sport),
                  color: _lime,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.sedeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      reservation.spaceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  reservation.localizedStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: _muted,
                size: 13,
              ),
              const SizedBox(width: 6),
              Text(
                reservation.formattedDate,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.access_time, color: _muted, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${reservation.startTime} - ${reservation.endTime}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
          if (!_showHistory && reservation.isActive) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Colors.white12),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _cancellingReservationId == reservation.id
                    ? null
                    : () => _cancelReservation(reservation),
                icon: _cancellingReservationId == reservation.id
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _danger,
                        ),
                      )
                    : const Icon(Icons.close, size: 14),
                label: Text(
                  _cancellingReservationId == reservation.id
                      ? 'Cancelando'
                      : 'Cancelar',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _danger,
                  side: BorderSide(color: _danger.withValues(alpha: 0.4)),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _sportIcon(String type) => switch (type) {
    'TENIS' => Icons.sports_tennis,
    'FUTBOL' => Icons.sports_soccer,
    'PADDLE' => Icons.sports_tennis,
    'BASQUET' => Icons.sports_basketball,
    'VOLEY' => Icons.sports_volleyball,
    _ => Icons.sports,
  };
}
