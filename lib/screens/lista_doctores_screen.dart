import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'doctor_basic_profile_screen.dart';
import 'doctor_profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_app_bar.dart';
import 'package:web_smooth_scroll/web_smooth_scroll.dart';

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
  final ScrollController _scrollController = ScrollController();
  String _textoFiltrado = "";

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 750;
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(),
      body: WebSmoothScroll(
        controller: _scrollController,
        scrollSpeed: 130,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1100),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ENCABEZADO ---
                  Text(
                    'Resultados para $textoFiltro',
                    style: TextStyle(
                      fontSize: isMobile ? 22 : 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Contacta directamente a los mejores especialistas verificados de la región.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // --- BARRA DE BÚSQUEDA ---
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.04),
                          blurRadius: 16,
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
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: esBusquedaPorCiudad
                            ? 'Filtrar por especialidad (Ej. Dentista, Pediatra...)'
                            : 'Filtrar por municipio (Ej. Durango, Gómez Palacio...)',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          esBusquedaPorCiudad
                              ? Icons.medical_services_outlined
                              : Icons.location_on_outlined,
                          color: const Color(0xFF2563EB),
                          size: 20,
                        ),
                        suffixIcon: _textoFiltrado.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Color(0xFF94A3B8),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _textoFiltrado = "";
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- LISTADO STREAM ---
                  StreamBuilder<QuerySnapshot>(
                    stream: queryMedicos.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Ocurrió un error al cargar los datos.'),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(child: CircularProgressIndicator()),
                        );
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
                            if (!espDoctor.contains(_textoFiltrado))
                              return false;
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
                                espBusqueda.contains('dentista') ||
                                espBusqueda.contains('periodoncia')) {
                              if (!(espDoctor.contains('odontología') ||
                                  espDoctor.contains('dentista') ||
                                  espDoctor.contains('odontologia') ||
                                  espDoctor.contains('periodoncia'))) {
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
                            if (!ciudadDoc.contains(ciudadBusqueda))
                              return false;
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
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          mainAxisExtent: 260,
                        ),
                        itemCount: docsFiltrados.length,
                        itemBuilder: (context, index) {
                          var doc = docsFiltrados[index];
                          Map<String, dynamic> data =
                              doc.data() as Map<String, dynamic>;

                          // Inyectamos el ID para garantizar que abra el perfil
                          data['uid'] = doc.id;
                          data['id'] = doc.id;

                          String nombre = data['nombre'] ?? '';
                          String apellidos = data['apellidos'] ?? '';
                          String iniciales = '';
                          if (nombre.isNotEmpty) iniciales += nombre[0];
                          if (apellidos.isNotEmpty) iniciales += apellidos[0];

                          List<dynamic> consultorios =
                              data['consultorios'] ?? [];
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 64,
            color: const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aún no hay especialistas registrados para esta búsqueda.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatarDoctor(fotoUrl, initials, isPro: false),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialty,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cédula: $cedula',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
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
          _contactRow(
            Icons.location_on_outlined,
            const Color(0xFF64748B),
            address,
          ),
          const SizedBox(height: 6),
          _contactRow(Icons.phone_outlined, const Color(0xFF64748B), phone),
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
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Ver perfil completo →',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatarDoctor(fotoUrl, initials, isPro: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialty,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cédula: $cedula',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          totalResenas == 0
                              ? '5.0 (Nuevo)'
                              : '5.0 ($totalResenas opiniones)',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _contactRow(
            Icons.location_on_outlined,
            const Color(0xFF64748B),
            address,
          ),
          const SizedBox(height: 4),
          _contactRow(Icons.phone_outlined, const Color(0xFF64748B), phone),
          const Spacer(),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (whatsapp.isNotEmpty) _abrirWhatsApp(whatsapp);
                },
                icon: const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFE6F7F0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DoctorProfileScreen(doctorData: doctorData),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2563EB),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: const Text(
                    'Ver perfil completo →',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarDoctor(
    String? fotoUrl,
    String initials, {
    required bool isPro,
  }) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: isPro ? const Color(0xFFF0FDFA) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPro ? const Color(0xFF99F6E4) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: (fotoUrl != null && fotoUrl.isNotEmpty)
            ? (fotoUrl.startsWith('http')
                  ? Image.network(
                      fotoUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    )
                  : Image.memory(
                      base64Decode(fotoUrl),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ))
            : Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: isPro
                        ? const Color(0xFF0D9488)
                        : const Color(0xFF64748B),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _contactRow(IconData icon, Color iconColor, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
