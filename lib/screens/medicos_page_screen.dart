import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'doctor_profile_screen.dart';
import 'registro_screen.dart';
import 'lista_doctores_screen.dart';
import 'blog_detail_screen.dart';
import '../widgets/custom_app_bar.dart'; // Tu nueva barra universal

// --- MODELOS ---
class Especialidad {
  final String nombre;
  final dynamic icon;
  final Color color;
  final int medicosCount;

  Especialidad({
    required this.nombre,
    required this.icon,
    required this.color,
    this.medicosCount = 0,
  });
}

class Entrevista {
  final String thumbnail;
  final String doctorName;
  final String tema;
  final String youtubeUrl;

  Entrevista({
    required this.thumbnail,
    required this.doctorName,
    required this.tema,
    required this.youtubeUrl,
  });
}

// --- PANTALLA PRINCIPAL ---
class MedicosPageScreen extends StatefulWidget {
  const MedicosPageScreen({super.key});

  @override
  State<MedicosPageScreen> createState() => _MedicosPageScreenState();
}

class _MedicosPageScreenState extends State<MedicosPageScreen> {
  final List<Especialidad> _listaEspecialidades = [
    Especialidad(
      nombre: 'Cardiología',
      icon: FontAwesomeIcons.heartPulse,
      color: Colors.red,
    ),
    Especialidad(
      nombre: 'Pediatría',
      icon: FontAwesomeIcons.baby,
      color: Colors.blue,
    ),
    Especialidad(
      nombre: 'Ginecología',
      icon: FontAwesomeIcons.venus,
      color: Colors.purple,
    ),
    Especialidad(
      nombre: 'Dentista',
      icon: FontAwesomeIcons.tooth,
      color: Colors.teal,
    ),
    Especialidad(
      nombre: 'Neurología',
      icon: FontAwesomeIcons.brain,
      color: Colors.orange,
    ),
    Especialidad(
      nombre: 'Traumatología',
      icon: FontAwesomeIcons.bone,
      color: Colors.brown,
    ),
  ];

  Map<String, dynamic> _getEspecialidadEstilo(String nombre) {
    switch (nombre.toLowerCase().trim()) {
      case 'cardiología':
      case 'cardiologia':
        return {
          'icon': const FaIcon(
            FontAwesomeIcons.heartPulse,
            color: Colors.red,
            size: 30,
          ),
          'color': Colors.red,
        };
      case 'pediatría':
      case 'pediatria':
        return {
          'icon': const FaIcon(
            FontAwesomeIcons.baby,
            color: Colors.blue,
            size: 30,
          ),
          'color': Colors.blue,
        };
      case 'ginecología':
      case 'ginecologia':
        return {
          'icon': const FaIcon(
            FontAwesomeIcons.venus,
            color: Colors.purple,
            size: 30,
          ),
          'color': Colors.purple,
        };
      case 'dentista':
      case 'odontología':
      case 'odontologia':
        return {
          'icon': const FaIcon(
            FontAwesomeIcons.tooth,
            color: Colors.teal,
            size: 30,
          ),
          'color': Colors.teal,
        };
      case 'neurología':
      case 'neurologia':
        return {
          'icon': const FaIcon(
            FontAwesomeIcons.brain,
            color: Colors.orange,
            size: 30,
          ),
          'color': Colors.orange,
        };
      case 'traumatología':
      case 'traumatologia':
        return {
          'icon': const FaIcon(
            FontAwesomeIcons.bone,
            color: Colors.brown,
            size: 30,
          ),
          'color': Colors.brown,
        };
      case 'general':
      case 'médico general':
      case 'medicina general':
        return {
          'icon': const FaIcon(
            FontAwesomeIcons.userDoctor,
            color: Colors.green,
            size: 30,
          ),
          'color': Colors.green,
        };
      case 'neumólogo':
      case 'neumologo':
      case 'neumología':
      case 'neumologia':
        return {
          'icon': const FaIcon(
            FontAwesomeIcons.lungs,
            color: Colors.lightBlue,
            size: 30,
          ),
          'color': Colors.lightBlue,
        };
      default:
        return {
          'icon': const FaIcon(
            FontAwesomeIcons.stethoscope,
            color: Colors.blueGrey,
            size: 30,
          ),
          'color': Colors.blueGrey,
        };
    }
  }

