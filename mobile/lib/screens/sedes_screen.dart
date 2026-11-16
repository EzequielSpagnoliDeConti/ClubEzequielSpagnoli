import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../models/sports_sede.dart';
import '../services/sedes_service.dart';
import 'booking_screen.dart';

class SedesScreen extends StatefulWidget {
  const SedesScreen({super.key, required this.onSessionExpired});

  final VoidCallback onSessionExpired;

  @override
  State<SedesScreen> createState() => _SedesScreenState();
}

class _SedesScreenState extends State<SedesScreen> {
  static const Color _lime = AppColors.yellow;
  static const Color _surface = AppColors.surface;
  static const Color _muted = AppColors.muted;

  final SedesService _sedesService = SedesService();
  SedeCatalog? _catalog;
  SedeErrorType? _error;
  String? _selectedSport;
  bool _isLoading = true;

  List<String> get _sports =>
      _catalog?.sedes.expand((sede) => sede.sports).toSet().toList() ?? [];

  List<SportsSede> get _visibleSedes {
    final sedes = _catalog?.sedes ?? [];
    if (_selectedSport == null) return sedes;
    return sedes
        .map(
          (sede) => SportsSede(
            id: sede.id,
            name: sede.name,
            address: sede.address,
            openingTime: sede.openingTime,
            closingTime: sede.closingTime,
            courts: sede.courts
                .where((court) => court.sport == _selectedSport)
                .toList(),
          ),
        )
        .where((sede) => sede.courts.isNotEmpty)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final catalog = await _sedesService.getCatalog();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        if (_selectedSport != null &&
            !catalog.sedes.any(
              (sede) => sede.sports.contains(_selectedSport),
            )) {
          _selectedSport = null;
        }
      });
    } on SedeException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.type);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TODAS LAS SEDES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Elegí una sede y encontrá tu próxima cancha.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              if (!_isLoading && _catalog != null && _sports.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _sportFilterChip(
                        label: 'Todos',
                        selected: _selectedSport == null,
                        onTap: () => setState(() => _selectedSport = null),
                      ),
                      ..._sports.map(
                        (sport) => _sportFilterChip(
                          label: _sportLabel(sport),
                          selected: _selectedSport == sport,
                          onTap: () => setState(() => _selectedSport = sport),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(child: _buildSedes()),
      ],
    );
  }

  Widget _sportFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          color: selected ? Colors.black : Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        backgroundColor: _surface,
        selectedColor: _lime,
        side: BorderSide(
          color: selected ? _lime : Colors.white.withValues(alpha: 0.1),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildSedes() {
    if (_isLoading && _catalog == null) {
      return const Center(
        child: CircularProgressIndicator(color: _lime, strokeWidth: 2),
      );
    }

    if (_error != null && _catalog == null) {
      return _messageState(
        icon: Icons.cloud_off_outlined,
        message: _error == SedeErrorType.connectivity
            ? 'No hay conexión. Verificá tu red.'
            : 'No se pudieron cargar las sedes.',
        action: TextButton(
          onPressed: _loadCatalog,
          child: const Text('REINTENTAR'),
        ),
      );
    }

    if (_visibleSedes.isEmpty) {
      return _messageState(
        icon: Icons.location_city_outlined,
        message: _selectedSport == null
            ? 'Todavía no hay sedes disponibles.'
            : 'No hay sedes con canchas de ${_sportLabel(_selectedSport!)}.',
      );
    }

    final catalog = _catalog!;
    return RefreshIndicator(
      color: _lime,
      backgroundColor: _surface,
      onRefresh: _loadCatalog,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _visibleSedes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 13),
        itemBuilder: (context, index) {
          final sede = _visibleSedes[index];
          return _SedeCard(
            sede: sede,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SedeDetailScreen(
                  sede: sede,
                  rates: catalog.rates,
                  onSessionExpired: widget.onSessionExpired,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 75),
        Icon(icon, color: _muted, size: 44),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: 12),
          Center(child: action),
        ],
      ],
    );
  }

  String _sportLabel(String sport) => switch (sport) {
    'FUTBOL' => 'Fútbol',
    'PADDLE' => 'Pádel',
    'BASQUET' => 'Básquet',
    'TENIS' => 'Tenis',
    'VOLEY' => 'Vóley',
    _ => sport,
  };
}

class _SedeCard extends StatelessWidget {
  const _SedeCard({required this.sede, required this.onTap});

  static const Color _lime = AppColors.yellow;
  static const Color _surface = AppColors.surface;
  static const Color _muted = AppColors.muted;

