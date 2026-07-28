import 'package:flutter/material.dart';
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
  String _municipioFiltrado = "";

  // 📝 EL CATÁLOGO COMPLETO DE ESPECIALIDADES EN ORDEN ALFABÉTICO (A-Z) CON COLORES CORPORATIVOS
  static const List<Map<String, dynamic>> _especialidades = [
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
      'nombre': 'Oncolgía',
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
      body: SingleChildScrollView(
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
                const Text(
                  'Catálogo Completo de Especialidades',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explora todas las ramas médicas disponibles en la Comarca durango para encontrar a tu médico.',
                  style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 25),

                // =========================================================================
                // 🔍 BARRA DE FILTRADO DE MUNICIPIOS HOMOLOGADA
                // =========================================================================
                Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
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
                          'Filtrar por municipio (Ej. Torreón, Gómez Palacio, Lerdo...)',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                      ),
                      suffixIcon: _municipioFiltrado.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
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
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Colors.grey.shade200),
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

                // Grid de tarjetas de especialidades completas
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: width < 600 ? 1.05 : 1.2,
                  ),
                  itemCount: _especialidades.length,
                  itemBuilder: (context, index) {
                    final item = _especialidades[index];
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
              ciudad:
                  _municipioFiltrado, // 👈 Se inyecta de forma nativa la búsqueda de la barra
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
              color: Colors.black.withOpacity(0.01),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorEspecialidad.withOpacity(0.09),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: colorEspecialidad, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                nombre,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
