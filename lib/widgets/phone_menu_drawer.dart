import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// 🔑 IMPORTACIÓN DEL ARCHIVO MAESTRO
import 'package:directorios_laguna/config/app_config.dart';

import '../screens/lista_doctores_screen.dart';
import '../screens/todas_especialidades_screen.dart';
import '../screens/lista_hospitales_screen.dart';
import '../screens/lista_farmacias_screen.dart';
import '../services/auth_service.dart';

class PhoneMenuDrawer extends StatelessWidget {
  const PhoneMenuDrawer({Key? key}) : super(key: key);

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
            decoration: BoxDecoration(
              color: AppConfig.primaryColor,
            ), // 🔑 COLOR DINÁMICO
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                AppConfig.appName, // 🔑 NOMBRE DE LA APP DINÁMICO
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 1. ¿Quiénes somos?
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
            // 🔑 LISTA DINÁMICA DE CIUDADES
            children: AppConfig.ciudadesActivas.map((ciudad) {
              return _buildSubItemCiudad(context, ciudad);
            }).toList(),
          ),

          // 3. Desplegable Especialidad (Top 10 Alfabético)
          ExpansionTile(
            leading: Icon(
              Icons.medical_services_outlined,
              color: AppConfig.primaryColor,
            ),
            title: const Text('Especialidad'),
            children: [
              _buildSubItemEspecialidad(context, 'Cardiología'),
              _buildSubItemEspecialidad(context, 'Dermatología'),
              _buildSubItemEspecialidad(context, 'Ginecología y Obstetricia'),
              _buildSubItemEspecialidad(context, 'Medicina General'),
              _buildSubItemEspecialidad(context, 'Neumología'),
              _buildSubItemEspecialidad(context, 'Neurología'),
              _buildSubItemEspecialidad(context, 'Nutrición'),
              _buildSubItemEspecialidad(context, 'Odontología (Dentista)'),
              _buildSubItemEspecialidad(context, 'Oftalmología'),
              _buildSubItemEspecialidad(context, 'Pediatría'),

              ListTile(
                title: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'Ver todas las especialidades ',
                        style: TextStyle(
                          color: AppConfig.primaryColor, // 🔑 COLOR DINÁMICO
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TodasEspecialidadesScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // 4. Hospitales
          ListTile(
            leading: Icon(Icons.local_hospital, color: AppConfig.primaryColor),
            title: const Text('Hospitales'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListaHospitalesScreen(),
                ),
              );
            },
          ),

          // 5. Farmacias
          ListTile(
            leading: Icon(Icons.local_pharmacy, color: AppConfig.primaryColor),
            title: const Text('Farmacias'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListaFarmaciasScreen(),
                ),
              );
            },
          ),

          // 6. Enfermería
          ListTile(
            leading: Icon(Icons.people_outline, color: AppConfig.primaryColor),
            title: const Text('Enfermería'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListaDoctoresScreen(
                    especialidad: 'Enfermería General',
                    ciudad: '',
                  ),
                ),
              );
            },
          ),

          // 7. Urgencias 24/hrs
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            title: const Text(
              'Urgencias 24/hrs',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListaDoctoresScreen(
                    especialidad: 'Urgencias Médicas 24/7',
                    ciudad: '',
                  ),
                ),
              );
            },
          ),

          // 8. Contacto
          ListTile(
            leading: Icon(Icons.email_outlined, color: AppConfig.primaryColor),
            title: const Text('Contacto'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/contacto');
            },
          ),

          const Divider(),

          // =========================================================================
          //  CONTROL DE ACCESO DINÁMICO HOMOLOGADO PARA DISPOSITIVOS MÓVILES
          // =========================================================================
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
                              // 🔑 ENLACE DINÁMICO DEL CRM
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
                              // 🔑 ENLACE DINÁMICO DEL CRM
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

          // 9. Botón Destacado Fijo: Suscribirse (Ruta Nombrada)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/suscribirse');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor, // 🔑 COLOR DINÁMICO
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
        padding: const EdgeInsets.only(left: 16.0),
        child: Text(
          nombreCiudad,
          style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ListaDoctoresScreen(especialidad: '', ciudad: nombreCiudad),
          ),
        );
      },
    );
  }

  Widget _buildSubItemEspecialidad(
    BuildContext context,
    String nombreEspecialidad,
  ) {
    return TypographyItem(context, nombreEspecialidad);
  }

  Widget TypographyItem(BuildContext context, String nombreEspecialidad) {
    return ListTile(
      title: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Text(
          nombreEspecialidad,
          style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListaDoctoresScreen(
              especialidad: nombreEspecialidad,
              ciudad: '',
            ),
          ),
        );
      },
    );
  }
}
