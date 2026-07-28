import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'hospital_profile_screen.dart';
import 'suscribirse_screen.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/phone_menu_drawer.dart';
import '../widgets/seccion_enlaces_cruzados.dart'; // 👈 IMPORTADO: Tu componente máster

class ListaHospitalesScreen extends StatefulWidget {
  const ListaHospitalesScreen({super.key});

  @override
  State<ListaHospitalesScreen> createState() => _ListaHospitalesScreenState();
}

class _ListaHospitalesScreenState extends State<ListaHospitalesScreen> {
  String _busquedaCiudad = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // 👈 Controlador para auto-scroll

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fondo Slate 50 premium
      appBar: const CustomAppBar(),
      drawer: width < 1100 ? const PhoneMenuDrawer() : null,
      body: SingleChildScrollView(
        controller:
            _scrollController, // Asignado para poder subir la pantalla al hacer clic
        child: Column(
          children: [
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================================================================
                    // 🏢 ENCABEZADO PREMIUM
                    // =========================================================================
                    const Text(
                      'Hospitales y Clínicas en la durango',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Encuentra centros médicos de alta especialidad y atención de urgencias las 24 horas.',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 35),

                    // =========================================================================
                    // 🔍 BUSCADOR ESTILIZADO CON CONTRASTE
                    // =========================================================================
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _busquedaCiudad = value.trim().toLowerCase();
                          });
                        },
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                        decoration: const InputDecoration(
                          hintText:
                              'Filtrar por municipio (Ej. Durango, Gómez Palacio, Lerdo...)',
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14.5,
                          ),
                          prefixIcon: Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF0061E0),
                            size: 22,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // =========================================================================
                    // 📡 FLUJO DE DATOS DESDE FIREBASE
                    // =========================================================================
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('hospitales')
                          .where('activo', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(50),
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return _buildEmptyState(
                            'No hay clínicas u hospitales registrados de forma activa.',
                          );
                        }

                        // Filtrado local reactivo por ciudad o municipio escrito
                        final hospitales = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final ciudad = (data['ciudad'] ?? '')
                              .toString()
                              .toLowerCase();
                          final direccion = (data['direccion'] ?? '')
                              .toString()
                              .toLowerCase();
                          return ciudad.contains(_busquedaCiudad) ||
                              direccion.contains(_busquedaCiudad);
                        }).toList();

                        if (hospitales.isEmpty) {
                          return _buildEmptyState(
                            'No se encontraron hospitales en "$_busquedaCiudad". Prueba con otra ciudad.',
                          );
                        }

                        // =========================================================================
                        // 📐 GRID ADAPTATIVO CON CONTROL DE MAX-WIDTH
                        // =========================================================================
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: hospitales.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: width > 1100
                                    ? 3
                                    : (width > 700 ? 2 : 1),
                                mainAxisExtent: 380,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                              ),
                          itemBuilder: (context, index) {
                            var data =
                                hospitales[index].data()
                                    as Map<String, dynamic>;
                            String? fotoUrl = data['foto_url'];
                            String nombre = data['nombre'] ?? 'Hospital';
                            String direccion =
                                data['direccion'] ?? 'Dirección no disponible';
                            String ciudadDoc =
                                data['ciudad'] ?? 'Comarca Lagunera';
                            String score = data['score'] ?? '5.0';

                            return Center(
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 370,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF0F172A,
                                      ).withOpacity(0.04),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          HospitalProfileScreen(
                                            hospitalData: data,
                                          ),
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            height: 170,
                                            width: double.infinity,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(20),
                                                  ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(20),
                                                  ),
                                              child:
                                                  (fotoUrl != null &&
                                                      fotoUrl.isNotEmpty)
                                                  ? (fotoUrl.startsWith(
                                                          'data:image',
                                                        )
                                                        ? Image.memory(
                                                            base64Decode(
                                                              fotoUrl
                                                                  .split(',')
                                                                  .last,
                                                            ),
                                                            fit: BoxFit.cover,
                                                          )
                                                        : Image.network(
                                                            fotoUrl,
                                                            fit: BoxFit.cover,
                                                          ))
                                                  : const Icon(
                                                      Icons
                                                          .local_hospital_rounded,
                                                      size: 55,
                                                      color: Color(0xFF94A3B8),
                                                    ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 14,
                                            left: 14,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .access_time_filled_rounded,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'URGENCIAS 24/7',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 10,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      nombre,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 17,
                                                        color: Color(
                                                          0xFF0F172A,
                                                        ),
                                                        letterSpacing: -0.3,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFFEF3C7,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.star_rounded,
                                                          color: Colors.amber,
                                                          size: 15,
                                                        ),
                                                        const SizedBox(
                                                          width: 2,
                                                        ),
                                                        Text(
                                                          score,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 11.5,
                                                                color: Color(
                                                                  0xFF92400E,
                                                                ),
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on_outlined,
                                                    color: Color(0xFF64748B),
                                                    size: 15,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      '$direccion, $ciudadDoc',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF64748B,
                                                        ),
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Spacer(),
                                              Container(
                                                width: double.infinity,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF1F5F9,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Center(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Ver Hospital',
                                                        style: TextStyle(
                                                          color: Color(
                                                            0xFF1E293B,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      SizedBox(width: 6),
                                                      Icon(
                                                        Icons
                                                            .arrow_forward_rounded,
                                                        color: Color(
                                                          0xFF1E293B,
                                                        ),
                                                        size: 14,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // =========================================================================
            // 📊 SECCIÓN EXCLUSIVA DE ENLACES CRUZADOS MÓDULO DE HOSPITALES
            // =========================================================================
            SeccionEnlacesCruzados(
              tituloSeccion: "Hospitales y Clínicas por categoría y ciudad",
              columnasCiudades: const ['Durango', 'Gómez Palacio', 'Lerdo'],
              enlacesPorCiudad: const {
                'Durango': [
                  'Hospitales con Urgencias en Durango',
                  'Clínicas de Especialidades en Durango',
                  'Maternidad en Durango',
                  'Centros Médicos Quirúrgicos en Durango',
                  'Sanatorios Privados en Durango',
                ],
                'Gómez Palacio': [
                  'Hospitales con Urgencias en Gómez Palacio',
                  'Clínicas de Especialidades en Gómez Palacio',
                  'Maternidad en Gómez Palacio',
                  'Centros Médicos Quirúrgicos en Gómez Palacio',
                  'Sanatorios Privados en Gómez Palacio',
                ],
                'Lerdo': [
                  'Hospitales con Urgencias en Lerdo',
                  'Clínicas de Especialidades en Lerdo',
                  'Maternidad en Lerdo',
                  'Centros Médicos en Lerdo',
                  'Clínicas de Medicina General en Lerdo',
                ],
              },
              ctaTitulo: "¿Tienes una clínica?",
              ctaSubtitulo:
                  "Registra tu centro médico u hospital para aparecer en las búsquedas de urgencia de la región.",
              ctaBotonTexto: "Registrar Clínica",
              onCtaPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SuscribirseScreen(),
                ),
              ),
              onEnlacePressed: (ciudad, enlace) {
                // Setea el buscador de arriba con el nombre de la ciudad seleccionada
                _searchController.text = ciudad;
                setState(() {
                  _busquedaCiudad = ciudad.toLowerCase();
                });
                // Desplazamiento animado premium hacia la parte superior para mostrar resultados
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
