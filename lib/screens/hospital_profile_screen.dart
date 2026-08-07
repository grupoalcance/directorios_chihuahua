import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../widgets/custom_app_bar.dart';
import '../widgets/phone_menu_drawer.dart';

// 🔑 IMPORTACIÓN DINÁMICA DE CONFIGURACIÓN REGIONAL
import '../config/app_config.dart';

class HospitalProfileScreen extends StatelessWidget {
  final Map<String, dynamic> hospitalData;

  const HospitalProfileScreen({super.key, required this.hospitalData});

  Future<void> _hacerLlamada(String telefono) async {
    if (telefono.isEmpty) return;
    final Uri url = Uri.parse('tel:$telefono');
    if (!await launchUrl(url)) {
      debugPrint('No se pudo marcar al número: $telefono');
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

    // Extracción segura de datos desde Firebase
    String nombre = hospitalData['nombre'] ?? 'Hospital General';
    String direccion = hospitalData['direccion'] ?? 'Dirección no especificada';
    String ciudad = hospitalData['ciudad'] ?? AppConfig.ciudadesActivas[0];
    String telefono = hospitalData['telefono'] ?? '';
    String urgencias =
        hospitalData['telefono_urgencias']?.toString().isNotEmpty == true
        ? hospitalData['telefono_urgencias']
        : telefono;
    String horario = hospitalData['horario']?.toString().isNotEmpty == true
        ? hospitalData['horario']
        : 'Abierto las 24 horas (Lunes a Domingo)';
    String score = hospitalData['score'] ?? '5.0';
    String descripcion =
        hospitalData['descripcion']?.toString().isNotEmpty == true
        ? hospitalData['descripcion']
        : '$nombre no solo es un espacio de atención médica, es el corazón de un grupo de profesionales comprometidos con la salud y el bienestar de nuestra gente.';

    // Extracción dinámica de servicios desde Firebase
    List<String> servicios = [];
    if (hospitalData['servicios'] != null &&
        hospitalData['servicios'] is List) {
      servicios = List<String>.from(hospitalData['servicios']);
    }

    if (servicios.isEmpty) {
      servicios = [
        'Urgencias Médicas 24/7',
        'Quirófanos de Alta Tecnología',
        'Unidad de Cuidados Intensivos (UCI)',
        'Especialidades Médicas Integrales',
        'Laboratorio Clínico y de Análisis',
        'Banco de Sangre',
        'Radiología e Imagenología Avanzada',
        'Maternidad y Neonatología',
      ];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(),
      drawer: screenWidth < 1100 ? const PhoneMenuDrawer() : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // =========================================================================
            // 🏢 HEADER HERO SECTION (BANNER INTEGRADO CON OVERLAY DE CONTRASTE)
            // =========================================================================
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 220),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  if (hospitalData['foto_url'] != null &&
                      hospitalData['foto_url'].toString().isNotEmpty)
                    Positioned.fill(
                      child:
                          hospitalData['foto_url'].toString().startsWith(
                            'data:image',
                          )
                          ? Image.memory(
                              base64Decode(
                                hospitalData['foto_url']
                                    .toString()
                                    .split(',')
                                    .last,
                              ),
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              hospitalData['foto_url'],
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
                        vertical: 30,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: esPC ? 45 : 35,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                (hospitalData['foto_url'] != null &&
                                    hospitalData['foto_url']
                                        .toString()
                                        .isNotEmpty)
                                ? (hospitalData['foto_url']
                                          .toString()
                                          .startsWith('data:image')
                                      ? MemoryImage(
                                          base64Decode(
                                            hospitalData['foto_url']
                                                .toString()
                                                .split(',')
                                                .last,
                                          ),
                                        )
                                      : NetworkImage(hospitalData['foto_url'])
                                            as ImageProvider)
                                : null,
                            child:
                                (hospitalData['foto_url'] != null &&
                                    hospitalData['foto_url']
                                        .toString()
                                        .isNotEmpty)
                                ? null
                                : Icon(
                                    Icons.local_hospital_rounded,
                                    size: esPC ? 50 : 35,
                                    color: Colors.blue.shade700,
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
                                    fontSize: esPC ? 32 : 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 12,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
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
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
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
            // 📊 CUERPO PRINCIPAL RESPONSIVO
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
                              urgencias,
                              horario,
                              direccion,
                              ciudad,
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
                            urgencias,
                            horario,
                            direccion,
                            ciudad,
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

  Widget _buildInformacionPrincipal(
    String descripcion,
    List<String> servicios,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Acerca de
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
                'Acerca del Hospital',
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

        // Servicios y Especialidades
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
                'Servicios e Infraestructura',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  int columnas = constraints.maxWidth > 550 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: servicios.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnas,
                      mainAxisExtent: 36,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Color(0xFF0284C7),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              servicios[index],
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaContacto(
    String telGeneral,
    String telUrgencias,
    String horario,
    String direccion,
    String ciudad,
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
            'Canales de Atención',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),

          // Botón Urgencias 24h
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _hacerLlamada(telUrgencias),
              icon: const Icon(
                Icons.emergency_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'URGENCIAS 24 HRS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Botón Conmutador General
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _hacerLlamada(telGeneral),
              icon: const Icon(Icons.phone, color: Color(0xFF0284C7), size: 18),
              label: const Text(
                'Llamar a Conmutador',
                style: TextStyle(
                  color: Color(0xFF0284C7),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),

          // Horarios Dinámicos
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
                      'Horario de Operación',
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
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Dirección Física
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
                      'Dirección Clínica',
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

          // Botón Maps
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
                'Ver en Google Maps / Cómo llegar',
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
