import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'doctor_basic_profile_screen.dart';
import 'doctor_profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_app_bar.dart'; // <-- IMPORTAMOS LA NUEVA BARRA

class ListaDoctoresScreen extends StatelessWidget {
  final String especialidad;
  final String ciudad;

  const ListaDoctoresScreen({
    Key? key,
    required this.especialidad,
    this.ciudad = '', // 👈 Recibe la ciudad elegida de manera opcional
  }) : super(key: key);

  // --- FUNCIÓN PARA WHATSAPP (Con mensaje predeterminado) ---
  Future<void> _abrirWhatsApp(String whatsapp) async {
    if (whatsapp.isEmpty) return;

    // Limpiamos el número
    String cleanPhone = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');

    // Si el número tiene 10 dígitos (normal en México), le agregamos el código de país (52)
    if (!cleanPhone.startsWith('52') && cleanPhone.length == 10) {
      cleanPhone = '52$cleanPhone';
    }

    // Creamos un mensaje automático neutral
    String mensaje = Uri.encodeComponent(
      'Hola, vi su perfil en médicoslaguna.com y me gustaría agendar una cita o pedir información.',
    );
    final Uri url = Uri.parse('https://wa.me/$cleanPhone?text=$mensaje');

    // LaunchMode.externalApplication fuerza a que se abra la app de WhatsApp y no el navegador web
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('No se pudo abrir WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Título dinámico para la sección de resultados
    String textoFiltro = especialidad.isNotEmpty
        ? especialidad
        : 'Especialistas';
    if (ciudad.isNotEmpty) {
      textoFiltro += ' en $ciudad';
    }

    // --- CONSTRUCCIÓN DE LA QUERY DINÁMICA DE FIREBASE ---
    Query queryMedicos = FirebaseFirestore.instance
        .collection('usuarios')
        .where('rol', isEqualTo: 'medico')
        .where('activo', isEqualTo: true);

    // Si la especialidad no está vacía, aplicamos el filtro
    if (especialidad.isNotEmpty) {
      queryMedicos = queryMedicos.where(
        'especialidad',
        isEqualTo: especialidad,
      );
    }
    // Si la ciudad no está vacía, aplicamos el filtro en cascada de forma transparente
    if (ciudad.isNotEmpty) {
      queryMedicos = queryMedicos.where('ciudad', isEqualTo: ciudad);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: const CustomAppBar(), // <-- LA LÍNEA MÁGICA UNIFICADA
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resultados para $textoFiltro',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1F36),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Contacta directamente a los mejores especialistas.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 25),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: queryMedicos
                      .snapshots(), // 👈 Query optimizada con los filtros duales
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Ocurrió un error al cargar los datos.'),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search_outlined,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Aún no hay especialistas registrados para esta búsqueda.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // --- ORDENAMOS LOS DOCTORES (PRO ARRIBA, BÁSICOS ABAJO) ---
                    var doctores = snapshot.data!.docs.toList();
                    doctores.sort((a, b) {
                      Map<String, dynamic> dataA =
                          a.data() as Map<String, dynamic>;
                      Map<String, dynamic> dataB =
                          b.data() as Map<String, dynamic>;

                      String tipoA = dataA['tipo_perfil'] ?? 'basico';
                      String tipoB = dataB['tipo_perfil'] ?? 'basico';

                      if (tipoA == 'pro' && tipoB != 'pro') return -1;
                      if (tipoA != 'pro' && tipoB == 'pro') return 1;
                      return 0;
                    });

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        int columns = constraints.maxWidth > 600 ? 2 : 1;
                        double cardWidth =
                            (constraints.maxWidth - ((columns - 1) * 20)) /
                            columns;

                        return SingleChildScrollView(
                          child: Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            children: doctores.map((doc) {
                              Map<String, dynamic> data =
                                  doc.data() as Map<String, dynamic>;

                              String nombre = data['nombre'] ?? '';
                              String apellidos = data['apellidos'] ?? '';
                              String iniciales = '';
                              if (nombre.isNotEmpty) iniciales += nombre[0];
                              if (apellidos.isNotEmpty)
                                iniciales += apellidos[0];

                              // --- EXTRAEMOS EL PRIMER CONSULTORIO (PRINCIPAL) ---
                              List<dynamic> consultorios =
                                  data['consultorios'] ?? [];
                              Map<String, dynamic> primerConsultorio =
                                  consultorios.isNotEmpty
                                  ? consultorios[0]
                                  : {};

                              String direccionDoctor =
                                  primerConsultorio['direccion']
                                          ?.toString()
                                          .isNotEmpty ==
                                      true
                                  ? primerConsultorio['direccion']
                                  : 'Dirección por definir';

                              String telefonoDoctor =
                                  primerConsultorio['telefono']
                                          ?.toString()
                                          .isNotEmpty ==
                                      true
                                  ? primerConsultorio['telefono']
                                  : 'No disponible';

                              String whatsappDoctor =
                                  primerConsultorio['whatsapp']
                                          ?.toString()
                                          .isNotEmpty ==
                                      true
                                  ? primerConsultorio['whatsapp']
                                  : '';

                              String tipoPerfil =
                                  data['tipo_perfil'] ?? 'basico';

                              return SizedBox(
                                width: cardWidth,
                                child: _decidirTarjeta(
                                  context,
                                  data,
                                  iniciales.toUpperCase(),
                                  '$nombre $apellidos'.trim(),
                                  data['especialidad'] ?? especialidad,
                                  data['cedula'] ?? 'S/N',
                                  direccionDoctor,
                                  telefonoDoctor,
                                  whatsappDoctor,
                                  tipoPerfil,
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- FUNCIÓN DISTRIBUIDORA ---
  Widget _decidirTarjeta(
    BuildContext context,
    Map<String, dynamic> doctorData,
    String initials,
    String name,
    String specialty,
    String cedula,
    String address,
    String phone,
    String whatsapp,
    String tipoPerfil,
  ) {
    if (tipoPerfil == 'pro') {
      return _buildTarjetaPro(
        context,
        doctorData,
        initials,
        name,
        specialty,
        cedula,
        address,
        phone,
        whatsapp,
      );
    } else {
      return _buildTarjetaBasica(
        context,
        doctorData,
        initials,
        name,
        specialty,
        cedula,
        address,
        phone,
        whatsapp,
      );
    }
  }

  // ==========================================
  // TARJETA BÁSICA (Sencilla)
  // ==========================================
  Widget _buildTarjetaBasica(
    BuildContext context,
    Map<String, dynamic> doctorData,
    String initials,
    String name,
    String specialty,
    String cedula,
    String address,
    String phone,
    String whatsapp,
  ) {
    String? fotoUrl = doctorData['foto_url'];

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.blueGrey.shade300,
                backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty)
                    ? (fotoUrl.startsWith('http')
                          ? NetworkImage(fotoUrl) as ImageProvider
                          : MemoryImage(base64Decode(fotoUrl)))
                    : null,
                child: (fotoUrl == null || fotoUrl.isEmpty)
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1F36),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialty,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.lightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cédula: $cedula',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _contactRow(Icons.location_on, Colors.blue, address),
          const SizedBox(height: 10),
          _contactRow(Icons.phone, Colors.blue, phone),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DoctorBasicProfileScreen(doctorData: doctorData),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Ver perfil completo →',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TARJETA PRO
  // ==========================================
  Widget _buildTarjetaPro(
    BuildContext context,
    Map<String, dynamic> doctorData,
    String initials,
    String name,
    String specialty,
    String cedula,
    String address,
    String phone,
    String whatsapp,
  ) {
    String? fotoUrl = doctorData['foto_url'];
    int totalResenas = doctorData['reseñas_count'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.shade300, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.teal.shade400,
                backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty)
                    ? (fotoUrl.startsWith('http')
                          ? NetworkImage(fotoUrl) as ImageProvider
                          : MemoryImage(base64Decode(fotoUrl)))
                    : null,
                child: (fotoUrl == null || fotoUrl.isEmpty)
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1F36),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'DESTACADO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      specialty,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.lightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cédula: $cedula',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          totalResenas == 0
                              ? '(Nuevo)'
                              : '($totalResenas opiniones)',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _contactRow(Icons.location_on, Colors.blue, address),
          const SizedBox(height: 10),
          _contactRow(Icons.phone, Colors.blue, phone),
          const SizedBox(height: 20),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (whatsapp.isNotEmpty) {
                      _abrirWhatsApp(whatsapp);
                    }
                  },
                  icon: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'WhatsApp',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DoctorProfileScreen(doctorData: doctorData),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue, width: 1),
                    backgroundColor: Colors.blue.shade50,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Ver perfil completo →',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, Color iconColor, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
