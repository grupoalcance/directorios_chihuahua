import 'package:flutter/material.dart';
import 'registro_screen.dart';
import '../services/auth_service.dart';
import 'medicos_page_screen.dart';
import '../widgets/custom_app_bar.dart';
import 'admin_dashboard_screen.dart';

// 🔑 IMPORTACIÓN DINÁMICA DE CONFIGURACIÓN REGIONAL
import '../config/app_config.dart';

class LoginScreen extends StatefulWidget {
  final bool vieneDesdeOpinio;

  const LoginScreen({super.key, this.vieneDesdeOpinio = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  void _mostrarDialogoRecuperarPassword() {
    final TextEditingController _resetEmailController = TextEditingController();
    _resetEmailController.text = _emailController.text;

    showDialog(
      context: context,
      builder: (context) {
        bool isSending = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                'Recuperar contraseña',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ingresa tu correo electrónico y te enviaremos un enlace seguro para crear una nueva contraseña.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'ejemplo@correo.com',
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          if (_resetEmailController.text.trim().isEmpty) return;

                          setStateDialog(() => isSending = true);

                          String? resultado = await AuthService()
                              .recuperarPassword(
                                email: _resetEmailController.text.trim(),
                              );

                          setStateDialog(() => isSending = false);

                          if (!mounted) return;
                          Navigator.pop(context);

                          if (resultado == "success") {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '¡Enlace enviado! Revisa tu bandeja de entrada o la carpeta de Spam.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  resultado ?? 'Error desconocido',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSending
                      ? const SizedBox(
                          height: 15,
                          width: 15,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Enviar enlace',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
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
              constraints: const BoxConstraints(maxWidth: 400),
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TÍTULO DINÁMICO SEGÚN FLUJO
                  Text(
                    widget.vieneDesdeOpinio
                        ? 'Inicia Sesión para Opinar'
                        : 'Portal de Acceso',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // PÁRRAFO CONTEXTUALIZADO Y DESACOPLADO CON AppConfig.appName
                  Text(
                    widget.vieneDesdeOpinio
                        ? 'Para garantizar la autenticidad y seguridad del directorio, inicia sesión con tu cuenta de paciente antes de calificar tu experiencia.'
                        : 'Ingresa tus credenciales autorizadas de acceso para pacientes o administradores de ${AppConfig.appName}.',
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    'Correo electrónico',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'ejemplo@correo.com',
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Colors.grey,
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

                  const Text(
                    'Contraseña',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: '••••••••',
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
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _mostrarDialogoRecuperarPassword,
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppConfig.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final emailLimpio = _emailController.text.trim();
                              final passwordLimpia = _passwordController.text
                                  .trim();

                              if (emailLimpio.isEmpty ||
                                  passwordLimpia.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Por favor, ingresa tu correo y contraseña.',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              setState(() => _isLoading = true);

                              String? resultado = await AuthService()
                                  .iniciarSesion(
                                    email: emailLimpio,
                                    password: passwordLimpia,
                                  );

                              if (resultado == "success") {
                                Map<String, dynamic>? datosUsuario =
                                    await AuthService().getDatosUsuarioActual();

                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }

                                if (datosUsuario == null) {
                                  await AuthService().cerrarSesion();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Error al verificar tu perfil en el servidor.',
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                  return;
                                }

                                String rolUsuario = datosUsuario['rol'] ?? '';

                                if (mounted) {
                                  if (rolUsuario == 'admin' ||
                                      emailLimpio.toLowerCase() ==
                                          'sistemas@agenciaalcance.com') {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/admin_dashboard',
                                      (route) => false,
                                    );
                                  } else if (rolUsuario == 'vendedor') {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/captura-contratos',
                                      (route) => false,
                                    );
                                  } else if (rolUsuario == 'paciente') {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/',
                                      (route) => false,
                                    );
                                  } else {
                                    await AuthService().cerrarSesion();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Acceso denegado. Este portal es de uso exclusivo para cuentas autorizadas.',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor: Colors.orange,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        resultado ?? 'Error desconocido',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
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
                              'Iniciar Sesión',
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
                        '¿No tienes cuenta?',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegistroScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Regístrate aquí',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppConfig.primaryColor,
                          ),
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
}
