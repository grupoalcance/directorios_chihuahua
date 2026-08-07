import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Para detonar el mensaje de WhatsApp
import '../widgets/custom_app_bar.dart';
import '../widgets/phone_menu_drawer.dart';

// 🔑 IMPORTACIÓN DINÁMICA DE CONFIGURACIÓN REGIONAL
import '../config/app_config.dart';

class SuscribirseScreen extends StatefulWidget {
  const SuscribirseScreen({Key? key}) : super(key: key);

  @override
  State<SuscribirseScreen> createState() => _SuscribirseScreenState();
}

class _SuscribirseScreenState extends State<SuscribirseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _especialidadController = TextEditingController();

  // Opción por defecto para el tipo de contacto
  String _tipoContacto = 'Deseo que me contacten por llamada/WhatsApp';

  // 📞 NÚMERO COMERCIAL CENTRAL PARA RECIBIR SOLICITUDES DE REGISTRO
  final String _numeroComercial = '528714758857';

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _especialidadController.dispose();
    super.dispose();
  }

  // 🚀 FUNCIÓN PARA PROCESAR EL FORMULARIO Y ENVIARLO A WHATSAPP
  Future<void> _enviarSolicitudSuscripcion() async {
    if (_formKey.currentState!.validate()) {
      final String plantillaMensaje =
          '🩺 *Nueva Solicitud de Registro - ${AppConfig.appName}*\n\n'
          '👤 *Médico:* ${_nombreController.text.trim()}\n'
          '📞 *Teléfono:* ${_telefonoController.text.trim()}\n'
          '🩻 *Especialidad:* ${_especialidadController.text.trim()}\n\n'
          '📅 *Preferencia de Atención:*\n_${_tipoContacto}_';

      final String mensajeCodificado = Uri.encodeComponent(plantillaMensaje);
      final Uri url = Uri.parse(
        'https://wa.me/$_numeroComercial?text=$mensajeCodificado',
      );

      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo abrir WhatsApp de forma automática. Inténtalo de nuevo.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      // Limpiamos los campos después de enviar
      _nombreController.clear();
      _telefonoController.clear();
      _especialidadController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    bool esPC = width > 850;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(),
      drawer: width < 1100 ? const PhoneMenuDrawer() : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- BLOQUE 1: ENCABEZADO / HERO ---
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: width < 600 ? 45 : 65,
                horizontal: 20,
              ),
              color: const Color(0xFF1E3A8A),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      Text(
                        'Únete a ${AppConfig.appName}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Forma parte del directorio médico más moderno y consultado en ${AppConfig.ciudadesActivas.join(", ")}. Incrementa tus pacientes de manera directa y digital.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- CONTENEDOR MÁSTER RESPONSIVO ---
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1100),
                padding: EdgeInsets.symmetric(
                  horizontal: width < 600 ? 16.0 : 40.0,
                  vertical: 48.0,
                ),
                child: esPC
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildBeneficiosSuscripcion(),
                          ),
                          const SizedBox(width: 50),
                          Expanded(
                            flex: 3,
                            child: _buildFormularioSuscripcion(),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildBeneficiosSuscripcion(),
                          const SizedBox(height: 40),
                          _buildFormularioSuscripcion(),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BLOQUE IZQUIERDO: BENEFICIOS DE SUSCRIBIRSE ---
  Widget _buildBeneficiosSuscripcion() {
    String ciudadesTexto = AppConfig.ciudadesActivas.join(", ");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Por qué anunciarte con nosotros?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Diseñamos una plataforma pensada exclusivamente en las necesidades del sector médico local.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
        ),
        const SizedBox(height: 32),
        _itemBeneficio(
          Icons.ads_click_rounded,
          'Mayor Visibilidad',
          'Aparece ante miles de pacientes en $ciudadesTexto que buscan tu especialidad a diario.',
        ),
        const SizedBox(height: 20),
        _itemBeneficio(
          Icons.chat_bubble_rounded,
          'Citas Directas',
          'Sin intermediarios ni comisiones por cita. Los pacientes te contactan directo a tu WhatsApp empresarial.',
        ),
        const SizedBox(height: 20),
        _itemBeneficio(
          Icons.verified_rounded,
          'Perfil Premium Validado',
          'Destaca tu formación, sube tu foto, ubicación de consultorios, horarios y tu cédula profesional oficial.',
        ),
      ],
    );
  }

  Widget _itemBeneficio(IconData icon, String titulo, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFE0F2FE),
          child: Icon(icon, color: const Color(0xFF0369A1), size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- BLOQUE DERECHO: FORMULARIO DE CAPTURA ---
  Widget _buildFormularioSuscripcion() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solicitud de Registro',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Llena este breve formulario y nuestro equipo se comunicará contigo de inmediato.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 28),

            // Input Nombre
            _buildInputLabel('Nombre Completo del Médico'),
            TextFormField(
              controller: _nombreController,
              decoration: _inputDecoration(''),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Por favor ingresa tu nombre' : null,
            ),
            const SizedBox(height: 20),

            // Input Teléfono
            _buildInputLabel('Número de Teléfono / WhatsApp'),
            TextFormField(
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(''),
              validator: (v) => v == null || v.isEmpty
                  ? 'Por favor ingresa tu número de contacto'
                  : null,
            ),
            const SizedBox(height: 20),

            // Input Especialidad
            _buildInputLabel('Especialidad Médica'),
            TextFormField(
              controller: _especialidadController,
              decoration: _inputDecoration(''),
              validator: (v) => v == null || v.isEmpty
                  ? 'Por favor escribe tu especialidad'
                  : null,
            ),
            const SizedBox(height: 24),

            // Radio Buttons / Selector dinámico para agendar o contactar
            _buildInputLabel('¿Cómo te gustaría que coordinemos tu alta?'),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text(
                      'Deseo que me contacten por llamada/WhatsApp',
                      style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
                    ),
                    value: 'Deseo que me contacten por llamada/WhatsApp',
                    groupValue: _tipoContacto,
                    activeColor: AppConfig.primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _tipoContacto = value!;
                      });
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  RadioListTile<String>(
                    title: const Text(
                      'Quiero agendar cita para que me visiten en mi consultorio',
                      style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
                    ),
                    value:
                        'Quiero agendar cita para que me visiten en mi consultorio',
                    groupValue: _tipoContacto,
                    activeColor: AppConfig.primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _tipoContacto = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Botón de Acción Principal
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviarSolicitudSuscripcion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Enviar solicitud de registro',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        texto,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppConfig.primaryColor, width: 1.5),
      ),
    );
  }
}
