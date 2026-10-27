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
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _codeSent = false;
  bool _completed = false;

  static const Color _lime = Color(0xFFDFFF00);

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_completed) return;
      if (!_codeSent) {
        await _authService.requestPasswordReset(email: _emailController.text);
        if (!mounted) return;
        setState(() => _codeSent = true);
      } else {
        await _authService.resetPassword(
          email: _emailController.text,
          token: _tokenController.text,
          password: _passwordController.text,
        );
        if (!mounted) return;
        setState(() => _completed = true);
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      final message = switch (error.type) {
        AuthErrorType.connectivity => 'No hay conexión. Verificá tu red.',
        AuthErrorType.passwordResetFailed =>
          'El código no es válido o venció. Revisalo e intentá nuevamente.',
        AuthErrorType.validation => 'Revisá el email ingresado.',
        _ => 'No se pudo completar la solicitud. Intentá más tarde.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                      _completed
                          ? 'Contraseña actualizada'
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
                      _completed
                          ? 'Ya podés iniciar sesión con tu nueva contraseña.'
                          : _codeSent
                          ? 'Si el correo corresponde a una cuenta activa, '
                                'vas a recibir un código. Ingresalo junto con '
                                'tu nueva contraseña.'
                          : 'Ingresá el email asociado a tu cuenta. Si existe, '
                                'te enviaremos un código de un solo uso.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    if (!_completed) ...[
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
                      if (_codeSent) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _tokenController,
                          keyboardType: TextInputType.visiblePassword,
                          autocorrect: false,
                          style: const TextStyle(color: Colors.white),
                          decoration: _decoration(
                            'Código recibido por email',
                            icon: Icons.pin_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresá el código.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: _decoration(
                            'Nueva contraseña',
                            icon: Icons.lock_outline,
                          ),
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return 'Usá al menos 8 caracteres.';
                            }
                            if (value.length > 128) {
                              return 'Usá como máximo 128 caracteres.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: _decoration(
                            'Confirmar contraseña',
                            icon: Icons.lock_outline,
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Las contraseñas no coinciden.';
                            }
                            return null;
                          },
                        ),
                      ],
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
                              : Text(
                                  _codeSent
                                      ? 'GUARDAR NUEVA CONTRASEÑA'
                                      : 'ENVIAR CÓDIGO',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      if (_codeSent) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  setState(() => _isLoading = true);
                                  try {
                                    await _authService.requestPasswordReset(
                                      email: _emailController.text,
                                    );
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Si la cuenta existe y no '
                                          'solicitaste un código '
                                          'recientemente, recibirás otro.',
                                        ),
                                      ),
                                    );
                                  } on AuthException {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No se pudo enviar el código. '
                                          'Intentá más tarde.',
                                        ),
                                      ),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                          child: const Text(
                            'Reenviar código',
                            style: TextStyle(color: _lime),
                          ),
                        ),
                      ],
                    ] else ...[
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('VOLVER AL INICIO DE SESIÓN'),
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
