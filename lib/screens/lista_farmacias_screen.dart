import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'farmacia_profile_screen.dart';
import 'suscribirse_screen.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/phone_menu_drawer.dart';
import '../widgets/seccion_enlaces_cruzados.dart';
import 'package:web_smooth_scroll/web_smooth_scroll.dart';

class ListaFarmaciasScreen extends StatefulWidget {
  const ListaFarmaciasScreen({super.key});

  @override
  State<ListaFarmaciasScreen> createState() => _ListaFarmaciasScreenState();
}

class _ListaFarmaciasScreenState extends State<ListaFarmaciasScreen> {
  String _busquedaCiudad = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isMobile = width < 750;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(),
      drawer: width < 1100 ? const PhoneMenuDrawer() : null,
      body: WebSmoothScroll(
        controller: _scrollController,
        scrollSpeed: 130,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- ENCABEZADO ---
                      Text(
                        'Farmacias en Durango',
                        style: TextStyle(
                          fontSize: isMobile ? 24 : 32,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Encuentra farmacias de confianza, sucursales 24 horas y localización de medicamentos.',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // --- BUSCADOR ESTILIZADO ---
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.03),
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
                            fontSize: 14.5,
                            color: Color(0xFF1E293B),
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Filtrar por municipio (Ej. Durango, Gómez Palacio, Lerdo...)',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFF0061E0),
                              size: 20,
                            ),
                            suffixIcon: _busquedaCiudad.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _busquedaCiudad = "";
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
                      const SizedBox(height: 32),

                      // --- FLUJO DE DATOS DESDE FIRESTORE ---
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('farmacias')
                            .where('activo', isEqualTo: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(50),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              ),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return _buildEmptyState(
                              'No hay farmacias registradas de forma activa actualmente.',
                            );
                          }

                          final farmacias = snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final ciudad = (data['ciudad'] ?? '')
                                .toString()
                                .toLowerCase();
                            final nombre = (data['nombre'] ?? '')
                                .toString()
                                .toLowerCase();
                            return ciudad.contains(_busquedaCiudad) ||
                                nombre.contains(_busquedaCiudad);
                          }).toList();

                          if (farmacias.isEmpty) {
                            return _buildEmptyState(
                              'No se encontraron farmacias asociadas a "$_busquedaCiudad".',
                            );
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: farmacias.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: width > 1100
                                      ? 3
                                      : (width > 700 ? 2 : 1),
                                  mainAxisExtent: 310,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                ),
                            itemBuilder: (context, index) {
                              var data =
                                  farmacias[index].data()
                                      as Map<String, dynamic>;
                              String? fotoUrl = data['foto_url'];
                              String nombre = data['nombre'] ?? 'Farmacia';
                              String ciudadDoc = data['ciudad'] ?? 'Durango';
                              String score = data['score'] ?? '5.0';

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF0F172A,
                                      ).withOpacity(0.03),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FarmaciaProfileScreen(
                                            farmaciaData: data,
                                          ),
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // --- IMAGEN SUPERIOR ---
                                      Container(
                                        height: 140,
                                        width: double.infinity,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(16),
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
                                                        alignment:
                                                            Alignment.center,
                                                      )
                                                    : Image.network(
                                                        fotoUrl,
                                                        fit: BoxFit.cover,
                                                        alignment:
                                                            Alignment.center,
                                                      ))
                                              : const Center(
                                                  child: Icon(
                                                    Icons.storefront_rounded,
                                                    size: 48,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
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
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Color(
                                                          0xFF0F172A,
                                                        ),
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
                                                          size: 14,
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
                                                                fontSize: 11,
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
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      'Sucursales en $ciudadDoc',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF64748B,
                                                        ),
                                                        fontSize: 12,
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
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF1F5F9,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Center(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Ver sucursales y horarios',
                                                        style: TextStyle(
                                                          color: Color(
                                                            0xFF1E293B,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12.5,
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
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // --- SECCIÓN DE ENLACES CRUZADOS MÓDULO DE FARMACIAS ---
              SeccionEnlacesCruzados(
                tituloSeccion: "Farmacias por categoría y ciudad",
                columnasCiudades: const ['Durango', 'Gómez Palacio', 'Lerdo'],
                enlacesPorCiudad: const {
                  'Durango': [
                    'Farmacias 24 Horas en Durango',
                    'Farmacias con Consultorio en Durango',
                    'Medicamentos de Especialidad en Durango',
                    'Farmacias Dermatológicas en Durango',
                    'Servicio a Domicilio en Durango',
                  ],
                  'Gómez Palacio': [
                    'Farmacias 24 Horas en Gómez Palacio',
                    'Farmacias con Consultorio en Gómez Palacio',
                    'Medicamentos de Especialidad en Gómez Palacio',
                    'Farmacias de Genéricos en Gómez Palacio',
                    'Servicio a Domicilio en Gómez Palacio',
                  ],
                  'Lerdo': [
                    'Farmacias 24 Horas en Lerdo',
                    'Farmacias con Consultorio en Lerdo',
                    'Medicamentos de Especialidad en Lerdo',
                    'Farmacias Locales en Lerdo',
                    'Servicio a Domicilio en Lerdo',
                  ],
                },
                ctaTitulo: "¿Surtas recetas?",
                ctaSubtitulo:
                    "Une tu farmacia al directorio y ayuda a miles de familias a localizar sus medicamentos rápido.",
                ctaBotonTexto: "Registrar Farmacia",
                onCtaPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SuscribirseScreen(),
                  ),
                ),
                onEnlacePressed: (ciudad, enlace) {
                  _searchController.text = ciudad;
                  setState(() {
                    _busquedaCiudad = ciudad.toLowerCase();
                  });
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
