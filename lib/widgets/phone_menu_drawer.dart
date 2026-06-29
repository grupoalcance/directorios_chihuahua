import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 IMPORTANTE: Para escuchar el estado de la sesión móvil
import '../screens/lista_doctores_screen.dart';
import '../screens/todas_especialidades_screen.dart';
import '../screens/quienes_somos_screen.dart';
import '../screens/contacto_screen.dart';
import '../screens/suscribirse_screen.dart';
import '../screens/lista_hospitales_screen.dart';
import '../screens/lista_farmacias_screen.dart';
import '../screens/login_screen.dart'; // 👈 IMPORTANTE: Para mandar al paciente a loguearse
import '../screens/paciente_dashboard_screen.dart'; // 👈 IMPORTANTE: Redirección al panel del paciente móvil
import '../services/auth_service.dart'; // 👈 IMPORTANTE: Para ejecutar el cierre de sesión

class PhoneMenuDrawer extends StatelessWidget {
  const PhoneMenuDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Encabezado del menú lateral
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Médicos Laguna',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 1. ¿Quiénes somos?
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.blue),
            title: const Text('¿Quiénes somos?'),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer móvil
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuienesSomosScreen(),
                ),
              );
            },
          ),

          // 2. Desplegable Ciudad
          ExpansionTile(
            leading: const Icon(Icons.location_city, color: Colors.blue),
            title: const Text('Ciudad'),
            children: [
              _buildSubItemCiudad(context, 'Torreón'),
              _buildSubItemCiudad(context, 'Gómez Palacio'),
              _buildSubItemCiudad(context, 'Lerdo'),
              _buildSubItemCiudad(context, 'San Pedro'),
              _buildSubItemCiudad(context, 'Fco. I. Madero'),
              _buildSubItemCiudad(context, 'Matamoros'),
            ],
          ),

          // 3. Desplegable Especialidad (Top 10 Alfabético)
          ExpansionTile(
            leading: const Icon(
              Icons.medical_services_outlined,
              color: Colors.blue,
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

              // Redirección directa al Grid Global de Especialidades
              ListTile(
                title: const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'Ver todas las especialidades ',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: Colors.blue, size: 16),
                    ],
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Cierra el menú lateral móvil
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
            leading: const Icon(Icons.local_hospital, color: Colors.blue),
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
            leading: const Icon(Icons.local_pharmacy, color: Colors.blue),
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
            leading: const Icon(Icons.people_outline, color: Colors.blue),
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
            leading: const Icon(Icons.email_outlined, color: Colors.blue),
            title: const Text('Contacto'),
            onTap: () {
              Navigator.pop(context); // Cierra el menú móvil
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactoScreen()),
              );
            },
          ),

          const Divider(),

          // =========================================================================
          // 🔐 CONTROL DE ACCESO DINÁMICO PARA EL MENÚ DE CELULARES (ACTUALIZADO)
          // =========================================================================
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              // CASO A: PACIENTE TIENE SESIÓN INICIADA -> Opciones de Mi Panel y Salir
              if (snapshot.hasData && snapshot.data != null) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.dashboard_rounded,
                        color: Colors.blue,
                      ),
                      title: const Text(
                        'Mi Panel / Perfil',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Cierra el drawer móvil
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PacienteDashboardScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.logout_rounded,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Cerrar Sesión (Paciente)',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(context); // Cierra el drawer
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
              }

              // CASO B: VISITANTE ANÓNIMO -> Opción para entrar como Paciente
              return ListTile(
                leading: const Icon(
                  Icons.lock_open_rounded,
                  color: Color(0xFF475569),
                ),
                title: const Text(
                  'Iniciar Sesión (Pacientes)',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Cierra el drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              );
            },
          ),

          // 9. Botón Destacado Fijo: Suscribirse (Membresías de Doctores)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SuscribirseScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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

  // 🛠️ Sub-item específico para Ciudades con redirección directa
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
        Navigator.pop(context); // Cierra el Drawer
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

  // 🛠️ Sub-item específico para Especialidades con redirección directa
  Widget _buildSubItemEspecialidad(
    BuildContext context,
    String nombreEspecialidad,
  ) {
    return TypographyItem(context, nombreEspecialidad);
  }

  // Helper semántico para mantener ordenado el árbol
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
        Navigator.pop(context); // Cierra el Drawer
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
