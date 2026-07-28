import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 👈 Asegurado para abrir los enlaces de WhatsApp
import '../widgets/custom_app_bar.dart';
import '../widgets/phone_menu_drawer.dart';

class ContactoScreen extends StatefulWidget {
  const ContactoScreen({Key? key}) : super(key: key);

  @override
  State<ContactoScreen> createState() => _ContactoScreenState();
}

class _ContactoScreenState extends State<ContactoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _mensajeController = TextEditingController();

  // 📞 COLOCA AQUÍ TU NÚMERO DE WHATSAPP CON LADA (52 para México)
  final String _numeroSoporte = '528714178277';

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  // 🛠️ FUNCIÓN GENERAL PARA ABRIR UN CHAT DE WHATSAPP
  Future<void> _abrirWhatsApp({required String mensaje}) async {
    final String mensajeCodificado = Uri.encodeComponent(mensaje);
    final Uri url = Uri.parse(
      'https://wa.me/$_numeroSoporte?text=$mensajeCodificado',
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir WhatsApp automáticamente. Inténtalo de nuevo.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🚀 FUNCIÓN DEL BOTÓN "ENVIAR MENSAJE" (Formatea el texto ordenado para tu WhatsApp)
  void _enviarFormularioPorWhatsApp() {
    if (_formKey.currentState!.validate()) {
      final String plantillaMensaje =
          '📌 *Nuevo Mensaje de Contacto - Médicos durango*\n\n'
          '👤 *Nombre:* ${_nombreController.text.trim()}\n'
          '✉️ *Correo:* ${_correoController.text.trim()}\n\n'
          '💬 *Mensaje / Duda:*\n${_mensajeController.text.trim()}';

      _abrirWhatsApp(mensaje: plantillaMensaje);

      // Limpiamos cajas después de mandar la información
      _nombreController.clear();
      _correoController.clear();
      _mensajeController.clear();
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
                vertical: width < 600 ? 40 : 60,
                horizontal: 20,
              ),
              color: const Color(0xFF1E3A8A),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      const Text(
                        'Ponte en Contacto',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '¿Tienes dudas, sugerencias o te interesa anunciar tu consultorio, clínica o farmacia? Escríbenos, estamos para ayudarte.',
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
                            child: _buildFormularioCanales(width),
                          ),
                          const SizedBox(width: 48),
                          Expanded(flex: 3, child: _buildFormularioMensaje()),
                        ],
                      )
                    : Column(
                        children: [
                          _buildFormularioCanales(width),
                          const SizedBox(height: 40),
                          _buildFormularioMensaje(),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BLOQUE DE CANALES / DATOS DE CONTACTO ---
  Widget _buildFormularioCanales(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Canales de Atención',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Elige la vía más cómoda para comunicarte de forma directa con el equipo de Médicos durango.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.3),
        ),
        const SizedBox(height: 28),

        // Tarjeta WhatsApp (Clickable para mandar mensaje rápido)
        _cardCanal(
          icon: Icons.chat_bubble_rounded,
          color: Colors.green,
          titulo: 'Soporte WhatsApp',
          desc: 'Atención rápida para dudas o registros médicos.',
          datoDestacado: '871 417 8277',
          onTap: () => _abrirWhatsApp(
            mensaje:
                'Hola, me comunico desde la sección de Contacto de Médicos durango, me gustaría recibir más información.',
          ),
        ),
        const SizedBox(height: 16),
        _cardCanal(
          icon: Icons.alternate_email_rounded,
          color: Colors.blue,
          titulo: 'Correo Electrónico',
          desc: 'Para propuestas comerciales o anuncios institucionales.',
          datoDestacado: 'contacto@medicosdurango.com',
        ),
        const SizedBox(height: 16),

        // Tarjeta de Horario de atención
        _cardCanal(
          icon: Icons.access_time_filled_rounded,
          color: Colors.orange,
          titulo: 'Horario de Atención',
          desc:
              'Lunes a Viernes de 9:00 AM a 7:00 PM', 
          datoDestacado: 'Sábados de 9:00 AM a 2:00 PM',
        ),
      ],
    );
  }

  Widget _cardCanal({
    required IconData icon,
    required Color color,
    required String titulo,
    required String desc,
    required String datoDestacado,
    VoidCallback? onTap, // Añadido para habilitar el toque
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap:
            onTap, // Si se le asigna una función (como en el de WhatsApp), reaccionará al clic
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 20),
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      datoDestacado,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color,
                        decoration: onTap != null
                            ? TextDecoration.underline
                            : TextDecoration
                                  .none, // Subrayado sutil si es clickable
                      ),
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

  // --- BLOQUE FORMULARIO DE ENVÍO ---
  Widget _buildFormularioMensaje() {
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
              'Envíanos un mensaje',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),

            _buildInputLabel('Nombre Completo'),
            TextFormField(
              controller: _nombreController,
              decoration: _inputDecoration('Ej. Carlos Lozano'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Por favor ingresa tu nombre' : null,
            ),
            const SizedBox(height: 20),

            _buildInputLabel('Correo Electrónico'),
            TextFormField(
              controller: _correoController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration('Ej. carlos@correo.com'),
              validator: (v) {
                if (v == null || v.isEmpty)
                  return 'Por favor ingresa tu correo';
                if (!v.contains('@') || !v.contains('.'))
                  return 'Ingresa un correo válido';
                return null;
              },
            ),
            const SizedBox(height: 20),

            _buildInputLabel('¿En qué podemos ayudarte?'),
            TextFormField(
              controller: _mensajeController,
              maxLines: 4,
              decoration: _inputDecoration(
                'Escribe aquí detalladamente tu duda o propuesta comercial...',
              ),
              validator: (v) => v == null || v.isEmpty
                  ? 'Por favor escribe tu mensaje'
                  : null,
            ),
            const SizedBox(height: 28),

            // Botón de Enviar (Detona el envío estructurado a tu WhatsApp)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _enviarFormularioPorWhatsApp, // 👈 Vinculado al despachador de WhatsApp
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0061E0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Enviar mensaje',
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
        borderSide: const BorderSide(color: Color(0xFF0061E0), width: 1.5),
      ),
    );
  }
}
