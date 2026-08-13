import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

// 🔑 IMPORTACIÓN DEL ARCHIVO MAESTRO DE sinaloa
import 'package:directorios_sinaloa/config/app_config.dart';

import 'package:directorios_sinaloa/screens/medicos_page_screen.dart';
import 'package:directorios_sinaloa/screens/doctor_profile_screen.dart';
import 'package:directorios_sinaloa/screens/admin_dashboard_screen.dart';
import 'package:directorios_sinaloa/screens/login_screen.dart';
import 'package:directorios_sinaloa/screens/suscribirse_screen.dart';
import 'package:directorios_sinaloa/screens/quienes_somos_screen.dart';
import 'package:directorios_sinaloa/screens/contacto_screen.dart';
import 'package:directorios_sinaloa/screens/lista_hospitales_screen.dart';
import 'package:directorios_sinaloa/screens/lista_farmacias_screen.dart';
import 'package:directorios_sinaloa/screens/todas_especialidades_screen.dart';
import 'package:directorios_sinaloa/screens/lista_doctores_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppConfig.primaryColor),
        useMaterial3: true,
      ),

      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.trackpad,
        },
      ),

      initialRoute: '/',
      onGenerateRoute: (settings) {
        final String? routeName = settings.name;

        // 💳 1. SUSCRIBIRSE / UNETE
        if (routeName != null && routeName.contains('suscribirse')) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const SuscribirseScreen(),
          );
        }

        // ℹ️ 2. ¿QUIÉNES SOMOS?
        if (routeName != null && routeName.contains('quienes-somos')) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const QuienesSomosScreen(),
          );
        }

        // ✉️ 3. CONTACTO
        if (routeName != null && routeName.contains('contacto')) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const ContactoScreen(),
          );
        }

        // 🏥 4. HOSPITALES / CLÍNICAS
        if (routeName != null && routeName.contains('hospitales')) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const ListaHospitalesScreen(),
          );
        }

        // 💊 5. FARMACIAS
        if (routeName != null && routeName.contains('farmacias')) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const ListaFarmaciasScreen(),
          );
        }

        // 🩺 6. TODAS LAS ESPECIALIDADES
        if (routeName != null && routeName.contains('especialidades')) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const TodasEspecialidadesScreen(),
          );
        }

        // 👨‍⚕️ 7. LISTADO DE DOCTORES CON PARÁMETROS
        if (routeName != null && routeName.startsWith('/doctores')) {
          final uri = Uri.parse(routeName);
          final especialidad = uri.queryParameters['especialidad'] ?? '';
          final ciudad = uri.queryParameters['ciudad'] ?? '';

          return MaterialPageRoute(
            settings: settings,
            builder: (context) =>
                ListaDoctoresScreen(especialidad: especialidad, ciudad: ciudad),
          );
        }

        // 🔑 8. INTERCEPTOR DE LOGIN
        if (routeName != null && routeName.contains('ingresar')) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const LoginScreen(),
          );
        }

        // 📊 9. DASHBOARD ADMINISTRACIÓN
        if (routeName != null && routeName.contains('admin_dashboard')) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const AdminDashboardScreen(),
          );
        }

        // 🩺 10. PERFILES DE MÉDICOS (Ej: /perfil?id=123)
        if (routeName != null && routeName.startsWith('/perfil')) {
          final uri = Uri.parse(routeName);
          final doctorId = uri.queryParameters['id'];

          if (doctorId != null && doctorId.isNotEmpty) {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => CargarPerfilPuente(doctorId: doctorId),
            );
          }
        }

        // 🏠 11. RUTA POR DEFECTO (Home / Inicio)
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const MedicosPageScreen(),
        );
      },
    );
  }
}

// --- PANTALLA PUENTE DE CARGA NATIVA ---
class CargarPerfilPuente extends StatelessWidget {
  final String doctorId;

  const CargarPerfilPuente({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(doctorId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    'No se encontró el perfil de este médico.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/'),
                    child: const Text('Volver al inicio'),
                  ),
                ],
              ),
            );
          }

          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          data['uid'] = snapshot.data!.id;

          return DoctorProfileScreen(doctorData: data);
        },
      ),
    );
  }
}