  Future<void> _llamarTelefono(String telefono) async {
    if (telefono.isEmpty) return;
    String cleanPhone = telefono.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri url = Uri.parse('tel:$cleanPhone');
    if (!await launchUrl(url)) {
      debugPrint('No se pudo abrir la app de teléfono');
    }
  }

  Future<void> _abrirWhatsApp(String whatsapp) async {
    if (whatsapp.isEmpty) return;
    String cleanPhone = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    if (!cleanPhone.startsWith('52') && cleanPhone.length == 10) {
      cleanPhone = '52$cleanPhone';
    }
    String mensaje = Uri.encodeComponent(
      'Hola Doctor(a), vi su perfil en médicoslaguna.com y me gustaría agendar una cita.',
    );
    final Uri url = Uri.parse('https://wa.me/$cleanPhone?text=$mensaje');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('No se pudo abrir WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(), // <-- LA LÍNEA MÁGICA
      body: CustomScrollView(
        slivers: [
          _buildHeroSection(screenWidth),
          _buildEspecialidadesSection(screenWidth),
          _buildMedicosSection(screenWidth),
          _buildBlogSection(screenWidth),
          _buildEntrevistaUnicaSection(screenWidth),
          _buildBannerSoyMedico(screenWidth),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildHeroSection(double width) {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        // 👇 AQUÍ ESTÁ LA MAGIA: Un degradado suave para dar profundidad
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
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: width > 800 ? 52 : 32,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      color: const Color(0xFF0F172A),
                    ),
                    children: [
                      const TextSpan(text: 'Encuentra a los\n'),
                      TextSpan(
                        text: 'mejores médicos\n',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                      const TextSpan(text: 'en la Comarca Lagunera'),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  'Busca por especialidad y contacta a tu médico fácilmente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: width > 800 ? 19 : 16,
                    color: Colors.blueGrey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: width > 800 ? 600 : double.infinity,
                  child: _buscadorResponsivo(width),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buscadorResponsivo(double width) {
    return SizedBox(
      width: width > 800 ? 500 : width * 0.9,
      child: SearchAnchor(
        // 👇 AQUÍ ESTÁ LA MAGIA DEL DISEÑO PARA LA VENTANA DESPLEGABLE 👇
        viewBackgroundColor: Colors.white,
        viewSurfaceTintColor: Colors.white,
        viewElevation: 10,
        viewShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        viewConstraints: const BoxConstraints(
          maxHeight: 350, // Para que no se haga gigante hacia abajo
        ),
        dividerColor: Colors.grey.shade200, // Una línea separadora muy sutil

        builder: (BuildContext context, SearchController controller) {
          return SearchBar(
            controller: controller,
            padding: const WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 16.0),
            ),
            onTap: () => controller.openView(),
            onChanged: (_) => controller.openView(),
            leading: const Icon(Icons.search, color: Colors.blue),
            hintText: '¿Qué especialidad buscas?',
            backgroundColor: const WidgetStatePropertyAll(Colors.white),
            elevation: const WidgetStatePropertyAll(2),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          );
        },
        suggestionsBuilder:
            (BuildContext context, SearchController controller) async {
              // 1. Buscamos a todos los médicos registrados
              final snapshot = await FirebaseFirestore.instance
                  .collection('usuarios')
                  .where('rol', isEqualTo: 'medico')
                  .get();

              // 2. Extraemos solo las especialidades únicas (sin repetir)
              Set<String> especialidadesRegistradas = {};
              for (var doc in snapshot.docs) {
                var data = doc.data() as Map<String, dynamic>;
                // Solo tomamos en cuenta doctores que estén activos
                if (data['activo'] == false) continue;

                String esp = (data['especialidad'] ?? 'General')
                    .toString()
                    .trim();
                if (esp.isNotEmpty) {
                  especialidadesRegistradas.add(esp);
                }
              }

              // 3. Filtramos por lo que el paciente está escribiendo en el buscador
              final keyword = controller.text.toLowerCase();
              final filtradas = especialidadesRegistradas.where((esp) {
                return esp.toLowerCase().contains(keyword);
              }).toList();

              // Si el paciente escribe algo raro y no hay resultados
              if (filtradas.isEmpty) {
                return [
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Icon(Icons.search_off, color: Colors.grey),
                        SizedBox(width: 15),
                        Text(
                          'No hay especialistas con este término.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ];
              }

              // 4. Dibujamos la lista de resultados reales, mucho más limpia
              return filtradas.map((espName) {
                var estilo = _getEspecialidadEstilo(espName);
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: (estilo['color'] as Color).withOpacity(
                        0.1,
                      ),
                      child: estilo['icon'] as Widget,
                    ),
                    title: Text(
                      espName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1F36),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      controller.closeView(espName);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ListaDoctoresScreen(especialidad: espName),
                        ),
                      );
                    },
                  ),
                );
              }).toList();
            },
      ),
    );
  }

