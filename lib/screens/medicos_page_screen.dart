import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:async';
import 'doctor_profile_screen.dart';
import 'lista_doctores_screen.dart';
import 'todas_especialidades_screen.dart';
import 'suscribirse_screen.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/phone_menu_drawer.dart';

// --- LISTA MÁSTER HOMOLOGADA DE LAS 15 ESPECIALIDADES MÁS BUSCADAS ---
const List<String> las15EspecialidadesLaguna = [
  'Cardiología',
  'Dermatología',
  'Ginecología y Obstetricia',
  'Medicina General',
  'Neumología',
  'Neurología',
  'Nutrición',
  'Odontología (Dentista)',
  'Oftalmología',
  'Otorrinolaringología',
  'Pediatría',
  'Psicología',
  'Psiquiatría',
  'Traumatología y Ortopedia',
  'Urología',
];

class MedicosPageScreen extends StatefulWidget {
  const MedicosPageScreen({super.key});

  @override
  State<MedicosPageScreen> createState() => _MedicosPageScreenState();
}

class _MedicosPageScreenState extends State<MedicosPageScreen> {
  final TextEditingController _especialidadController = TextEditingController();
  final TextEditingController _ciudadBuscadorController =
      TextEditingController();

  final ScrollController _especialidadesScrollController = ScrollController();
  final ScrollController _medicosScrollController = ScrollController();
  Timer? _timerEspecialidades;
  Timer? _timerMedicos;

  @override
  void initState() {
    super.initState();
    _iniciarAutoScrolls();
  }