  final SportsSede sede;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sports = sede.sports;
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          height: 148,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 104,
                height: 126,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF301A1A), Color(0xFF101010)],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const CustomPaint(painter: _SedePitchPainter()),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Icon(Icons.sports, color: _lime, size: 24),
                    ),
                    Positioned(
                      right: 11,
                      top: 11,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${sede.courts.length} ${sede.courts.length == 1 ? 'cancha' : 'canchas'}',
                          style: const TextStyle(
                            color: _lime,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        sede.name.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: _muted,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              sede.address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (sports.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: sports
                              .map(
                                (sport) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF302900),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _sportLabel(sport),
                                    style: const TextStyle(
                                      color: _lime,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const Row(
                        children: [
                          Text(
                            'VER SEDE',
                            style: TextStyle(
                              color: _lime,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: _lime,
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sportLabel(String sport) => switch (sport) {
    'FUTBOL' => 'Fútbol',
    'PADDLE' => 'Pádel',
    'BASQUET' => 'Básquet',
    'TENIS' => 'Tenis',
    'VOLEY' => 'Vóley',
    _ => sport,
  };
}

class SedeDetailScreen extends StatefulWidget {
  const SedeDetailScreen({
    super.key,
    required this.sede,
    required this.rates,
    required this.onSessionExpired,
  });

  final SportsSede sede;
  final Map<String, double> rates;
  final VoidCallback onSessionExpired;

  @override
  State<SedeDetailScreen> createState() => _SedeDetailScreenState();
}

class _SedeDetailScreenState extends State<SedeDetailScreen> {
  static const Color _lime = AppColors.yellow;
  static const Color _surface = AppColors.surface;
  static const Color _muted = AppColors.muted;

  String? _selectedSport;

  List<String> get _sports => widget.sede.sports;

  List<SportsCourt> get _visibleCourts {
    if (_selectedSport == null) return widget.sede.courts;
    return widget.sede.courts
        .where((court) => court.sport == _selectedSport)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    if (_sports.length == 1) _selectedSport = _sports.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        title: const Text(
          'Sedes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 150,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF301A1A), AppColors.background],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: _SedePitchPainter()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'SEDE DEPORTIVA',
                        style: TextStyle(
                          color: _lime,
                          fontSize: 9,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.sede.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.sede.address,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FILTRAR POR DEPORTE',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 9,
                    letterSpacing: 1.7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _sportChip(
                        label: 'Todos',
                        selected: _selectedSport == null,
                        onTap: () => setState(() => _selectedSport = null),
                      ),
                      ..._sports.map(
                        (sport) => _sportChip(
                          label: _sportLabel(sport),
                          selected: _selectedSport == sport,
                          onTap: () => setState(() => _selectedSport = sport),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
            child: Text(
              '${_visibleCourts.length} ${_visibleCourts.length == 1 ? 'CANCHA DISPONIBLE' : 'CANCHAS DISPONIBLES'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Expanded(
            child: _visibleCourts.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'Esta sede todavía no tiene canchas cargadas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _visibleCourts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 11),
                    itemBuilder: (context, index) =>
                        _buildCourtCard(_visibleCourts[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sportChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          color: selected ? Colors.black : Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        backgroundColor: _surface,
        selectedColor: _lime,
        side: BorderSide(
          color: selected ? _lime : Colors.white.withValues(alpha: 0.1),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildCourtCard(SportsCourt court) {
    final price = widget.rates[court.sport];
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF302900),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(_sportIcon(court.sport), color: _lime, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      court.courtLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${court.sportLabel} · Cancha ${court.number}',
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price == null ? 'Tarifa pendiente' : _formatMoney(price),
                      style: TextStyle(
                        color: price == null ? _muted : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'por hora',
                      style: TextStyle(color: _muted, fontSize: 9),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  final sportCourts = widget.sede.courts
                      .where((item) => item.sport == court.sport)
                      .toList();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookingScreen(
                        sede: widget.sede,
                        courts: sportCourts,
                        initialCourtId: court.id,
                        rates: widget.rates,
                        onSessionExpired: widget.onSessionExpired,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                label: const Text('HORARIOS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lime,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMoney(double value) =>
      '\$ ${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}';

  String _sportLabel(String sport) => switch (sport) {
    'FUTBOL' => 'Fútbol',
    'PADDLE' => 'Pádel',
    'BASQUET' => 'Básquet',
    'TENIS' => 'Tenis',
    'VOLEY' => 'Vóley',
    _ => sport,
  };

  IconData _sportIcon(String sport) => switch (sport) {
    'TENIS' || 'PADDLE' => Icons.sports_tennis,
    'FUTBOL' => Icons.sports_soccer,
    'BASQUET' => Icons.sports_basketball,
    'VOLEY' => Icons.sports_volleyball,
    _ => Icons.sports,
  };
}

class _SedePitchPainter extends CustomPainter {
  const _SedePitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(
      Rect.fromLTWH(7, 7, size.width - 14, size.height - 14),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, 7),
      Offset(size.width * 0.5, size.height - 7),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.height * 0.19,
      paint,
    );
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width * 0.48, size.height * 0.7),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.55, size.height * 0.28),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SedePitchPainter oldDelegate) => false;
}
