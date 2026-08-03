import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:web_smooth_scroll/web_smooth_scroll.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/phone_menu_drawer.dart';
import '../screens/lista_doctores_screen.dart';

class TodasEspecialidadesScreen extends StatefulWidget {
  const TodasEspecialidadesScreen({Key? key}) : super(key: key);

  @override
  State<TodasEspecialidadesScreen> createState() =>
      _TodasEspecialidadesScreenState();
}

class _TodasEspecialidadesScreenState extends State<TodasEspecialidadesScreen> {
  final TextEditingController _searchMunicipioController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _municipioFiltrado = "";

  // 📝 CATÁLOGO BASE DE ESPECIALIDADES CON SUS ESTILOS
  final List<Map<String, dynamic>> _especialidadesBase = [
    {
      'nombre': 'Alergología',
      'icono': Icons.biotech_rounded,
      'color': Colors.amber,
    },
    {
      'nombre': 'Anestesiología',
      'icono': Icons.airline_seat_flat_angled_rounded,
      'color': Colors.blueGrey,
    },
    {
      'nombre': 'Angiología / Cirugía Vascular',
      'icono': Icons.navigation_rounded,
      'color': Colors.indigo,
    },
    {
      'nombre': 'Cardiología',
      'icono': Icons.favorite_rounded,
      'color': Colors.red,
    },
    {
      'nombre': 'Cirugía General',
      'icono': Icons.architecture_rounded,
      'color': Colors.deepOrange,
    },
    {
      'nombre': 'Cirugía Plástica y Reconstructiva',
      'icono': Icons.face_rounded,
      'color': Colors.pinkAccent,
    },
    {
      'nombre': 'Dermatología',
      'icono': Icons.clean_hands_rounded,
      'color': Colors.pink,
    },
    {
      'nombre': 'Endocrinología',
      'icono': Icons.opacity_rounded,
      'color': Colors.purple,
    },
    {
      'nombre': 'Gastroenterología',
      'icono': Icons.restaurant_rounded,
      'color': Colors.brown,
    },
    {
      'nombre': 'Geriatría',
      'icono': Icons.elderly_rounded,
      'color': Colors.blueGrey,
    },
    {
      'nombre': 'Ginecología y Obstetricia',
      'icono': Icons.pregnant_woman_rounded,
      'color': Colors.pink,
    },
    {
      'nombre': 'Hematología',
      'icono': Icons.bloodtype_rounded,
      'color': Colors.redAccent,
    },
    {
      'nombre': 'Medicina General',
      'icono': Icons.medical_services_rounded,
      'color': Colors.teal,
    },
    {
      'nombre': 'Medicina Interna',
      'icono': Icons.assignment_ind_rounded,
      'color': Colors.blue,
    },
    {
      'nombre': 'Neumología',
      'icono': Icons.air_rounded,
      'color': Colors.lightBlue,
    },
    {
      'nombre': 'Neurología',
      'icono': Icons.psychology_rounded,
      'color': Colors.deepPurple,
    },
    {
      'nombre': 'Nutrición',
      'icono': Icons.apple_rounded,
      'color': Colors.green,
    },
    {
      'nombre': 'Odontología (Dentista)',
      'icono': Icons.badge_rounded,
      'color': Colors.cyan,
    },
    {
      'nombre': 'Oftalmología',
      'icono': Icons.visibility_rounded,
      'color': Colors.tealAccent,
    },
    {
      'nombre': 'Oncología',
      'icono': Icons.health_and_safety_rounded,
      'color': Colors.orange,
    },
    {
      'nombre': 'Otorrinolaringología',
      'icono': Icons.hearing_rounded,
      'color': Colors.blueAccent,
    },
    {
      'nombre': 'Pediatría',
      'icono': Icons.child_care_rounded,
      'color': Colors.orangeAccent,
    },
    {
      'nombre': 'Periodoncia (Implantes Dentales)',
      'icono': Icons.health_and_safety_rounded,
      'color': const Color(0xFF0D9488),
    },
    {
      'nombre': 'Proctología',
      'icono': Icons.airline_seat_recline_extra_rounded,
      'color': Colors.grey,
    },
    {
      'nombre': 'Psicología',
      'icono': Icons.forum_rounded,
      'color': Colors.greenAccent,
    },
    {
      'nombre': 'Psiquiatría',
      'icono': Icons.healing_rounded,
      'color': Colors.purpleAccent,
    },
    {
      'nombre': 'Reumatología',
      'icono': Icons.accessibility_new_rounded,
      'color': Colors.blueGrey,
    },
    {
      'nombre': 'Traumatología y Ortopedia',
      'icono': Icons.accessible_forward_rounded,
      'color': Colors.indigoAccent,
    },
    {
      'nombre': 'Uroginecología',
      'icono': Icons.wc_rounded,
      'color': Colors.purpleAccent,
    },
    {
      'nombre': 'Urología',
      'icono': Icons.water_drop_rounded,
      'color': Colors.blue,
    },
  ];

