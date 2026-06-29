import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'medicos_page_screen.dart';
import '../widgets/custom_app_bar.dart';
import 'textos_legales_screen.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  // El rol se fuerza estrictamente a false (No es médico, es Paciente)
  final bool _isDoctor = false;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _aceptaTerminos = false;

  // Controladores exclusivos para el registro de Pacientes
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEBF4FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              margin: const EdgeInsets.symmetric(vertical: 40),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Registro de Paciente',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1F36),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Crea tu cuenta para dejar opiniones y calificaciones verificadas a tus médicos de confianza.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blueGrey, fontSize: 13.5),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- FORMULARIO PARA PACIENTES ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Nombre(s)',
                          _nombreController,
                          isRequired: true,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildTextField(
                          'Apellidos',
                          _apellidosController,
                          isRequired: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  _buildTextField(
                    'Teléfono celular',
                    _telefonoController,
                    icon: Icons.phone,
                    isNumber: true,
                    isRequired: true,
                  ),
                  const SizedBox(height: 15),

                  _buildTextField(
                    'Correo electrónico',
                    _correoController,
                    icon: Icons.email_outlined,
                    isEmail: true,
                    isRequired: true,
                  ),
                  const SizedBox(height: 15),

                  _buildLabelRequired('Contraseña'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Mínimo 8 caracteres, 1 mayúscula y 1 número',
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Colors.grey,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  _buildLabelRequired('Confirmar Contraseña'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Repite tu contraseña',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Colors.grey,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                          () => _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Checkbox Legal
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _aceptaTerminos,
                          activeColor: Colors.blue,
                          onChanged: (value) {
                            setState(() {
                              _aceptaTerminos = value ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TextosLegalesScreen(),
                              ),
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              text: 'He leído y acepto los ',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                              children: const [
                                TextSpan(
                                  text:
                                      'Términos, Condiciones y el Aviso de Privacidad',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: ' de la plataforma.'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- BOTÓN REGISTRARSE ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _ejecutarRegistro,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Registrarme',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿Ya tienes una cuenta?',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Inicia sesión',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- LÓGICA DE VALIDACIÓN Y REGISTRO EXCLUSIVO DE PACIENTES ---
  Future<void> _ejecutarRegistro() async {
    if (_nombreController.text.trim().isEmpty ||
        _apellidosController.text.trim().isEmpty ||
        _telefonoController.text.trim().isEmpty ||
        _correoController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _mostrarError(
        'Por favor llena todos los campos marcados con asterisco (*).',
      );
      return;
    }

    // Validar Reglas de Contraseña (Mínimo 8, 1 mayúscula, 1 número)
    String password = _passwordController.text.trim();
    if (password.length < 8) {
      _mostrarError('La contraseña debe tener al menos 8 caracteres.');
      return;
    }
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    if (!hasUppercase || !hasDigits) {
      _mostrarError(
        'La contraseña debe incluir al menos una letra mayúscula y un número.',
      );
      return;
    }

    if (password != _confirmPasswordController.text.trim()) {
      _mostrarError('Las contraseñas no coinciden. Verifícalas por favor.');
      return;
    }

    if (!_aceptaTerminos) {
      _mostrarError('Debes aceptar los términos y privacidad para continuar.');
      return;
    }

    setState(() => _isLoading = true);

    // Ejecutar llamada mandando estrictamente el rol 'paciente'
    String? resultado = await AuthService().registrarUsuario(
      email: _correoController.text.trim(),
      password: password,
      nombre: _nombreController.text.trim(),
      apellidos: _apellidosController.text.trim(),
      telefono: _telefonoController.text.trim(),
      rol: 'paciente', // 👈 Rol de paciente nativo inalterable
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (resultado == "success") {
      if (mounted) {
        // Los pacientes pasan directo al inicio asíncrono ya logueados y activos
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MedicosPageScreen()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        _mostrarError(resultado ?? 'Error desconocido');
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildLabelRequired(String text, {bool isRequired = true}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black87,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    bool isEmail = false,
    bool isNumber = false,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelRequired(label, isRequired: isRequired),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isEmail
              ? TextInputType.emailAddress
              : (isNumber ? TextInputType.number : TextInputType.text),
          decoration: InputDecoration(
            hintText:
                'Ingresa tu ${label.replaceAll(RegExp(r'\(.*\)'), '').trim()}'
                    .toLowerCase(),
            prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
