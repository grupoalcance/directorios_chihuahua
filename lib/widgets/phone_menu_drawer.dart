import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// 🔑 IMPORTACIÓN RELATIVA Y DINÁMICA DE CONFIGURACIÓN REGIONAL
import '../config/app_config.dart';

import '../services/auth_service.dart';

class PhoneMenuDrawer extends StatefulWidget {
  const PhoneMenuDrawer({Key? key}) : super(key: key);

  @override
  State<PhoneMenuDrawer> createState() => _PhoneMenuDrawerState();
}

class _PhoneMenuDrawerState extends State<PhoneMenuDrawer> {
  // 📝 ESTRUCTURA DE CATEGORÍAS PADRE Y SUS SUBESPECIALIDADES BASE
  final Map<String, List<String>> _categoriasPadreEspecialidades = {
    'Odontología / Salud Dental': [
      'Odontología (Dentista)',
      'Ortodoncia',
      'Periodoncia (Implantes Dentales)',
      'Odontopediatría',
      'Endodoncia',
    ],
    'Salud de la Mujer': ['Ginecología y Obstetricia', 'Uroginecología'],
    'Pediatría': ['Pediatría'],
    'Cirugías': [
      'Cirugía General',
      'Cirugía Plástica y Reconstructiva',
      'Angiología / Cirugía Vascular',
    ],
    'Neuro y Salud Mental': ['Neurología', 'Psicología', 'Psiquiatría'],
    'Otras Especialidades Médicas': [
      'Cardiología',
      'Dermatología',
      'Medicina General',
      'Neumología',
      'Nutrición',
      'Oftalmología',
      'Traumatología y Ortopedia',
      'Urología',
    ],
  };

  Map<String, List<String>> _mapaEspecialidadesDinamicas = {};

  @override
  void initState() {
    super.initState();
    _mapaEspecialidadesDinamicas = Map.from(_categoriasPadreEspecialidades);
    _cargarEspecialidadesDinamicas();
  }

  // 🔑 CARGA Y CLASIFICACIÓN DENTRO DE CATEGORÍAS PADRE DESDE FIRESTORE
  Future<void> _cargarEspecialidadesDinamicas() async {
    try {
      var query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('rol', isEqualTo: 'medico')
          .where('activo', isEqualTo: true)
          .get();

      Map<String, Set<String>> mapaSet = {};
      _categoriasPadreEspecialidades.forEach((cat, lista) {
        mapaSet[cat] = Set.from(lista);
      });

      for (var doc in query.docs) {
        String esp = (doc.data()['especialidad'] ?? '').toString().trim();
        if (esp.isNotEmpty) {
          String espLower = esp.toLowerCase();

          // Normalización inteligente
          if (espLower == 'dentista' ||
              espLower == 'odontología' ||
              espLower == 'odontologia') {
            esp = 'Odontología (Dentista)';
          } else if (espLower.contains('periodoncia')) {
            esp = 'Periodoncia (Implantes Dentales)';
          } else if (espLower == 'ginecología' || espLower == 'ginecologia') {
            esp = 'Ginecología y Obstetricia';
          } else if (espLower.contains('traumatología') ||
              espLower.contains('traumatologia')) {
            esp = 'Traumatología y Ortopedia';
          } else if (espLower.contains('uroginecología') ||
              espLower.contains('uroginecologia')) {
            esp = 'Uroginecología';
          }

          // Clasificación automática dentro de Categorías Padre
          if (espLower.contains('odontolog') ||
              espLower.contains('dentista') ||
              espLower.contains('periodoncia') ||
              espLower.contains('ortodoncia') ||
              espLower.contains('endodoncia')) {
            mapaSet['Odontología / Salud Dental']?.add(esp);
          } else if (espLower.contains('ginecolog') ||
              espLower.contains('obstetricia') ||
              espLower.contains('uroginecolog')) {
            mapaSet['Salud de la Mujer']?.add(esp);
          } else if (espLower.contains('pediatra') ||
              espLower.contains('pediatría') ||
              espLower.contains('pediatria')) {
            mapaSet['Pediatría']?.add(esp);
          } else if (espLower.contains('cirug')) {
            mapaSet['Cirugías']?.add(esp);
          } else if (espLower.contains('neuro') ||
              espLower.contains('psico') ||
              espLower.contains('psiquia')) {
            mapaSet['Neuro y Salud Mental']?.add(esp);
          } else {
            mapaSet['Otras Especialidades Médicas']?.add(esp);
          }
        }
      }

      if (mounted) {
        Map<String, List<String>> mapaFinal = {};
        mapaSet.forEach((cat, setEsp) {
          List<String> listaOrdenada = setEsp.toList()..sort();
          mapaFinal[cat] = listaOrdenada;
        });

        setState(() {
          _mapaEspecialidadesDinamicas = mapaFinal;
        });
      }
    } catch (e) {
      debugPrint('Error cargando especialidades en PhoneMenuDrawer: $e');
    }
  }