  Widget _buildEspecialidadesSection(double width) {
    return SliverToBoxAdapter(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Especialidades populares',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .where('rol', isEqualTo: 'medico')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text(
                      'Aún no hay médicos registrados.',
                      style: TextStyle(color: Colors.grey),
                    );
                  }

                  Map<String, int> conteoEspecialidades = {};
                  for (var doc in snapshot.data!.docs) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    String esp = (data['especialidad'] ?? 'General')
                        .toString()
                        .trim();
                    if (esp.isEmpty) esp = 'General';
                    conteoEspecialidades[esp] =
                        (conteoEspecialidades[esp] ?? 0) + 1;
                  }

                  var especialidadesOrdenadas = conteoEspecialidades.entries
                      .toList();
                  especialidadesOrdenadas.sort(
                    (a, b) => b.value.compareTo(a.value),
                  );

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: especialidadesOrdenadas.map((entry) {
                        var estilo = _getEspecialidadEstilo(entry.key);
                        return _itemEspecialidad(
                          entry.key,
                          estilo['icon'] as Widget,
                          estilo['color'] as Color,
                          entry.value,
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemEspecialidad(
    String nombre,
    Widget iconWidget,
    Color color,
    int count,
  ) {
    return Container(
      width: 160,
      padding: const EdgeInsets.only(right: 20),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListaDoctoresScreen(especialidad: nombre),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: color.withOpacity(0.08),
                child: iconWidget,
              ),
              const SizedBox(height: 12),
              Text(
                nombre,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueGrey.shade900,
                ),
              ),
              Text(
                '$count médico${count == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicosSection(double width) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: width > 1200 ? (width - 1200) / 2 : 20,
        vertical: 40,
      ),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Médicos destacados',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .where('rol', isEqualTo: 'medico')
                  .where('tipo_perfil', isEqualTo: 'pro')
                  .limit(4)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'Próximamente los mejores especialistas de la región.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                var doctoresPro = snapshot.data!.docs;
                return width > 800
                    ? _gridMedicos(doctoresPro)
                    : _carruselMedicos(doctoresPro);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridMedicos(List<QueryDocumentSnapshot> docs) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: docs
          .map((doc) => SizedBox(width: 320, child: _cardDoctorPro(doc)))
          .toList(),
    );
  }

  Widget _carruselMedicos(List<QueryDocumentSnapshot> docs) {
    return SizedBox(
      height: 420,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: docs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 15),
        itemBuilder: (context, index) =>
            SizedBox(width: 300, child: _cardDoctorPro(docs[index])),
      ),
    );
  }

  Widget _cardDoctorPro(QueryDocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String doctorUid = doc.id; // <-- CAPTURAMOS EL ID DEL DOCTOR PARA EL SENSOR

    String nombre = data['nombre'] ?? '';
    String apellidos = data['apellidos'] ?? '';
    String iniciales = '';
    if (nombre.isNotEmpty) iniciales += nombre[0];
    if (apellidos.isNotEmpty) iniciales += apellidos[0];

    String nombreCompleto = 'Dr(a). $nombre $apellidos';
    String specialty = data['especialidad'] ?? 'Medicina General';
    String cedula = data['cedula'] ?? 'S/N';
    String? fotoUrl = data['foto_url'];

    List<dynamic> consultorios = data['consultorios'] ?? [];
    Map<String, dynamic> primerConsultorio = consultorios.isNotEmpty
        ? consultorios[0]
        : {};

    String address =
        primerConsultorio['direccion']?.toString().isNotEmpty == true
        ? primerConsultorio['direccion']
        : 'Dirección por definir';
    String phone = primerConsultorio['telefono']?.toString().isNotEmpty == true
        ? primerConsultorio['telefono']
        : 'No disponible';
    String whatsapp =
        primerConsultorio['whatsapp']?.toString().isNotEmpty == true
        ? primerConsultorio['whatsapp']
        : '';

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
        mainAxisSize: MainAxisSize.min,
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
                        iniciales.toUpperCase(),
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
                      nombreCompleto,
                      style: const TextStyle(
                        fontSize: 16,
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
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 12),
                        Icon(Icons.star, color: Colors.amber, size: 12),
                        Icon(Icons.star, color: Colors.amber, size: 12),
                        Icon(Icons.star, color: Colors.amber, size: 12),
                        Icon(Icons.star, color: Colors.amber, size: 12),
                        SizedBox(width: 5),
                        Text(
                          '(1 reseñas)',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _contactRowHome(Icons.location_on, Colors.blue, address),
          const SizedBox(height: 10),
          _contactRowHome(Icons.phone, Colors.blue, phone),
          const SizedBox(height: 20),

          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // 👇 SENSOR DE WHATSAPP 👇
                    String fechaHoy =
                        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
                    FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(doctorUid)
                        .update({
                          'clics_wa': FieldValue.increment(1),
                          'ultimo_contacto': fechaHoy,
                        })
                        .catchError(
                          (e) => debugPrint("Error en sensor WA: $e"),
                        );

                    // Ejecuta la función de abrir WhatsApp original
                    _abrirWhatsApp(whatsapp);
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
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // 👇 SENSOR DE VISITA AL PERFIL 👇
                    FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(doctorUid)
                        .update({'visitas': FieldValue.increment(1)})
                        .catchError(
                          (e) => debugPrint("Error en sensor Visitas: $e"),
                        );

                    // Abre el perfil
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DoctorProfileScreen(doctorData: data),
                      ),
                    );
                  },
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

  Widget _contactRowHome(IconData icon, Color iconColor, String text) {
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
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // --- BLOG DE SALUD EN VIVO (CONECTADO A FIREBASE) ---
  Future<List<Map<String, dynamic>>> _fetchAllBlogs() async {
    List<Map<String, dynamic>> allBlogs = [];

    try {
      QuerySnapshot doctores = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('rol', isEqualTo: 'medico')
          .where('tipo_perfil', isEqualTo: 'pro')
          .get();

      for (var doc in doctores.docs) {
        String doctorName = "Dr(a). ${doc['nombre']} ${doc['apellidos']}"
            .trim();

        QuerySnapshot blogsSnapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(doc.id)
            .collection('mis_blogs')
            .get();

        for (var blogDoc in blogsSnapshot.docs) {
          var blogData = blogDoc.data() as Map<String, dynamic>;
          blogData['doctorName'] = doctorName;
          blogData['doctorData'] = doc.data() as Map<String, dynamic>;
          blogData['doctorData']['uid'] = doc.id;
          allBlogs.add(blogData);
        }
      }

      allBlogs.sort((a, b) {
        Timestamp timeA = a['fecha'] ?? Timestamp.now();
        Timestamp timeB = b['fecha'] ?? Timestamp.now();
        return timeB.compareTo(timeA);
      });
    } catch (e) {
      debugPrint("🚨 ERROR AL DESCARGAR BLOGS: $e");
    }

    return allBlogs;
  }

  Widget _buildBlogSection(double width) {
    return SliverToBoxAdapter(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchAllBlogs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              List<Map<String, dynamic>> globalBlogs = snapshot.data!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Blog de Salud',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 350,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: globalBlogs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 20),
                      itemBuilder: (context, index) =>
                          _buildBlogCard(globalBlogs[index], globalBlogs),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBlogCard(
    Map<String, dynamic> post,
    List<Map<String, dynamic>> allBlogs,
  ) {
    String? imgData = post['img'];
    String doctorName = post['doctorName'] ?? 'Médico Especialista';

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: (imgData != null && imgData.isNotEmpty)
                  ? (imgData.startsWith('http')
                        ? Image.network(
                            imgData,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.memory(
                            base64Decode(imgData),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ))
                  : Image.network(
                      'https://via.placeholder.com/400x300',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['title'] ?? 'Sin título',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Por $doctorName',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                Text(
                  post['desc'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlogDetailScreen(
                            blogPost: post,
                            doctorName: doctorName,
                            allBlogs: allBlogs,
                            doctorData: post['doctorData'],
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Leer más',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ENTREVISTA ÚNICA CENTRADA ---
  Widget _buildEntrevistaUnicaSection(double width) {
    final entrevista = Entrevista(
      thumbnail: 'assets/images/medicos_laguna_portada.png',
      doctorName: '',
      tema: '', // Lo dejamos vacío porque el texto ahora va arriba
      youtubeUrl: 'https://youtu.be/hAZ_5PyFcD0',
    );

    return SliverToBoxAdapter(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.center, // <-- CENTRAMOS TODO AQUÍ
            children: [
              // --- TÍTULO Y SUBTÍTULO CENTRADOS ---
              const Text(
                'Conoce más sobre Médicos Laguna',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1F36),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Descubre cómo conectamos a los pacientes con los especialistas más destacados de la Comarca Lagunera.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blueGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // --- EL VIDEO ENORME ---
              SizedBox(
                width: width > 800
                    ? 800
                    : width *
                          0.9, // Lo hicimos un poco más ancho (800) para que luzca espectacular
                child: _buildVideoCard(entrevista),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(Entrevista entrevista) {
    return GestureDetector(
      onTap: () async {
        final Uri url = Uri.parse(entrevista.youtubeUrl);
        if (!await launchUrl(url)) throw Exception('No se pudo abrir $url');
      },
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                20,
              ), // Bordes un poco más redonditos
              child: Image.asset(
                entrevista.thumbnail,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(
                  0.15,
                ), // Un oscurecido muy sutil
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            // --- BOTÓN DE PLAY ANIMADO (Visualmente) ---
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 40, // Lo hicimos más grandecito
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.play_arrow_rounded, // Un ícono de play más moderno
                  color: Colors.blue,
                  size: 55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BLOQUE BANNER DE "SOY MÉDICO" (DISEÑO PREMIUM) ---
  Widget _buildBannerSoyMedico(double width) {
    return SliverToBoxAdapter(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
          decoration: BoxDecoration(
            // 1. Degradado elegante para quitar lo "plano"
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1E3A8A),
                Color(0xFF3B82F6),
              ], // De azul oscuro a azul brillante
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            // Sombra para que resalte del fondo
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(60, 40, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿Eres médico?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 36,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Únete al directorio médico más moderno de la Comarca Lagunera y haz crecer tu consultorio.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // 2. Viñetas de beneficios para convencer al doctor
                      _beneficioItem('Perfil profesional en minutos'),
                      _beneficioItem('Mayor visibilidad para pacientes'),
                      _beneficioItem('Conexión directa a tu WhatsApp'),

                      const SizedBox(height: 35),

                      // 3. Botón con más "Llamado a la acción"
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegistroScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.rocket_launch, size: 18),
                        label: const Text(
                          'Crear mi perfil gratis',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(
                            0xFF1E3A8A,
                          ), // Azul oscuro para contraste
                          padding: const EdgeInsets.symmetric(
                            horizontal: 35,
                            vertical: 20,
                          ),
                          elevation: 5, // Sombrilla al botón
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, right: 40),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Image.asset(
                      'assets/images/doctor_banner.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person,
                        size: 150,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Pequeño widget auxiliar para las viñetas del banner
  Widget _beneficioItem(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
