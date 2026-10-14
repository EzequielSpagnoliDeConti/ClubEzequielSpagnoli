import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _dniController = TextEditingController();
  final _fechaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _mostrarPassword = false;
  bool _registroExitoso = false;

  String? _mensajeError;
  String? _campoError;

  static const Color _lime = Color(0xFFD7FF00);
  static const Color _rojo = Color(0xFFFF4545);

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _fechaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime(hoy.year - 18, hoy.month, hoy.day),
      firstDate: DateTime(1900),
      lastDate: hoy,
      helpText: 'FECHA DE NACIMIENTO',
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
    );

    if (fecha == null || !mounted) return;

    // El backend espera YYYY-MM-DD.
    _fechaController.text =
        '${fecha.year.toString().padLeft(4, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';

    setState(() {
      _mensajeError = null;
      _campoError = null;
    });
  }

  String? _validarTexto(String? valor, String nombre) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Completá este campo';
    }
    return null;
  }

  String? _validarEmail(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Completá este campo';
    }

    final emailRegex = RegExp(
      r'^[\w.!#$%&’*+/=?^_`{|}~-]+@'
      r'[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?'
      r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)+$',
    );

    if (!emailRegex.hasMatch(valor.trim())) {
      return 'Ingresá un email válido';
    }

    return null;
  }

  String? _validarPassword(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Completá este campo';
    }

    if (valor.length < 8) {
      return 'Mínimo 8 caracteres';
    }

    return null;
  }

  void _limpiarError() {
    if (_mensajeError != null || _campoError != null) {
      setState(() {
        _mensajeError = null;
        _campoError = null;
      });
    }
  }

  Future<void> _crearCuenta() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _mensajeError = null;
      _campoError = null;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _mensajeError = 'Completá todos los campos';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.register(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        dni: _dniController.text.trim(),
        fechaNacimiento: _fechaController.text,
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        _registroExitoso = true;
      });
    } on AuthException catch (error) {
      if (!mounted) return;

      setState(() {
        switch (error.type) {
          case AuthErrorType.validation:
            _mensajeError = 'Revisá los datos ingresados';
            break;
          case AuthErrorType.registrationFailed:
            _mensajeError = 'Este usuario ya está registrado';
            _campoError = 'dni';
            break;
          case AuthErrorType.connectivity:
            _mensajeError = 'No hay conexión. Verificá tu red.';
            break;
          default:
            _mensajeError = 'Error del servidor. Intentá más tarde.';
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _mensajeError = 'No se pudo crear la cuenta. Intentá más tarde.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _decoracion(
    String hint, {
    String? campo,
    Widget? suffixIcon,
  }) {
    final tieneError = campo != null && _campoError == campo;

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tieneError ? _rojo : Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _lime),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _rojo),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _rojo),
      ),
      errorStyle: const TextStyle(color: _rojo, fontSize: 10),
    );
  }

  Widget _campo({
    required String etiqueta,
    required TextEditingController controller,
    required String hint,
    required String campo,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    bool obscureText = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$etiqueta *',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          readOnly: onTap != null,
          onTap: onTap,
          onChanged: (_) => _limpiarError(),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: _decoracion(hint, campo: campo, suffixIcon: suffixIcon),
        ),
      ],
    );
  }

  Widget _etiqueta(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        color: _lime,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 4,
      ),
    );
  }

  Widget _boton({required String texto, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _lime,
          foregroundColor: Colors.black,
          disabledBackgroundColor: _lime.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Text(
                texto,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
      ),
    );
  }

  Widget _fondo({required Widget child}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/fondo_login.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFF101010)),
        ),
        Container(color: Colors.black.withValues(alpha: 0.48)),
        SafeArea(child: child),
      ],
    );
  }

  Widget _pantallaExito() {
    return _fondo(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '¡Usuario Registrado!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 36),
                _boton(
                  texto: 'VOLVER AL LOGIN',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_registroExitoso) {
      return Scaffold(body: _pantallaExito());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: _fondo(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.chevron_left, size: 18),
                      label: const Text(
                        'Volver',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _etiqueta('NUEVA CUENTA'),
                    const SizedBox(height: 8),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        children: [
                          TextSpan(text: 'CREAR '),
                          TextSpan(
                            text: 'CUENTA',
                            style: TextStyle(color: _lime),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_mensajeError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _rojo.withValues(alpha: 0.17),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _rojo.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: _rojo,
                              size: 17,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _mensajeError!,
                                style: const TextStyle(
                                  color: _rojo,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _campo(
                            etiqueta: 'NOMBRE',
                            controller: _nombreController,
                            hint: 'Juan',
                            campo: 'nombre',
                            validator: (v) => _validarTexto(v, 'nombre'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _campo(
                            etiqueta: 'APELLIDO',
                            controller: _apellidoController,
                            hint: 'Pérez',
                            campo: 'apellido',
                            validator: (v) => _validarTexto(v, 'apellido'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _campo(
                      etiqueta: 'DNI',
                      controller: _dniController,
                      hint: '31.234.567',
                      campo: 'dni',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        final error = _validarTexto(v, 'dni');
                        if (error != null) return error;
                        if (v!.length < 7 || v.length > 8) {
                          return 'Ingresá un DNI válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    _campo(
                      etiqueta: 'FECHA DE NACIMIENTO',
                      controller: _fechaController,
                      hint: 'Seleccioná una fecha',
                      campo: 'fecha',
                      validator: (v) => _validarTexto(v, 'fecha'),
                      onTap: _seleccionarFecha,
                      suffixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _campo(
                      etiqueta: 'EMAIL',
                      controller: _emailController,
                      hint: 'juan@email.com',
                      campo: 'email',
                      keyboardType: TextInputType.emailAddress,
                      validator: _validarEmail,
                    ),
                    const SizedBox(height: 14),

                    _campo(
                      etiqueta: 'CONTRASEÑA',
                      controller: _passwordController,
                      hint: 'Mínimo 8 caracteres',
                      campo: 'password',
                      validator: _validarPassword,
                      obscureText: !_mostrarPassword,
                      suffixIcon: IconButton(
                        tooltip: _mostrarPassword
                            ? 'Ocultar contraseña'
                            : 'Mostrar contraseña',
                        onPressed: () {
                          setState(() {
                            _mostrarPassword = !_mostrarPassword;
                          });
                        },
                        icon: Icon(
                          _mostrarPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    _boton(texto: 'CREAR CUENTA', onPressed: _crearCuenta),
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