  @override
  void dispose() {
    _searchMunicipioController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    int crossAxisCount = 4;
    if (width < 600) {
      crossAxisCount = 2;
    } else if (width < 1000) {
      crossAxisCount = 3;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(),
      drawer: width < 1100 ? const PhoneMenuDrawer() : null,
      body: WebSmoothScroll(
        controller: _scrollController,
        scrollSpeed: 130,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .where('rol', isEqualTo: 'medico')
              .where('activo', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            List<Map<String, dynamic>> listaDinamica = List.from(
              _especialidadesBase,
            );
            Set<String> nombresExistentes = _especialidadesBase
                .map((e) => (e['nombre'] as String).toLowerCase().trim())
                .toSet();

            if (snapshot.hasData && snapshot.data != null) {
              for (var doc in snapshot.data!.docs) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                String esp = (data['especialidad'] ?? '').toString().trim();

                if (esp.isNotEmpty) {
                  String espLower = esp.toLowerCase();

                  // Normalizaciones de nombres para coincidir con la lista maestro
                  if (espLower == 'dentista' ||
                      espLower == 'odontología' ||
                      espLower == 'odontologia') {
                    esp = 'Odontología (Dentista)';
                  } else if (espLower.contains('periodoncia')) {
                    esp = 'Periodoncia (Implantes Dentales)';
                  } else if (espLower == 'ginecología' ||
                      espLower == 'ginecologia') {
                    esp = 'Ginecología y Obstetricia';
                  } else if (espLower.contains('traumatología') ||
                      espLower.contains('traumatologia')) {
                    esp = 'Traumatología y Ortopedia';
                  } else if (espLower.contains('uroginecología') ||
                      espLower.contains('uroginecologia')) {
                    esp = 'Uroginecología';
                  }

                  if (!nombresExistentes.contains(esp.toLowerCase())) {
                    nombresExistentes.add(esp.toLowerCase());

                    // Asignación de íconos personalizados para especialidades emergentes
                    IconData iconoDinamico = Icons.medical_services_rounded;
                    Color colorDinamico = Colors.blueGrey;

                    if (espLower.contains('periodoncia')) {
                      iconoDinamico = Icons.health_and_safety_rounded;
                      colorDinamico = const Color(0xFF0D9488);
                    }

                    listaDinamica.add({
                      'nombre': esp,
                      'icono': iconoDinamico,
                      'color': colorDinamico,
                    });
                  }
                }
              }
            }

            listaDinamica.sort(
              (a, b) =>
                  (a['nombre'] as String).compareTo(b['nombre'] as String),
            );

            return SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  padding: EdgeInsets.symmetric(
                    horizontal: width < 600 ? 16.0 : 24.0,
                    vertical: 32.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catálogo Completo de Especialidades',
                        style: TextStyle(
                          fontSize: width < 600 ? 22 : 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Explora todas las ramas médicas disponibles en la región para encontrar a tu médico.',
                        style: TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Barra de filtrado de municipios
                      Container(
                        margin: const EdgeInsets.only(bottom: 28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchMunicipioController,
                          onChanged: (value) {
                            setState(() {
                              _municipioFiltrado = value.trim();
                            });
                          },
                          decoration: InputDecoration(
                            hintText:
                                'Filtrar por municipio (Ej. Durango, Gómez Palacio...)',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.location_on_outlined,
                              color: Colors.blue,
                              size: 20,
                            ),
                            suffixIcon: _municipioFiltrado.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      _searchMunicipioController.clear();
                                      setState(() {
                                        _municipioFiltrado = "";
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Grid adaptativo de tarjetas de especialidades
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: width < 600 ? 1.15 : 1.3,
                        ),
                        itemCount: listaDinamica.length,
                        itemBuilder: (context, index) {
                          final item = listaDinamica[index];
                          return _buildEspecialidadCard(
                            context,
                            item['nombre'] as String,
                            item['icono'] as IconData,
                            item['color'] as Color,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEspecialidadCard(
    BuildContext context,
    String nombre,
    IconData icono,
    Color colorEspecialidad,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListaDoctoresScreen(
              especialidad: nombre,
              ciudad: _municipioFiltrado,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorEspecialidad.withOpacity(0.09),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: colorEspecialidad, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                nombre,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