  void _iniciarAutoScrolls() {
    _timerEspecialidades = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_especialidadesScrollController.hasClients) {
        double maxScroll =
            _especialidadesScrollController.position.maxScrollExtent;
        double currentScroll = _especialidadesScrollController.position.pixels;
        double targetScroll = currentScroll + 180;

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
        double targetScroll = currentScroll + 340;

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
      case 'ginecología y obstetricia':
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
      case 'odontología (dentista)':
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
      case 'traumatología y ortopedia':
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
      case 'medicina general':
      case 'general':
        return {
          'icon': const FaIcon(
            FontAwesomeIcons.userDoctor,
            color: Colors.green,
            size: 30,
          ),
          'color': Colors.green,
        };
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
      case 'dermatología':
      case 'dermatologia':
        return {
          'icon': const FaIcon(
            FontAwesomeIcons.handDots,
            color: Colors.pink,
            size: 30,
          ),
          'color': Colors.pink,
        };
      case 'nutrición':
      case 'nutricion':
        return {
          'icon': const FaIcon(
            FontAwesomeIcons.appleWhole,
            color: Colors.lightGreen,
            size: 30,
          ),
          'color': Colors.lightGreen,
        };
      case 'oftalmología':
      case 'oftalmologia':
        return {
          'icon': const FaIcon(
            FontAwesomeIcons.eye,
            color: Colors.indigo,
            size: 30,
          ),
          'color': Colors.indigo,
        };
      case 'otorrinolaringología':
      case 'otorrinolaringologia':
        return {
          'icon': const FaIcon(
            FontAwesomeIcons.earDeaf,
            color: Colors.blueGrey,
            size: 30,
          ),
          'color': Colors.blueGrey,
        };
      case 'psicología':
      case 'psicologia':
        return {
          'icon': const FaIcon(
            FontAwesomeIcons.brain,
            color: Colors.deepPurple,
            size: 30,
          ),
          'color': Colors.deepPurple,
        };
      case 'psiquiatría':
      case 'psiquiatria':
        return {
          'icon': const FaIcon(
            FontAwesomeIcons.userShield,
            color: Colors.blueGrey,
            size: 30,
          ),
          'color': Colors.blueGrey,
        };
      case 'urología':
      case 'urologia':
        return {
          'icon': const FaIcon(
            FontAwesomeIcons.mars,
            color: Colors.cyan,
            size: 30,
          ),
          'color': Colors.cyan,
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
          _buildComoFuncionaSection(
            screenWidth,
          ), // 👈 Módulo "¿Cómo funciona?" rediseñado estéticamente
          _buildCategoriasYCiudadesSection(
            screenWidth,
          ), // 👈 Matriz Premium en fondo azul con botón "Suscríbete"
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // =========================================================================
  // HERO SECTION PREMIUM CON BUSCADOR DE 2 BLOQUES (ESPECIALIDAD Y CIUDAD)
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
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) return las15EspecialidadesLaguna;
            return las15EspecialidadesLaguna.where(
              (String option) => option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ),
            );
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
                    maxHeight: 250,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF334155),
                          ),
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
            if (textEditingValue.text.isEmpty) return lasCiudades;
            return lasCiudades.where(
              (String option) => option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ),
            );
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
                    maxHeight: 250,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF334155),
                          ),
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

  Widget _buildBotonBuscar() {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListaDoctoresScreen(
              especialidad: _especialidadController.text.trim(),
              ciudad: _ciudadBuscadorController.text.trim(),
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
  // ESPECIALIDADES POPULARES (MAESTRA FIJA DE 15)
  // =========================================================================
  Widget _buildEspecialidadesSection(double width) {
    return SliverToBoxAdapter(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 10),
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const TodasEspecialidadesScreen(),
                        ),
                      );
                    },
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
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('usuarios')
                    .where('rol', isEqualTo: 'medico')
                    .where('activo', isEqualTo: true)
                    .get(),
                builder: (context, snapshot) {
                  Map<String, int> conteoReal = {};

                  if (snapshot.hasData && snapshot.data != null) {
                    for (var doc in snapshot.data!.docs) {
                      Map<String, dynamic> data =
                          doc.data() as Map<String, dynamic>;
                      String esp = (data['especialidad'] ?? '')
                          .toString()
                          .trim();

                      if (esp.toLowerCase() == 'dentista' ||
                          esp.toLowerCase() == 'odontología')
                        esp = 'Odontología (Dentista)';
                      if (esp.toLowerCase() == 'ginecología')
                        esp = 'Ginecología y Obstetricia';
                      if (esp.toLowerCase() == 'traumatología')
                        esp = 'Traumatología y Ortopedia';

                      if (esp.isNotEmpty)
                        conteoReal[esp] = (conteoReal[esp] ?? 0) + 1;
                    }
                  }

                  return SizedBox(
                    height: 140,
                    child: ListView.builder(
                      controller: _especialidadesScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: las15EspecialidadesLaguna.length,
                      itemBuilder: (context, index) {
                        String nombreEspecialidad =
                            las15EspecialidadesLaguna[index];
                        int cantidadMedicos =
                            conteoReal[nombreEspecialidad] ?? 0;
                        var estilo = _getEspecialidadEstilo(nombreEspecialidad);

                        return _itemEspecialidad(
                          nombreEspecialidad,
                          estilo['icon'] as Widget,
                          estilo['color'] as Color,
                          cantidadMedicos,
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

  // =========================================================================
  // MÉDICOS DESTACADOS Fijos Globales
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
  // CLÍNICAS RECOMENDADAS Y FARMACIAS CERCANAS
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
  // 📥 SECCIÓN: ¿CÓMO FUNCIONA? ADAPTADA A TU SISTEMA DE WHATSAPP DIRECTO
  // =========================================================================
  Widget _buildComoFuncionaSection(double width) {
    return SliverToBoxAdapter(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          margin: const EdgeInsets.only(top: 32, bottom: 12),
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
                '¿Cómo funciona?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  return constraints.maxWidth > 750
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // 💻 VERSIÓN PC: Cada uno lleva: Número, Icono, Color, Título y Descripción
                            _buildStepItem(
                              '1',
                              Icons.search_rounded,
                              Colors.blue,
                              'Busca',
                              'Encuentra al especialista o clínica que necesitas.',
                            ),
                            _buildStepItem(
                              '2',
                              Icons.badge_rounded,
                              Colors.teal,
                              'Elige',
                              'Explora perfiles validados con cédula y dirección.',
                            ),
                            _buildStepItem(
                              '3',
                              Icons.chat_rounded,
                              Colors.green,
                              'Agenda',
                              'Contacta directo al consultorio por WhatsApp.',
                            ),
                            _buildStepItem(
                              '4',
                              Icons.healing_rounded,
                              Colors.orange,
                              'Asiste',
                              'Acude a tu cita médica y cuida de tu salud.',
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            // 📱 VERSIÓN MÓVIL: Todos con sus 5 parámetros en orden exacto
                            _buildStepItemHorizontal(
                              '1',
                              Icons.search_rounded,
                              Colors.blue,
                              'Busca',
                              'Encuentra al especialista o clínica que necesitas.',
                            ),
                            const Divider(height: 24, color: Color(0xFFE2E8F0)),
                            _buildStepItemHorizontal(
                              '2',
                              Icons.badge_rounded,
                              Colors.teal,
                              'Elige',
                              'Explora perfiles validados con cédula y dirección.',
                            ), 
                            const Divider(height: 24, color: Color(0xFFE2E8F0)),
                            _buildStepItemHorizontal(
                              '3',
                              Icons.chat_rounded,
                              Colors.green,
                              'Agenda',
                              'Contacta directo al consultorio por WhatsApp.',
                            ),
                            const Divider(height: 24, color: Color(0xFFE2E8F0)),
                            _buildStepItemHorizontal(
                              '4',
                              Icons.healing_rounded,
                              Colors.orange,
                              'Asiste',
                              'Acude a tu cita médica y cuida de tu salud.',
                            ),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(
    String numero,
    IconData icon,
    Color colorMaestro,
    String titulo,
    String desc,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorMaestro.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorMaestro, size: 26),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$numero. ',
                style: TextStyle(
                  fontSize: 14,
                  color: colorMaestro,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItemHorizontal(
    String numero,
    IconData icon,
    Color colorMaestro,
    String titulo,
    String desc,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorMaestro.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colorMaestro, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$numero. $titulo',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
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

  // =========================================================================
  // 📥 SECCIÓN FINAL: MATRIZ DE CATEGORÍAS EN FONDO AZUL CORPORATIVO PREMIUM
  // =========================================================================
  Widget _buildCategoriasYCiudadesSection(double width) {
    bool esPC = width > 900;

    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        color: const Color(0xFF1E3A8A), // 👈 Fondo azul profundo corporativo
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Médicos por categoría y ciudad',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Texto en blanco brillante
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                esPC
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildColumnaCiudad(
                              'Médicos en Torreón',
                              'Torreón',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildColumnaCiudad(
                              'Médicos en Gómez Palacio',
                              'Gómez Palacio',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildColumnaCiudad(
                              'Médicos en Lerdo',
                              'Lerdo',
                            ),
                          ),
                          const SizedBox(width: 24),
                          _buildMiniBannerInscripcion(), // Tarjeta publicitaria homologada
                        ],
                      )
                    : Column(
                        children: [
                          _buildColumnaCiudad('Médicos en Torreón', 'Torreón'),
                          const SizedBox(height: 16),
                          _buildColumnaCiudad(
                            'Médicos en Gómez Palacio',
                            'Gómez Palacio',
                          ),
                          const SizedBox(height: 16),
                          _buildColumnaCiudad('Médicos en Lerdo', 'Lerdo'),
                          const SizedBox(height: 24),
                          _buildMiniBannerInscripcion(fullWidth: true),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColumnaCiudad(String tituloHeader, String nombreCiudad) {
    final List<String> top5Categorias = [
      'Cardiólogos',
      'Pediatras',
      'Ginecólogos',
      'Dentistas',
      'Dermatólogos',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(
          0.06,
        ), // Fondo translúcido sutil sobre el azul oscuro
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tituloHeader,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF38BDF8), // Azul celeste brillante muy legible
            ),
          ),
          const SizedBox(height: 14),
          ...top5Categorias.map((cat) {
            String specialtyFilter = cat;
            if (cat == 'Cardiólogos') specialtyFilter = 'Cardiología';
            if (cat == 'Pediatras') specialtyFilter = 'Pediatría';
            if (cat == 'Ginecólogos')
              specialtyFilter = 'Ginecología y Obstetricia';
            if (cat == 'Dentistas') specialtyFilter = 'Odontología (Dentista)';
            if (cat == 'Dermatólogos') specialtyFilter = 'Dermatología';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListaDoctoresScreen(
                          especialidad: specialtyFilter,
                          ciudad: nombreCiudad,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    '$cat en $nombreCiudad',
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(
                        0xFFE2E8F0,
                      ), // Gris claro ultra suave premium
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMiniBannerInscripcion({bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : 270,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(
          0xFF0284C7,
        ), // Azul vibrante para destacar la tarjeta
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Eres médico?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Suscríbete al directorio y llega a más pacientes en la región.', // 👈 Modificado por "Suscríbete"
            style: TextStyle(
              color: Color(0xFFE0F2FE),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SuscribirseScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0369A1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Suscríbete',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ), // 👈 Modificado por "Suscríbete"
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // BURBUJAS ROTATIVAS POPULARES
  // =========================================================================
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
}
