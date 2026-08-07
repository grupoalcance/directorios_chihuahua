import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../widgets/custom_app_bar.dart';
import '../widgets/phone_menu_drawer.dart';

// 🔑 IMPORTACIÓN DINÁMICA DE CONFIGURACIÓN REGIONAL
import '../config/app_config.dart';

class FarmaciaProfileScreen extends StatelessWidget {
  final Map<String, dynamic> farmaciaData;

  const FarmaciaProfileScreen({super.key, required this.farmaciaData});

  // Métodos utilitarios para llamadas, mapas y WhatsApp
  Future<void> _hacerLlamada(String telefono) async {
    if (telefono.isEmpty) return;
    final Uri url = Uri.parse('tel:$telefono');
    if (!await launchUrl(url)) {
      debugPrint('No se pudo marcar al número: $telefono');
    }
  }

  Future<void> _abrirWhatsApp(String telefono, String nombreFarmacia) async {
    if (telefono.isEmpty) return;
    String cleanPhone = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (!cleanPhone.startsWith('52') && cleanPhone.length == 10) {
      cleanPhone = '52$cleanPhone';
    }
    String mensaje = Uri.encodeComponent(
      'Hola, vi su sucursal de $nombreFarmacia en ${AppConfig.appName} y me gustaría cotizar un medicamento.',
    );
    final Uri url = Uri.parse('https://wa.me/$cleanPhone?text=$mensaje');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('No se pudo abrir WhatsApp');
    }
  }

  Future<void> _abrirMapa(String direccion, String ciudad) async {
    final String query = Uri.encodeComponent('$direccion, $ciudad, Mexico');
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('No se pudo abrir el mapa');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool esPC = screenWidth > 900;

    // Extracción dinámica de datos desde Firebase
    String nombre = farmaciaData['nombre'] ?? 'Farmacia';
    String direccion = farmaciaData['direccion'] ?? 'Dirección no especificada';
    String ciudad = farmaciaData['ciudad'] ?? AppConfig.ciudadesActivas[0];
    String telefono = farmaciaData['telefono'] ?? '';
    String whatsapp = farmaciaData['whatsapp']?.toString().isNotEmpty == true
        ? farmaciaData['whatsapp']
        : telefono;
    String horario = farmaciaData['horario']?.toString().isNotEmpty == true
        ? farmaciaData['horario']
        : 'Abierto de 8:00 AM a 10:00 PM';
    String score = farmaciaData['score'] ?? '5.0';
    String descripcion =
        farmaciaData['descripcion']?.toString().isNotEmpty == true
        ? farmaciaData['descripcion']
        : 'Farmacia comprometida con la salud y el bienestar en nuestra región. Contamos con un amplio catálogo de medicamentos de patente, genéricos, cuidado personal y servicio a domicilio rápido.';

    // Extracción dinámica de servicios desde Firebase
    List<String> servicios = [];
    if (farmaciaData['servicios'] != null &&
        farmaciaData['servicios'] is List) {
      servicios = List<String>.from(farmaciaData['servicios']);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(),
      drawer: screenWidth < 1100 ? const PhoneMenuDrawer() : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // =========================================================================
            // 💊 HEADER HERO SECTION (BANNER INTEGRADO CON IMAGEN DINÁMICA DE FIREBASE)
            // =========================================================================
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 220),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  if (farmaciaData['foto_url'] != null &&
                      farmaciaData['foto_url'].toString().isNotEmpty)
                    Positioned.fill(
                      child:
                          farmaciaData['foto_url'].toString().startsWith(
                            'data:image',
                          )
                          ? Image.memory(
                              base64Decode(
                                farmaciaData['foto_url']
                                    .toString()
                                    .split(',')
                                    .last,
                              ),
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              farmaciaData['foto_url'],
                              fit: BoxFit.cover,
                            ),
                    ),

                  Positioned.fill(
                    child: Container(color: Colors.black.withOpacity(0.45)),
                  ),

                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 28,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: esPC ? 45 : 35,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                (farmaciaData['foto_url'] != null &&
                                    farmaciaData['foto_url']
                                        .toString()
                                        .isNotEmpty)
                                ? (farmaciaData['foto_url']
                                          .toString()
                                          .startsWith('data:image')
                                      ? MemoryImage(
                                          base64Decode(
                                            farmaciaData['foto_url']
                                                .toString()
                                                .split(',')
                                                .last,
                                          ),
                                        )
                                      : NetworkImage(farmaciaData['foto_url'])
                                            as ImageProvider)
                                : null,
                            child:
                                (farmaciaData['foto_url'] != null &&
                                    farmaciaData['foto_url']
                                        .toString()
                                        .isNotEmpty)
                                ? null
                                : const Icon(
                                    Icons.local_pharmacy_rounded,
                                    size: 40,
                                    color: Color(0xFF0F766E),
                                  ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: esPC ? 30 : 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      ciudad,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      score,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // =========================================================================
            // 📊 CUERPO RESPONSIVO EN 1 O 2 COLUMNAS
            // =========================================================================
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: esPC
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildInformacionPrincipal(
                              descripcion,
                              servicios,
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 2,
                            child: _buildTarjetaContacto(
                              telefono,
                              whatsapp,
                              horario,
                              direccion,
                              ciudad,
                              nombre,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildInformacionPrincipal(descripcion, servicios),
                          const SizedBox(height: 24),
                          _buildTarjetaContacto(
                            telefono,
                            whatsapp,
                            horario,
                            direccion,
                            ciudad,
                            nombre,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BLOQUE IZQUIERDO: DETALLES DE SERVICIOS ---
  Widget _buildInformacionPrincipal(
    String descripcion,
    List<String> serviciosDinamicos,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reseña comercial
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sobre nosotros',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                descripcion,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Atributos y Beneficios clave
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Servicios y Ventajas Clave',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 20),
              if (serviciosDinamicos.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: serviciosDinamicos.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 20),
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE6F7F0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF10B981),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            serviciosDinamicos[index],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
              else ...[
                _buildIconServiceItem(
                  Icons.delivery_dining_rounded,
                  'Servicio a Domicilio Express',
                  'Llevamos tus medicamentos directo a tu casa en la región.',
                ),
                const Divider(height: 24),
                _buildIconServiceItem(
                  Icons.medical_information_rounded,
                  'Consultorio Médico Adyacente',
                  'Consulta básica rápida y toma de presión al momento.',
                ),
                const Divider(height: 24),
                _buildIconServiceItem(
                  Icons.credit_card_rounded,
                  'Aceptamos Tarjetas de Crédito/Débito',
                  'Terminal móvil disponible para pagos a domicilio.',
                ),
                const Divider(height: 24),
                _buildIconServiceItem(
                  Icons.verified_user_rounded,
                  'Medicamentos de Patente y Genéricos',
                  'Surtido completo de recetas de forma segura.',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconServiceItem(IconData icon, String title, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF0F766E), size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- BLOQUE DERECHO: COMPRA Y CONTACTO DIRECTO ---
  Widget _buildTarjetaContacto(
    String telefono,
    String whatsapp,
    String horario,
    String direccion,
    String ciudad,
    String nombreFarmacia,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pedidos e Informes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),

          // 💬 BOTÓN ENVIAR RECETA POR WHATSAPP
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _abrirWhatsApp(whatsapp, nombreFarmacia),
              icon: const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Cotizar Receta por WhatsApp',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 🔵 BOTÓN LLAMAR A DOMICILIO
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _hacerLlamada(telefono),
              icon: const Icon(
                Icons.phone_in_talk_rounded,
                color: Color(0xFF0F766E),
                size: 18,
              ),
              label: const Text(
                'Pedir a Domicilio',
                style: TextStyle(
                  color: Color(0xFF0F766E),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),

          // Horario Comercial Farmacias
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Horario de Sucursal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      horario,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Ubicación
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dirección de Sucursal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '$direccion, $ciudad',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Botón GPS
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _abrirMapa(direccion, ciudad),
              icon: const FaIcon(
                FontAwesomeIcons.mapLocationDot,
                color: Colors.white,
                size: 15,
              ),
              label: const Text(
                '¿Cómo llegar a la sucursal?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF334155),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
