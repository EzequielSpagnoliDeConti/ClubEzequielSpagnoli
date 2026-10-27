import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
    required this.onLoggedOut,
  });

  final Map<String, dynamic> profile;
  final ValueChanged<Map<String, dynamic>> onProfileUpdated;
  final VoidCallback onLoggedOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _lime = Color(0xFFD7FF00);
  static const Color _surface = Color(0xFF1B1B1E);
  static const Color _muted = Color(0xFF8A8A90);
  static const Color _danger = Color(0xFFFF5B5B);

  final AuthService _authService = AuthService();
  late Map<String, dynamic> _profile;
  bool _isDeactivating = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      _profile = widget.profile;
    }
  }

  Future<void> _editProfile() async {
    final updatedProfile = await Navigator.of(context)
        .push<Map<String, dynamic>>(
          MaterialPageRoute(
            builder: (_) => EditProfileScreen(profile: _profile),
          ),
        );

    if (updatedProfile == null || !mounted) return;

    setState(() => _profile = updatedProfile);
    widget.onProfileUpdated(updatedProfile);
  }

  Future<void> _deactivateAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text(
          'Dar de baja la cuenta',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tu cuenta quedará inactiva y ya no vas a poder iniciar sesión. '
          'Tus datos y reservas se conservarán.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'DAR DE BAJA',
              style: TextStyle(color: _danger, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeactivating = true);

    try {
      await _authService.deactivateCurrentUser();
      if (mounted) widget.onLoggedOut();
    } on AuthException catch (error) {
      if (mounted) {
        _showMessage(_errorMessage(error.type));
      }
    } finally {
      if (mounted) {
        setState(() => _isDeactivating = false);
      }
    }
  }

  String _errorMessage(AuthErrorType type) {
    return switch (type) {
      AuthErrorType.invalidCredentials => 'La sesión venció. Iniciá sesión.',
      AuthErrorType.sessionExpired => 'La sesión venció. Iniciá sesión.',
      AuthErrorType.connectivity => 'No hay conexión. Verificá tu red.',
      AuthErrorType.validation => 'Revisá los datos ingresados.',
      AuthErrorType.profileUpdateFailed => 'Ese DNI ya está registrado.',
      AuthErrorType.accountDeactivationFailed =>
        'No se pudo dar de baja la cuenta. Intentá nuevamente.',
      AuthErrorType.passwordResetFailed =>
        'No se pudo completar la operación. Intentá nuevamente.',
      AuthErrorType.registrationFailed => 'No se pudo completar la operación.',
      AuthErrorType.server => 'Error del servidor. Intentá más tarde.',
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String get _fullName {
    final nombre = _profile['nombre']?.toString().trim() ?? '';
    final apellido = _profile['apellido']?.toString().trim() ?? '';
    return [nombre, apellido].where((part) => part.isNotEmpty).join(' ');
  }

  String get _initials {
    final parts = _fullName.split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    return parts.length > 1
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : parts.first[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _profile['activo'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'MI PERFIL',
            style: TextStyle(
              color: _lime,
              fontSize: 11,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: _lime,
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _fullName.isEmpty ? 'Usuario' : _fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _lime.withValues(alpha: 0.12)
                        : _danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'CUENTA ACTIVA' : 'CUENTA INACTIVA',
                    style: TextStyle(
                      color: isActive ? _lime : _danger,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DATOS PERSONALES',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    letterSpacing: 1.7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                _detail('Nombre', _profile['nombre'], Icons.person_outline),
                _detail('Apellido', _profile['apellido'], Icons.person_outline),
                _detail('DNI', _profile['dni'], Icons.badge_outlined),
                _detail(
                  'Fecha de nacimiento',
                  _formatDate(_profile['fecha_nacimiento']),
                  Icons.cake_outlined,
                ),
                _detail(
                  'Correo electrónico',
                  _profile['email'],
                  Icons.email_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isDeactivating ? null : _editProfile,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('EDITAR PERFIL'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _lime,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _isDeactivating ? null : _deactivateAccount,
            icon: _isDeactivating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _danger,
                    ),
                  )
                : const Icon(Icons.person_off_outlined),
            label: Text(
              _isDeactivating ? 'PROCESANDO...' : 'DAR DE BAJA MI CUENTA',
            ),
            style: TextButton.styleFrom(
              foregroundColor: _danger,
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, Object? value, IconData icon) {
    final text = value?.toString().trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _lime, size: 18),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
                const SizedBox(height: 3),
                Text(
                  text == null || text.isEmpty ? '—' : text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final Map<String, dynamic> profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color _lime = Color(0xFFD7FF00);
  static const Color _muted = Color(0xFF8A8A90);

  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _dniController;
  late final TextEditingController _fechaController;
  late final TextEditingController _emailController;
  DateTime? _fechaNacimiento;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.profile['nombre']?.toString() ?? '',
    );
    _apellidoController = TextEditingController(
      text: widget.profile['apellido']?.toString() ?? '',
    );
    _dniController = TextEditingController(
      text: widget.profile['dni']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: widget.profile['email']?.toString() ?? '',
    );
    _fechaNacimiento = DateTime.tryParse(
      widget.profile['fecha_nacimiento']?.toString() ?? '',
    );
    _fechaController = TextEditingController(
      text: _fechaNacimiento == null ? '' : _formatDate(_fechaNacimiento!),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _fechaController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final today = DateTime.now();
    final initialDate =
        _fechaNacimiento != null && !_fechaNacimiento!.isAfter(today)
        ? _fechaNacimiento!
        : DateTime(today.year - 18, today.month, today.day);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'FECHA DE NACIMIENTO',
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
    );

    if (selectedDate == null || !mounted) return;
    setState(() {
      _fechaNacimiento = selectedDate;
      _fechaController.text = _formatDate(selectedDate);
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _fechaNacimiento == null) {
      if (_fechaNacimiento == null) {
        _showMessage('Seleccioná tu fecha de nacimiento.');
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      final profile = await _authService.updateCurrentUser(
        nombre: _nombreController.text,
        apellido: _apellidoController.text,
        dni: _dniController.text,
        fechaNacimiento: _formatIsoDate(_fechaNacimiento!),
      );
      if (mounted) Navigator.of(context).pop(profile);
    } on AuthException catch (error) {
      if (mounted) _showMessage(_errorMessage(error.type));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _errorMessage(AuthErrorType type) {
    return switch (type) {
      AuthErrorType.invalidCredentials => 'La sesión venció. Iniciá sesión.',
      AuthErrorType.sessionExpired => 'La sesión venció. Iniciá sesión.',
      AuthErrorType.connectivity => 'No hay conexión. Verificá tu red.',
      AuthErrorType.validation => 'Revisá los datos ingresados.',
      AuthErrorType.profileUpdateFailed => 'Ese DNI ya está registrado.',
      AuthErrorType.accountDeactivationFailed =>
        'No se pudo dar de baja la cuenta.',
      AuthErrorType.passwordResetFailed =>
        'No se pudo completar la operación. Intentá nuevamente.',
      AuthErrorType.registrationFailed => 'No se pudo completar la operación.',
      AuthErrorType.server => 'Error del servidor. Intentá más tarde.',
    };
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Completá este campo.';
    }
    return null;
  }

  InputDecoration _decoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.35),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _lime, width: 2),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  String _formatIsoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        title: const Text(
          'Editar perfil',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Actualizá tus datos personales.',
                      style: TextStyle(color: _muted, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nombreController,
                      validator: _required,
                      style: const TextStyle(color: Colors.white),
                      decoration: _decoration('Nombre'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _apellidoController,
                      validator: _required,
                      style: const TextStyle(color: Colors.white),
                      decoration: _decoration('Apellido'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dniController,
                      validator: _required,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: _decoration('DNI'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fechaController,
                      readOnly: true,
                      onTap: _selectDate,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Seleccioná una fecha.'
                          : null,
                      style: const TextStyle(color: Colors.white),
                      decoration: _decoration(
                        'Fecha de nacimiento',
                        suffixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      style: const TextStyle(color: _muted),
                      decoration: _decoration(
                        'Correo electrónico (no editable)',
                        suffixIcon: const Icon(
                          Icons.lock_outline,
                          color: _muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _lime,
                          foregroundColor: Colors.black,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text('GUARDAR CAMBIOS'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
