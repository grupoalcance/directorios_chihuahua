import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:async'; // 👈 Necesario para los Timers de autorotación
import 'doctor_profile_screen.dart';
import 'registro_screen.dart';
import 'lista_doctores_screen.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/phone_menu_drawer.dart';

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

// --- PANTALLA PRINCIPAL ---
class MedicosPageScreen extends StatefulWidget {
  const MedicosPageScreen({super.key});

  @override
  State<MedicosPageScreen> createState() => _MedicosPageScreenState();
}

class _MedicosPageScreenState extends State<MedicosPageScreen> {
  // Controladores para las cajas del buscador avanzado de 2 bloques
  final TextEditingController _especialidadController = TextEditingController();
  final TextEditingController _ciudadBuscadorController =
      TextEditingController();

  // Controladores de Scroll para las rotaciones automáticas
  final ScrollController _especialidadesScrollController = ScrollController();
  final ScrollController _medicosScrollController = ScrollController();
  Timer? _timerEspecialidades;
  Timer? _timerMedicos;

  @override
  void initState() {
    super.initState();
    _iniciarAutoScrolls();
  }

  // Lógica para que las listas populares y destacados roten solas
  void _iniciarAutoScrolls() {
    _timerEspecialidades = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_especialidadesScrollController.hasClients) {
        double maxScroll =
            _especialidadesScrollController.position.maxScrollExtent;
        double currentScroll = _especialidadesScrollController.position.pixels;
        double targetScroll = currentScroll + 180; // Avanza una burbuja

        if (currentScroll >= maxScroll - 10) {
          _especialidadesScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        } else {
          _especialidadesScrollController.animateTo(
            targetScroll,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      }
    });

