import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _emailSent = false;

  static const Color _lime = Color(0xFFDFFF00);

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.requestPasswordReset(email: _emailController.text);

      if (!mounted) return;

      setState(() => _emailSent = true);
    } on AuthException catch (error) {
      if (!mounted) return;

      final message = switch (error.type) {
        AuthErrorType.connectivity => 'No hay conexión. Verificá tu red.',
        AuthErrorType.validation => 'Revisá el email ingresado.',
        _ => 'No se pudo enviar el correo. Intentá nuevamente.',
      };

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _decoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: icon == null ? null : Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.45),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white30),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _lime, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      appBar: AppBar(
        title: const Text('Restablecer contraseña'),
        backgroundColor: const Color(0xFF171717),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_reset, size: 64, color: _lime),
                    const SizedBox(height: 24),
                    Text(
                      _emailSent
                          ? 'Revisá tu correo'
                          : 'Recuperá el acceso a tu cuenta',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _emailSent
                          ? 'Si el correo corresponde a una cuenta registrada, '
                                'vas a recibir un enlace para restablecer '
                                'tu contraseña. Revisá también la carpeta '
                                'de correo no deseado.'
                          : 'Ingresá el email asociado a tu cuenta. '
                                'Te enviaremos un enlace para crear '
                                'una nueva contraseña.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    if (!_emailSent) ...[
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        style: const TextStyle(color: Colors.white),
                        decoration: _decoration(
                          'Email',
                          icon: Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Completá el email.';
                          }

                          if (!value.contains('@')) {
                            return 'Ingresá un email válido.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text(
                                  'ENVIAR ENLACE',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('VOLVER AL INICIO DE SESIÓN'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() => _emailSent = false);
                              },
                        child: const Text(
                          'Usar otro email',
                          style: TextStyle(color: _lime),
                        ),
                      ),
                    ],
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
