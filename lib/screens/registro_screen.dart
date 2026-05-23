import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'medicos_page_screen.dart';
import '../widgets/custom_app_bar.dart'; // <-- IMPORTAMOS LA NUEVA BARRA
import 'textos_legales_screen.dart'; // <-- IMPORTAMOS LA PANTALLA LEGAL

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  bool _isDoctor = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _aceptaTerminos = false;

  // Controladores comunes
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Controladores exclusivos de Doctor
  final _cedulaController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _direccionController = TextEditingController();
  final _otraEspecialidadController = TextEditingController();

  final List<String> _listaEspecialidades = [
    'Cardiología',
    'Pediatría',
    'Ginecología',
    'Dentista',
    'Neurología',
    'Traumatología',
    'Otra',
  ];
  String? _especialidadSeleccionada;

  final List<String> _listaCiudades = [
    'Torreón, Coah.',
    'Gómez Palacio, Dgo.',
    'Lerdo, Dgo.',
    'Matamoros, Coah.',
    'Francisco I. Madero, Coah.',
    'San Pedro, Coah.',
  ];
  String? _ciudadSeleccionada;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Color base
      appBar: const CustomAppBar(), // <-- LA LÍNEA MÁGICA
      body: Container(
        // 👇 ENVOLVEMOS EL CONTENIDO EN ESTE CONTAINER 👇
        width: double.infinity,
        height: double.infinity,
        // 👇 AQUÍ ESTÁ EL DEGRADADO SUAVE
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEBF4FF), // Un azul muy, muy clarito arriba
              Colors.white, // Se difumina a blanco hacia abajo
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              margin: const EdgeInsets.symmetric(
                vertical: 40,
              ), // Margen arriba y abajo
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
                      'Crear una cuenta',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1F36),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- SELECTOR DE ROL ---
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isDoctor = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isDoctor
                                    ? Colors.blue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isDoctor
                                    ? [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  'Soy Médico',
                                  style: TextStyle(
                                    color: _isDoctor
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isDoctor = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isDoctor
                                    ? Colors.blue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !_isDoctor
                                    ? [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  'Soy Paciente',
                                  style: TextStyle(
                                    color: !_isDoctor
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- FORMULARIO DINÁMICO ---
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
                    _isDoctor ? 'Teléfono (Consultorio)' : 'Teléfono celular',
                    _telefonoController,
                    icon: Icons.phone,
                    isNumber: true,
                    isRequired: true,
                  ),
                  const SizedBox(height: 15),

                  // Campos EXCLUSIVOS del Doctor
                  if (_isDoctor) ...[
                    _buildTextField(
                      'WhatsApp / Celular (Opcional)',
                      _whatsappController,
                      icon: Icons.phone_android,
                      isNumber: true,
                      isRequired: false, // <-- EL ÚNICO OPCIONAL
                    ),
                    const SizedBox(height: 15),

                    _buildDropdownCiudad(isRequired: true),
                    const SizedBox(height: 15),

                    _buildTextField(
                      'Calle y Número del Consultorio',
                      _direccionController,
                      icon: Icons.location_on_outlined,
                      isRequired: true, // <-- AHORA ES OBLIGATORIO
                    ),
                    const SizedBox(height: 15),

                    _buildDropdownEspecialidad(isRequired: true),
                    const SizedBox(height: 15),

                    if (_especialidadSeleccionada == 'Otra') ...[
                      _buildTextField(
                        '¿Cuál es tu especialidad?',
                        _otraEspecialidadController,
                        icon: Icons.edit_outlined,
                        isRequired: true,
                      ),
                      const SizedBox(height: 15),
                    ],

                    _buildTextField(
                      'Cédula Profesional',
                      _cedulaController,
                      icon: Icons.badge_outlined,
                      isNumber: true,
                      isRequired: true, // <-- AHORA ES OBLIGATORIO
                    ),
                    const SizedBox(height: 15),
                  ],

                  // Campos Comunes (Credenciales)
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
                      // --- AQUÍ ESTÁ EL CAMBIO PARA HACERLO CLICKABLE ---
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
                      // ---------------------------------------------------
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

  // --- LÓGICA DE VALIDACIÓN Y REGISTRO ---
  Future<void> _ejecutarRegistro() async {
    // 1. Validar campos obligatorios generales
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

    // 2. Validar campos obligatorios de Doctor
    if (_isDoctor) {
      if (_ciudadSeleccionada == null) {
        _mostrarError('Por favor selecciona la ciudad de tu consultorio.');
        return;
      }
      if (_direccionController.text.trim().isEmpty) {
        _mostrarError('Por favor ingresa la calle y número de tu consultorio.');
        return;
      }
      if (_especialidadSeleccionada == null) {
        _mostrarError('Por favor selecciona tu especialidad.');
        return;
      }
      if (_especialidadSeleccionada == 'Otra' &&
          _otraEspecialidadController.text.trim().isEmpty) {
        _mostrarError('Por favor especifica cuál es tu especialidad.');
        return;
      }
      if (_cedulaController.text.trim().isEmpty) {
        _mostrarError('Por favor ingresa tu Cédula Profesional.');
        return;
      }
    }

    // 3. Validar Reglas de Contraseña (Mínimo 8, 1 mayúscula, 1 número)
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

    // 4. Validar que las contraseñas coincidan
    if (password != _confirmPasswordController.text.trim()) {
      _mostrarError('Las contraseñas no coinciden. Verifícalas por favor.');
      return;
    }

    // 5. Validar Términos y Condiciones
    if (!_aceptaTerminos) {
      _mostrarError('Debes aceptar los términos y privacidad para continuar.');
      return;
    }

    // Si todo está perfecto, iniciamos el registro
    setState(() => _isLoading = true);

    String especialidadFinal = '';
    String direccionFinal = '';

    if (_isDoctor) {
      especialidadFinal = _especialidadSeleccionada == 'Otra'
          ? _otraEspecialidadController.text.trim()
          : _especialidadSeleccionada ?? 'General';

      direccionFinal =
          '${_direccionController.text.trim()}, $_ciudadSeleccionada';
    }

    String? resultado = await AuthService().registrarUsuario(
      email: _correoController.text.trim(),
      password: password,
      nombre: _nombreController.text.trim(),
      apellidos: _apellidosController.text.trim(),
      telefono: _telefonoController.text.trim(),
      rol: _isDoctor ? 'medico' : 'paciente',
      especialidad: _isDoctor ? especialidadFinal : null,
      cedula: _isDoctor ? _cedulaController.text.trim() : null,
      whatsapp: _isDoctor ? _whatsappController.text.trim() : null,
      direccion: _isDoctor ? direccionFinal : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (resultado == "success") {
      if (mounted) {
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
        behavior: SnackBarBehavior
            .floating, // Hace que se vea como una burbuja elegante
      ),
    );
  }

  // --- WIDGETS AUXILIARES PARA EL FORMULARIO ---

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

  Widget _buildDropdownCiudad({bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelRequired('Ciudad del Consultorio', isRequired: isRequired),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _ciudadSeleccionada,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.location_city_outlined,
              color: Colors.grey,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          hint: const Text(
            'Selecciona tu ciudad',
            style: TextStyle(fontSize: 14),
          ),
          items: _listaCiudades.map((String ciudad) {
            return DropdownMenuItem<String>(value: ciudad, child: Text(ciudad));
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _ciudadSeleccionada = newValue;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDropdownEspecialidad({bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelRequired('Especialidad', isRequired: isRequired),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _especialidadSeleccionada,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.medical_services_outlined,
              color: Colors.grey,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          hint: const Text(
            'Selecciona tu especialidad',
            style: TextStyle(fontSize: 14),
          ),
          items: _listaEspecialidades.map((String esp) {
            return DropdownMenuItem<String>(value: esp, child: Text(esp));
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _especialidadSeleccionada = newValue;
              if (newValue != 'Otra') {
                _otraEspecialidadController.clear();
              }
            });
          },
        ),
      ],
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
