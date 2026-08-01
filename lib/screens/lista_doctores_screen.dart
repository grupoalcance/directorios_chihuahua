import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'doctor_basic_profile_screen.dart';
import 'doctor_profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_app_bar.dart';

class ListaDoctoresScreen extends StatefulWidget {
  final String especialidad;
  final String ciudad;

  const ListaDoctoresScreen({
    Key? key,
    required this.especialidad,
    this.ciudad = '',
  }) : super(key: key);

  @override
  State<ListaDoctoresScreen> createState() => _ListaDoctoresScreenState();
}

class _ListaDoctoresScreenState extends State<ListaDoctoresScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _textoFiltrado = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- FUNCIÓN PARA WHATSAPP ---
  Future<void> _abrirWhatsApp(String whatsapp) async {
    if (whatsapp.isEmpty) return;
    String cleanPhone = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    if (!cleanPhone.startsWith('52') && cleanPhone.length == 10) {
      cleanPhone = '52$cleanPhone';
    }
    String mensaje = Uri.encodeComponent(
      'Hola, vi su perfil en médicosdurango.com y me gustaría agendar una cita o pedir información.',
    );
    final Uri url = Uri.parse('https://wa.me/$cleanPhone?text=$mensaje');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('No se pudo abrir WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool esBusquedaPorCiudad =
        widget.ciudad.isNotEmpty && widget.especialidad.isEmpty;

    String textoFiltro = widget.especialidad.isNotEmpty
        ? widget.especialidad
        : 'Especialistas';
    if (widget.ciudad.isNotEmpty) {
      textoFiltro += ' en ${widget.ciudad}';
    }

    Query queryMedicos = FirebaseFirestore.instance
        .collection('usuarios')
        .where('rol', isEqualTo: 'medico')
        .where('activo', isEqualTo: true);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: const CustomAppBar(),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
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
              const SizedBox(height: 20),

              // BARRA DE BÚSQUEDA HÍBRIDA
              Container(
                margin: const EdgeInsets.only(bottom: 25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _textoFiltrado = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: esBusquedaPorCiudad
                        ? 'Filtrar por especialidad (Ej. Dentista, Cardiólogo, Pediatra...)'
                        : 'Filtrar por municipio (Ej. Durango, Gómez Palacio, Lerdo...)',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      esBusquedaPorCiudad
                          ? Icons.medical_services_outlined
                          : Icons.location_on,
                      color: Colors.blue,
                    ),
                    suffixIcon: _textoFiltrado.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _textoFiltrado = "";
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.grey.shade100),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.grey.shade100),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: queryMedicos.snapshots(),
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
                      return _buildNoResults();
                    }

                    var docsFiltrados = snapshot.data!.docs.where((doc) {
                      Map<String, dynamic> data =
                          doc.data() as Map<String, dynamic>;

                      List<dynamic> consultorios = data['consultorios'] ?? [];
                      Map<String, dynamic> primerConsultorio =
                          consultorios.isNotEmpty ? consultorios[0] : {};

                      String ciudadDoc = (primerConsultorio['ciudad'] ?? '')
                          .toString()
                          .toLowerCase()
                          .trim();

                      String espDoctor = (data['especialidad'] ?? '')
                          .toString()
                          .toLowerCase()
                          .trim();

                      if (esBusquedaPorCiudad) {
                        String ciudadBusqueda = widget.ciudad
                            .toLowerCase()
                            .trim();
                        bool matchCiudadBase =
                            ciudadDoc == ciudadBusqueda ||
                            (ciudadBusqueda.contains('durango') &&
                                ciudadDoc.contains('durango')) ||
                            (ciudadBusqueda.contains('gómez') &&
                                ciudadDoc.contains('gomez')) ||
                            (ciudadBusqueda.contains('gomez') &&
                                ciudadDoc.contains('gómez'));

                        if (!matchCiudadBase) return false;

                        if (_textoFiltrado.isNotEmpty) {
                          if (!espDoctor.contains(_textoFiltrado)) return false;
                        }
                      } else {
                        if (_textoFiltrado.isNotEmpty) {
                          String direccionDoc =
                              (primerConsultorio['direccion'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .trim();

                          bool matchBarra =
                              ciudadDoc.contains(_textoFiltrado) ||
                              direccionDoc.contains(_textoFiltrado);
                          if (!matchBarra) return false;
                        }

                        if (widget.especialidad.isNotEmpty) {
                          String espBusqueda = widget.especialidad
                              .toLowerCase()
                              .trim();

                          if (espBusqueda.contains('uroginecología') ||
                              espBusqueda.contains('uroginecologia')) {
                            if (!(espDoctor.contains('uroginecología') ||
                                espDoctor.contains('uroginecologia'))) {
                              return false;
                            }
                          } else if (espBusqueda.contains('odontología') ||
                              espBusqueda.contains('dentista')) {
                            if (!(espDoctor.contains('odontología') ||
                                espDoctor.contains('dentista') ||
                                espDoctor.contains('odontologia'))) {
                              return false;
                            }
                          } else if (espBusqueda.contains('ginecología') ||
                              espBusqueda.contains('ginecologia')) {
                            if (!(espDoctor.contains('ginecología') ||
                                espDoctor.contains('ginecologia'))) {
                              return false;
                            }
                          } else if (espBusqueda.contains('traumatología') ||
                              espBusqueda.contains('traumatologia')) {
                            if (!(espDoctor.contains('traumatología') ||
                                espDoctor.contains('traumatologia') ||
                                espDoctor.contains('ortopedia'))) {
                              return false;
                            }
                          } else {
                            if (espDoctor != espBusqueda) return false;
                          }
                        }

                        if (widget.ciudad.isNotEmpty) {
                          String ciudadBusqueda = widget.ciudad
                              .toLowerCase()
                              .trim();
                          if (!ciudadDoc.contains(ciudadBusqueda)) return false;
                        }
                      }

                      return true;
                    }).toList();

                    if (docsFiltrados.isEmpty) {
                      return _buildNoResults();
                    }

                    docsFiltrados.sort((a, b) {
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

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 750
                            ? 2
                            : 1,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        // 🔑 CORREGIDO: Incrementado a 380 para evitar el aviso de desbordamiento (bottom overflow)
                        mainAxisExtent: 380,
                      ),
                      itemCount: docsFiltrados.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> data =
                            docsFiltrados[index].data() as Map<String, dynamic>;

                        String nombre = data['nombre'] ?? '';
                        String apellidos = data['apellidos'] ?? '';
                        String iniciales = '';
                        if (nombre.isNotEmpty) iniciales += nombre[0];
                        if (apellidos.isNotEmpty) iniciales += apellidos[0];

                        List<dynamic> consultorios = data['consultorios'] ?? [];
                        Map<String, dynamic> primerConsultorio =
                            consultorios.isNotEmpty ? consultorios[0] : {};

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

                        String tipoPerfil = data['tipo_perfil'] ?? 'basico';

                        return _decidirTarjeta(
                          context,
                          data,
                          iniciales.toUpperCase(),
                          '$nombre $apellidos'.trim(),
                          data['especialidad'] ?? widget.especialidad,
                          data['cedula'] ?? 'S/N',
                          direccionDoctor,
                          telefonoDoctor,
                          whatsappDoctor,
                          tipoPerfil,
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

  Widget _buildNoResults() {
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
          const Text(
            'Aún no hay especialistas registrados para esta búsqueda.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

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
      padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1F36),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialty,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.lightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cédula: $cedula',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _contactRow(Icons.location_on, Colors.blue, address),
          const SizedBox(height: 6),
          _contactRow(Icons.phone, Colors.blue, phone),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DoctorBasicProfileScreen(doctorData: doctorData),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue),
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
    );
  }

  // 🔑 TARJETA PRO REDISEÑADA PARA EVITAR BOTTOM OVERFLOW
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
      padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1F36),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
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
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialty,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.lightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cédula: $cedula',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 13),
                        const Icon(Icons.star, color: Colors.amber, size: 13),
                        const Icon(Icons.star, color: Colors.amber, size: 13),
                        const Icon(Icons.star, color: Colors.amber, size: 13),
                        const Icon(Icons.star, color: Colors.amber, size: 13),
                        const SizedBox(width: 4),
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
          const SizedBox(height: 12),
          _contactRow(Icons.location_on, Colors.blue, address),
          const SizedBox(height: 4),
          _contactRow(Icons.phone, Colors.blue, phone),
          const Spacer(),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (whatsapp.isNotEmpty) _abrirWhatsApp(whatsapp);
                  },
                  icon: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    'WhatsApp',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DoctorProfileScreen(doctorData: doctorData),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue, width: 1),
                    backgroundColor: Colors.blue.shade50,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Ver perfil completo →',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1, // 👈 Limitado a 1 línea para evitar empujar elementos
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 13,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
