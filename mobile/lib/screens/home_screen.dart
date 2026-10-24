import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.userName,
    required this.userProfile,
  });

  final String userName;
  final Map<String, dynamic> userProfile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _lime = Color(0xFFD7FF00);
  static const Color _surface = Color(0xFF1B1B1E);
  static const Color _muted = Color(0xFF8A8A90);
  static const Color _danger = Color(0xFFFF5B5B);

  static const List<String> _categories = [
    'Todos',
    'Fútbol',
    'Tenis',
    'Golf',
    'Hockey',
  ];

  static const List<_Venue> _venues = [
    _Venue(
      name: 'Morón',
      address: 'Av. Rivadavia 17500',
      categories: ['Fútbol', 'Tenis'],
      rating: '4.7',
      color: Color(0xFF123047),
    ),
    _Venue(
      name: 'Ramos Mejía',
      address: 'Calle Belgrano 1240',
      categories: ['Fútbol', 'Hockey'],
      rating: '4.9',
      color: Color(0xFF25451A),
    ),
    _Venue(
      name: 'Castelar',
      address: 'Av. Santa Rosa 820',
      categories: ['Tenis', 'Golf'],
      rating: '4.8',
      color: Color(0xFF234138),
    ),
  ];

  String _selectedCategory = 'Todos';
  int _selectedTab = 0;
  late Map<String, dynamic> _userProfile;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _userProfile = Map<String, dynamic>.from(widget.userProfile);
  }

  String get _displayName {
    final nombre = _userProfile['nombre']?.toString().trim() ?? '';
    final apellido = _userProfile['apellido']?.toString().trim() ?? '';
    final fullName = [
      nombre,
      apellido,
    ].where((part) => part.isNotEmpty).join(' ');
    return fullName.isEmpty ? widget.userName : fullName;
  }

  String get _initials {
    final names = _displayName.trim().split(RegExp(r'\s+'));
    if (names.isEmpty || names.first.isEmpty) return 'U';
    return names.length > 1
        ? '${names.first[0]}${names.last[0]}'.toUpperCase()
        : names.first[0].toUpperCase();
  }

  List<_Venue> get _visibleVenues => _selectedCategory == 'Todos'
      ? _venues
      : _venues
            .where((venue) => venue.categories.contains(_selectedCategory))
            .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: _selectedTab == 0
                  ? _buildHomeContent()
                  : _selectedTab == 3
                  ? _buildProfileContent()
                  : _buildComingSoon(),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(),
          const SizedBox(height: 16),
          _buildReservationCard(),
          const SizedBox(height: 16),
          _buildCategorySelector(),
          const SizedBox(height: 20),
          _buildVenuesSection(),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 226,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.5, 0.65),
                radius: 1.2,
                colors: [Color(0xFF354614), Color(0xFF090B08)],
              ),
            ),
          ),
          const CustomPaint(painter: _PitchPainter()),
          Container(color: Colors.black.withValues(alpha: 0.28)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    _circleAction(
                      icon: Icons.notifications_none_rounded,
                      onTap: () =>
                          _showMessage('No tenés notificaciones nuevas'),
                    ),
                    const SizedBox(width: 10),
                    Builder(
                      builder: (buttonContext) => InkWell(
                        onTap: () => _showMiniProfileMenu(buttonContext),
                        borderRadius: BorderRadius.circular(24),
                        child: CircleAvatar(
                          radius: 19,
                          backgroundColor: _lime,
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'BUENOS DÍAS,',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 44),
                const Text(
                  'CLUB EZEQUIEL SPAGNOLI DE CONTI',
                  style: TextStyle(
                    color: _lime,
                    fontSize: 9,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'ZONA DEPORTIVA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleAction({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.32),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }

  Widget _buildReservationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'PRÓXIMA RESERVA',
                style: TextStyle(
                  color: _lime,
                  fontSize: 9,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const Text(
                'en 3 días',
                style: TextStyle(color: _muted, fontSize: 10),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, color: _muted, size: 13),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F6F76), Color(0xFF1B2926)],
                  ),
                ),
                child: const Icon(Icons.sports_tennis, color: _lime, size: 24),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sede Morón',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Moron_Rivadavia_Tenis_Polvo_Cancha_1',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _muted, fontSize: 8),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '19:00',
                    style: TextStyle(
                      color: _lime,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text('20:00', style: TextStyle(color: _muted, fontSize: 10)),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: Divider(height: 1, color: Colors.white12),
          ),
          const Row(
            children: [
              Text(
                'sáb, 15 ago',
                style: TextStyle(color: _muted, fontSize: 10),
              ),
              Spacer(),
              Text(
                '\$ 2.500',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          final icon = switch (category) {
            'Fútbol' => Icons.sports_soccer,
            'Tenis' => Icons.sports_tennis,
            'Golf' => Icons.golf_course,
            'Hockey' => Icons.sports_hockey,
            _ => null,
          };
          return ChoiceChip(
            selected: isSelected,
            showCheckmark: false,
            avatar: icon == null
                ? null
                : Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.black : Colors.white70,
                  ),
            label: Text(category),
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: _surface,
            selectedColor: _lime,
            side: BorderSide(
              color: isSelected ? _lime : Colors.white.withValues(alpha: 0.1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onSelected: (_) => setState(() => _selectedCategory = category),
          );
        },
      ),
    );
  }

  Widget _buildVenuesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'SEDES DISPONIBLES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _selectedTab = 1),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Ver todas →',
                  style: TextStyle(
                    color: _lime,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 151,
          child: _visibleVenues.isEmpty
              ? const Center(
                  child: Text(
                    'No hay sedes para esta categoría',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _visibleVenues.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) =>
                      _buildVenueCard(_visibleVenues[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildVenueCard(_Venue venue) {
    return SizedBox(
      width: 184,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [venue.color, const Color(0xFF0B1011)],
                        ),
                      ),
                    ),
                    CustomPaint(painter: _PitchPainter(subtle: true)),
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '★ ${venue.rating}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 9,
                      bottom: 7,
                      child: Text(
                        venue.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(9, 6, 9, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: _muted,
                          size: 11,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            venue.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _muted, fontSize: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: venue.categories
                          .map(_buildCategoryBadge)
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    final color = category == 'Fútbol'
        ? const Color(0xFF075C50)
        : const Color(0xFF593018);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        category,
        style: const TextStyle(color: Colors.white, fontSize: 8),
      ),
    );
  }

  Widget _buildComingSoon() {
    const labels = ['Inicio', 'Sedes', 'Reservas', 'Perfil'];
    const icons = [
      Icons.home_outlined,
      Icons.location_city_outlined,
      Icons.calendar_month_outlined,
      Icons.person_outline,
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icons[_selectedTab], color: _lime, size: 42),
            const SizedBox(height: 14),
            Text(
              labels[_selectedTab],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta sección estará disponible próximamente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return ProfileScreen(
      profile: _userProfile,
      onProfileUpdated: (profile) {
        setState(() => _userProfile = profile);
      },
      onLoggedOut: _redirectToLogin,
    );
  }

  void _redirectToLogin() {
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _showMiniProfileMenu(BuildContext buttonContext) async {
    final button = buttonContext.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final isActive = _userProfile['activo'] == true;
    final buttonRect = Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(
        button.size.bottomRight(Offset.zero),
        ancestor: overlay,
      ),
    );

    final action = await showMenu<_MiniProfileAction>(
      context: context,
      position: RelativeRect.fromRect(buttonRect, Offset.zero & overlay.size),
      color: _surface,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      constraints: const BoxConstraints(minWidth: 210, maxWidth: 235),
      items: [
        PopupMenuItem<_MiniProfileAction>(
          enabled: false,
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _lime,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActive ? 'MIEMBRO ACTIVO' : 'MIEMBRO INACTIVO',
                      style: TextStyle(
                        color: isActive ? _lime : _danger,
                        fontSize: 8,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<_MiniProfileAction>(
          enabled: false,
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _miniProfileDetail('Apellido', _userProfile['apellido']),
        ),
        PopupMenuItem<_MiniProfileAction>(
          enabled: false,
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _miniProfileDetail('DNI', _userProfile['dni']),
        ),
        PopupMenuItem<_MiniProfileAction>(
          enabled: false,
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _miniProfileDetail('Email', _userProfile['email']),
        ),
        PopupMenuItem<_MiniProfileAction>(
          enabled: false,
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _miniProfileDetail(
            'Nac.',
            _formatBirthDate(_userProfile['fecha_nacimiento']),
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem<_MiniProfileAction>(
          value: _MiniProfileAction.profile,
          height: 42,
          child: _MiniProfileMenuAction(
            icon: Icons.person_outline,
            label: 'Perfil completo',
          ),
        ),
        const PopupMenuItem<_MiniProfileAction>(
          value: _MiniProfileAction.reservations,
          height: 42,
          child: _MiniProfileMenuAction(
            icon: Icons.calendar_month_outlined,
            label: 'Mis reservas',
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem<_MiniProfileAction>(
          value: _MiniProfileAction.logout,
          height: 42,
          child: _MiniProfileMenuAction(
            icon: Icons.logout,
            label: 'Cerrar sesión',
            color: _danger,
          ),
        ),
      ],
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _MiniProfileAction.profile:
        setState(() => _selectedTab = 3);
      case _MiniProfileAction.reservations:
        setState(() => _selectedTab = 2);
      case _MiniProfileAction.logout:
        await _authService.logout();
        _redirectToLogin();
    }
  }

  Widget _miniProfileDetail(String label, Object? value) {
    final text = value?.toString().trim() ?? '';
    return Row(
      children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 10)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text.isEmpty ? '—' : text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ),
      ],
    );
  }

  String _formatBirthDate(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '—';
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildBottomNavigation() {
    const labels = ['INICIO', 'SEDES', 'RESERVAS', 'PERFIL'];
    const icons = [
      Icons.home_outlined,
      Icons.location_city_outlined,
      Icons.calendar_month_outlined,
      Icons.person_outline,
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0F),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = index == _selectedTab;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = index),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[index],
                      color: selected ? _lime : _muted,
                      size: 19,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      labels[index],
                      style: TextStyle(
                        color: selected ? _lime : _muted,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                    if (selected)
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        width: 17,
                        height: 2,
                        decoration: BoxDecoration(
                          color: _lime,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Venue {
  const _Venue({
    required this.name,
    required this.address,
    required this.categories,
    required this.rating,
    required this.color,
  });

  final String name;
  final String address;
  final List<String> categories;
  final String rating;
  final Color color;
}

enum _MiniProfileAction { profile, reservations, logout }

class _MiniProfileMenuAction extends StatelessWidget {
  const _MiniProfileMenuAction({
    required this.icon,
    required this.label,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.8), size: 16),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PitchPainter extends CustomPainter {
  const _PitchPainter({this.subtle = false});

  final bool subtle;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: subtle ? 0.16 : 0.12)
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
      size.height * 0.13,
      paint,
    );
    final boxWidth = size.width * 0.16;
    final boxHeight = size.height * 0.48;
    canvas.drawRect(
      Rect.fromLTWH(5, (size.height - boxHeight) / 2, boxWidth, boxHeight),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width - boxWidth - 5,
        (size.height - boxHeight) / 2,
        boxWidth,
        boxHeight,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PitchPainter oldDelegate) =>
      oldDelegate.subtle != subtle;
}