    _timerMedicos = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_medicosScrollController.hasClients) {
        double maxScroll = _medicosScrollController.position.maxScrollExtent;
        double currentScroll = _medicosScrollController.position.pixels;
        double targetScroll = currentScroll + 340; // Avanza una tarjeta

        if (currentScroll >= maxScroll - 10) {
          _medicosScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
          );
        } else {
          _medicosScrollController.animateTo(
            targetScroll,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _especialidadController.dispose();
    _ciudadBuscadorController.dispose();
    _especialidadesScrollController.dispose();
    _medicosScrollController.dispose();
    _timerEspecialidades?.cancel();
    _timerMedicos?.cancel();
    super.dispose();
  }

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
      appBar: CustomAppBar(
        onCiudadSeleccionada: (String ciudadElegida) {
          // Si eligen una ciudad en la barra de arriba de la página, los manda directo a la búsqueda filtrada de esa ciudad
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ListaDoctoresScreen(especialidad: '', ciudad: ciudadElegida),
            ),
          );
        },
      ),
      drawer: screenWidth < 1100 ? const PhoneMenuDrawer() : null,
      body: CustomScrollView(
        slivers: [
          _buildHeroSection(screenWidth),
          _buildEspecialidadesSection(screenWidth),
          _buildMedicosSection(screenWidth),
          _buildClinicasYFarmaciasSection(screenWidth),
          _buildBannerSoyMedico(screenWidth),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. HERO SECTION PREMIUM CON BUSCADOR DE 2 BLOQUES (ESPECIALIDAD Y CIUDAD)
  // =========================================================================
  Widget _buildHeroSection(double width) {
    bool esPC = width > 850;

    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        height: esPC ? 420 : 580,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/hero_dra.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.98),
                      Colors.white.withOpacity(0.85),
                      Colors.white.withOpacity(0.1),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Encuentra a los\nmejores médicos\nen la Comarca Lagunera',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Busca por especialidad, ubicación o nombre y agenda tu cita fácilmente.',
                      style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 35),

                    // Tarjeta Flotante Multi-Buscador de 2 Bloques
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: esPC
                          ? Row(
                              children: [
                                Expanded(
                                  child: _buildInputEspecialidadAutocompletar(),
                                ),
                                Container(
                                  width: 1,
                                  height: 45,
                                  color: Colors.grey.shade200,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                  ),
                                ),
                                Expanded(
                                  child: _buildInputCiudadAutocompletar(),
                                ),
                                const SizedBox(width: 20),
                                _buildBotonBuscar(),
                              ],
                            )
                          : Column(
                              children: [
                                _buildInputEspecialidadAutocompletar(),
                                const Divider(height: 25),
                                _buildInputCiudadAutocompletar(),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: _buildBotonBuscar(),
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
    );
  }

  Widget _buildInputEspecialidadAutocompletar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Qué especialidad buscas?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        RawAutocomplete<String>(
          textEditingController: _especialidadController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            final snapshot = await FirebaseFirestore.instance
                .collection('usuarios')
                .where('rol', isEqualTo: 'medico')
                .get();
            Set<String> especialidades = {};
            for (var doc in snapshot.docs) {
              var data = doc.data() as Map<String, dynamic>;
              if (data['activo'] == false) continue;
              String esp = (data['especialidad'] ?? 'General')
                  .toString()
                  .trim();
              if (esp.isNotEmpty) especialidades.add(esp);
            }
            return especialidades.where((String option) {
              return option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: 'Ej. Cardiólogo, Pediatra...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: Icon(
                  Icons.search,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 300,
                    maxHeight: 200,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option,
                          style: const TextStyle(fontSize: 13),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInputCiudadAutocompletar() {
    final List<String> lasCiudades = [
      'Torreón',
      'Gómez Palacio',
      'Lerdo',
      'San Pedro',
      'Fco. I. Madero',
      'Matamoros',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿En qué ciudad?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        RawAutocomplete<String>(
          textEditingController: _ciudadBuscadorController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) {
            return lasCiudades.where((String option) {
              return option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: 'Torreón, Gómez Palacio...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 300,
                    maxHeight: 200,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option,
                          style: const TextStyle(fontSize: 13),
                        ),
                        onTap: () => onSelected(
                          option,
                        ), // Al dar clic, solo llena el input de la caja, no filtra el inicio
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBotonBuscar() {
    return ElevatedButton(
      onPressed: () {
        // 👇 AQUÍ SE HACE LA REDIRECCIÓN CON LOS FILTROS ELEGIDOS 👇
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListaDoctoresScreen(
              especialidad: _especialidadController.text.trim(),
              ciudad: _ciudadBuscadorController.text
                  .trim(), // Se va con la ciudad que escribió o seleccionó
            ),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0061E0),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: const Text(
        'Buscar médicos',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  // =========================================================================
  // 2. ESPECIALIDADES POPULARES (SIEMPRE VISIBLE)
  // =========================================================================
  Widget _buildEspecialidadesSection(double width) {
    return SliverToBoxAdapter(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Especialidades populares',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Row(
                      children: [
                        Text('Ver todas ', style: TextStyle(fontSize: 13)),
                        Icon(Icons.arrow_forward, size: 13),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              StreamBuilder<QuerySnapshot>(
                // 👇 Corregido: Muestra siempre todas las especialidades de la base de datos sin importar qué escriban arriba
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .where('rol', isEqualTo: 'medico')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const SizedBox(
                      height: 140,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return const Text(
                      'Aún no hay especialidades registradas.',
                      style: TextStyle(color: Colors.grey),
                    );

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

                  return SizedBox(
                    height: 140,
                    child: ListView.builder(
                      controller: _especialidadesScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: especialidadesOrdenadas.length,
                      itemBuilder: (context, index) {
                        var entry = especialidadesOrdenadas[index];
                        var estilo = _getEspecialidadEstilo(entry.key);
                        return _itemEspecialidad(
                          entry.key,
                          estilo['icon'] as Widget,
                          estilo['color'] as Color,
                          entry.value,
                        );
                      },
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
      width: 150,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ListaDoctoresScreen(especialidad: nombre, ciudad: ''),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.06),
                child: iconWidget,
              ),
              const SizedBox(height: 8),
              Text(
                nombre,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count doctor${count == 1 ? '' : 'es'}',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 3. MÉDICOS DESTACADOS (SIEMPRE VISIBLE)
  // =========================================================================
  Widget _buildMedicosSection(double width) {
    return SliverToBoxAdapter(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Médicos destacados',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Los mejor calificados por nuestros pacientes',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Row(
                      children: [
                        Text('Ver todos ', style: TextStyle(fontSize: 13)),
                        Icon(Icons.arrow_forward, size: 13),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                // 👇 Corregido: Trae siempre a los mejores médicos PRO globales para poblar el carrusel de inicio fijo
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .where('rol', isEqualTo: 'medico')
                    .where('activo', isEqualTo: true)
                    .where('tipo_perfil', isEqualTo: 'pro')
                    .limit(8)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return const Text(
                      'Próximamente los mejores especialistas de la region.',
                      style: TextStyle(color: Colors.grey),
                    );

                  var doctoresPro = snapshot.data!.docs;

                  return SizedBox(
                    height: 355,
                    child: ListView.builder(
                      controller: _medicosScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: doctoresPro.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 310,
                          margin: const EdgeInsets.only(right: 15, bottom: 5),
                          child: _cardDoctorPro(doctoresPro[index]),
                        );
                      },
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

  Widget _cardDoctorPro(QueryDocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    int totalResenas = data['reseñas_count'] ?? 0;

    String nombre = data['nombre'] ?? '';
    String apellidos = data['apellidos'] ?? '';
    String iniciales =
        '${nombre.isNotEmpty ? nombre[0] : ''}${apellidos.isNotEmpty ? apellidos[0] : ''}';
    String nombreCompleto = '$nombre $apellidos'.trim();
    String specialty = data['especialidad'] ?? 'Medicina General';
    String? fotoUrl = data['foto_url'];

    List<dynamic> consultorios = data['consultorios'] ?? [];
    Map<String, dynamic> primerConsultorio = consultorios.isNotEmpty
        ? consultorios[0]
        : {};
    String address =
        primerConsultorio['direccion']?.toString().isNotEmpty == true
        ? primerConsultorio['direccion']
        : 'Dirección por definir';
    String whatsapp =
        primerConsultorio['whatsapp']?.toString().isNotEmpty == true
        ? primerConsultorio['whatsapp']
        : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  height: 150,
                  color: Colors.grey.shade100,
                  child: (fotoUrl != null && fotoUrl.isNotEmpty)
                      ? (fotoUrl.startsWith('http')
                            ? Image.network(fotoUrl, fit: BoxFit.cover)
                            : Image.memory(
                                base64Decode(fotoUrl),
                                fit: BoxFit.cover,
                              ))
                      : Center(
                          child: Text(
                            iniciales.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'DESTACADO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            nombreCompleto,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            specialty,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text(
                totalResenas == 0 ? 'New' : '5.0 ($totalResenas opiniones)',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.grey, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              IconButton(
                onPressed: () => _abrirWhatsApp(whatsapp),
                icon: const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: Color(0xFF10B981),
                  size: 20,
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
                          DoctorProfileScreen(doctorData: data),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    elevation: 0,
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Ver perfil',
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

  // =========================================================================
  // 4. SECCIÓN COMBINADA: CLÍNICAS RECOMENDADAS Y FARMACIAS CERCANAS
  // =========================================================================
  Widget _buildClinicasYFarmaciasSection(double width) {
    bool esPC = width > 950;

    Widget gridClinicas = Wrap(
      spacing: 15,
      runSpacing: 15,
      children: [
        _cardEstaticaInformativa(
          'Hospital Angeles',
          'Torreón, Coahuila',
          'assets/images/medicos_laguna_portada.png',
          '5.0',
        ),
        _cardEstaticaInformativa(
          'Sanatorio Español',
          'Torreón, Coahuila',
          'assets/images/medicos_laguna_portada.png',
          '4.7',
        ),
        _cardEstaticaInformativa(
          'Hospital La Concepción',
          'Gómez Palacio, Dgo',
          'assets/images/medicos_laguna_portada.png',
          '4.6',
        ),
      ],
    );

    Widget gridFarmacias = Wrap(
      spacing: 15,
      runSpacing: 15,
      children: [
        _cardEstaticaInformativa(
          'Farmacias Guadalajara',
          'Ver sucursales >',
          'assets/images/medicos_laguna_portada.png',
          '5.0',
          esFarmacia: true,
        ),
        _cardEstaticaInformativa(
          'Farmacias del Ahorro',
          'Ver sucursales >',
          'assets/images/medicos_laguna_portada.png',
          '4.7',
          esFarmacia: true,
        ),
        _cardEstaticaInformativa(
          'Benavides',
          'Ver sucursales >',
          'assets/images/medicos_laguna_portada.png',
          '4.5',
          esFarmacia: true,
        ),
      ],
    );

    return SliverToBoxAdapter(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: esPC
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _headerSeccionEstatica('Clínicas recomendadas'),
                          const SizedBox(height: 15),
                          gridClinicas,
                        ],
                      ),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _headerSeccionEstatica('Farmacias cercanas'),
                          const SizedBox(height: 15),
                          gridFarmacias,
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _headerSeccionEstatica('Clínicas recomendadas'),
                    const SizedBox(height: 15),
                    gridClinicas,
                    const SizedBox(height: 35),
                    _headerSeccionEstatica('Farmacias cercanas'),
                    const SizedBox(height: 15),
                    gridFarmacias,
                  ],
                ),
        ),
      ),
    );
  }

  Widget _headerSeccionEstatica(String titulo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Row(
            children: [
              Text('Ver todas ', style: TextStyle(fontSize: 12)),
              Icon(Icons.arrow_forward, size: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cardEstaticaInformativa(
    String nombre,
    String sub,
    String imgAsset,
    String score, {
    bool esFarmacia = false,
  }) {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imgAsset,
              height: 95,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                esFarmacia ? Icons.storefront : Icons.star,
                color: esFarmacia ? Colors.blue : Colors.amber,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                score,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: esFarmacia ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 5. BANNER REGISTRO DE MÉDICOS ("¿ERES ESPECIALISTA?")
  // =========================================================================
  Widget _buildBannerSoyMedico(double width) {
    return SliverToBoxAdapter(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
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
                        '¿Eres especialista?',
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
                      _beneficioItem('Perfil profesional en minutos'),
                      _beneficioItem('Mayor visibilidad para pacientes'),
                      _beneficioItem('Conexión directa a tu WhatsApp'),
                      const SizedBox(height: 35),
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
                          foregroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 35,
                            vertical: 20,
                          ),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (width > 800)
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
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
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