  // AUXILIAR SEGURO PARA LEER EL ROL EN MÓVIL
  Future<String> _obtenerRolUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'paciente';
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['rol'] ?? 'paciente').toString().trim().toLowerCase();
      }
    } catch (e) {
      debugPrint("Error al obtener rol en drawer: $e");
    }
    return 'paciente';
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Encabezado del menú lateral
          DrawerHeader(
            decoration: BoxDecoration(color: AppConfig.primaryColor),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                AppConfig.appName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 0. Inicio / Home
          ListTile(
            leading: Icon(Icons.home_outlined, color: AppConfig.primaryColor),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),

          // 1. ¿Quiénes somos? (URL Limpia)
          ListTile(
            leading: Icon(Icons.info_outline, color: AppConfig.primaryColor),
            title: const Text('¿Quiénes somos?'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/quienes-somos');
            },
          ),

          // 2. Desplegable Ciudad
          ExpansionTile(
            leading: Icon(Icons.location_city, color: AppConfig.primaryColor),
            title: const Text('Ciudad'),
            children: AppConfig.ciudadesActivas.map((ciudad) {
              return _buildSubItemCiudad(context, ciudad);
            }).toList(),
          ),

          // 3. Desplegable Especialidad Jerárquico por Categorías Padre
          ExpansionTile(
            leading: Icon(
              Icons.medical_services_outlined,
              color: AppConfig.primaryColor,
            ),
            title: const Text('Especialidad'),
            children: [
              ..._mapaEspecialidadesDinamicas.entries.map((entry) {
                String categoriaPadre = entry.key;
                List<String> subEspecialidades = entry.value;

                return ExpansionTile(
                  title: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Text(
                      categoriaPadre,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  children: subEspecialidades.map((subEsp) {
                    return _buildSubItemEspecialidad(context, subEsp);
                  }).toList(),
                );
              }).toList(),

              ListTile(
                title: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'Ver todas las especialidades ',
                        style: TextStyle(
                          color: AppConfig.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: AppConfig.primaryColor,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/especialidades');
                },
              ),
            ],
          ),

          // 4. Hospitales (URL Limpia)
          ListTile(
            leading: Icon(Icons.local_hospital, color: AppConfig.primaryColor),
            title: const Text('Hospitales'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/hospitales');
            },
          ),

          // 5. Farmacias (URL Limpia)
          ListTile(
            leading: Icon(Icons.local_pharmacy, color: AppConfig.primaryColor),
            title: const Text('Farmacias'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/farmacias');
            },
          ),

          // 6. Enfermería (URL Limpia)
          ListTile(
            leading: Icon(Icons.people_outline, color: AppConfig.primaryColor),
            title: const Text('Enfermería'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/doctores?especialidad=${Uri.encodeComponent('Enfermería General')}',
              );
            },
          ),

          // 7. Urgencias 24/hrs (URL Limpia)
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            title: const Text(
              'Urgencias 24/hrs',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/doctores?especialidad=${Uri.encodeComponent('Urgencias Médicas 24/7')}',
              );
            },
          ),

          // 8. Contacto (URL Limpia)
          ListTile(
            leading: Icon(Icons.email_outlined, color: AppConfig.primaryColor),
            title: const Text('Contacto'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/contacto');
            },
          ),

          const Divider(),

          // CONTROL DE ACCESO DINÁMICO
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return FutureBuilder<String>(
                  future: _obtenerRolUsuario(),
                  builder: (context, rolSnapshot) {
                    String rol = rolSnapshot.data ?? 'paciente';
                    bool esAsesor =
                        (rol == 'vendedor' ||
                        rol == 'admin' ||
                        rol == 'administrador');

                    String textoPanel = 'Mi Panel / Perfil';
                    String rutaDestino = '/paciente_dashboard';

                    if (rol == 'admin' || rol == 'administrador') {
                      textoPanel = 'Panel Administrador';
                      rutaDestino = '/admin_dashboard';
                    } else if (rol == 'vendedor') {
                      textoPanel = 'Abrir Panel de Ventas';
                      rutaDestino = 'php';
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.dashboard_rounded,
                            color: AppConfig.primaryColor,
                          ),
                          title: Text(
                            textoPanel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            if (rutaDestino == 'php') {
                              final Uri url = Uri.parse(AppConfig.crmUrl);
                              launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              Navigator.pushNamed(context, rutaDestino);
                            }
                          },
                        ),
                        if (esAsesor) ...[
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(
                              Icons.assignment_turned_in_outlined,
                              color: Colors.green,
                            ),
                            title: const Text(
                              'Sistema de Asesores',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              final Uri url = Uri.parse(AppConfig.crmUrl);
                              launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            },
                          ),
                        ],
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.logout_rounded,
                            color: Colors.red,
                          ),
                          title: Text(
                            (rol == 'admin' || rol == 'administrador')
                                ? 'Cerrar Sesión (Admin)'
                                : rol == 'vendedor'
                                ? 'Cerrar Sesión (Asesor)'
                                : 'Cerrar Sesión (Paciente)',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            await AuthService().cerrarSesion();
                            if (context.mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/',
                                (route) => false,
                              );
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              }

              // VISITANTE ANÓNIMO
              return ListTile(
                leading: const Icon(
                  Icons.lock_open_rounded,
                  color: Color(0xFF475569),
                ),
                title: const Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/ingresar');
                },
              );
            },
          ),

          // 9. Botón Destacado Fijo: Suscribirse (URL Limpia)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/suscribirse');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Suscribirse al directorio',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubItemCiudad(BuildContext context, String nombreCiudad) {
    return ListTile(
      title: Padding(
        padding: const EdgeInsets.only(left: 24.0),
        child: Text(
          nombreCiudad,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155)),
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(
          context,
          '/doctores?ciudad=${Uri.encodeComponent(nombreCiudad)}',
        );
      },
    );
  }

  Widget _buildSubItemEspecialidad(
    BuildContext context,
    String nombreEspecialidad,
  ) {
    return ListTile(
      title: Padding(
        padding: const EdgeInsets.only(left: 28.0),
        child: Text(
          nombreEspecialidad,
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(
          context,
          '/doctores?especialidad=${Uri.encodeComponent(nombreEspecialidad)}',
        );
      },
    );
  }
}
