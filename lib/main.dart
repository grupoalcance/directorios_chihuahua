import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

// 🔑 IMPORTACIÓN DEL ARCHIVO MAESTRO
import 'package:directorios_durango/config/app_config.dart';

import 'package:directorios_durango/screens/medicos_page_screen.dart';
import 'package:directorios_durango/screens/doctor_profile_screen.dart';
import 'package:directorios_durango/screens/admin_dashboard_screen.dart';
import 'package:directorios_durango/screens/login_screen.dart';
import 'package:directorios_durango/screens/suscribirse_screen.dart';
import 'package:directorios_durango/screens/contacto_screen.dart';
import 'package:directorios_durango/screens/quienes_somos_screen.dart';

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
      title: AppConfig.appName, // 🔑 TOMA EL NOMBRE DEL ARCHIVO MAESTRO
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConfig.primaryColor,
        ), // 🔑 TOMA EL COLOR MAESTRO
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

        // 💳 1. RUTA PARA SUSCRIBIRSE / UNETE
        if (routeName != null &&
            (routeName == '/suscribirse' ||
                routeName.contains('suscribirse'))) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const SuscribirseScreen(),
          );
        }

        // 📞 2. NUEVA RUTA REGISTRADA PARA CONTACTO
        if (routeName != null &&
            (routeName == '/contacto' || routeName.contains('contacto'))) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const ContactoScreen(),
          );
        }

        // ℹ️ 3. NUEVA RUTA REGISTRADA PARA QUIÉNES SOMOS
        if (routeName != null &&
            (routeName == '/quienes-somos' ||
                routeName.contains('quienes-somos'))) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const QuienesSomosScreen(),
          );
        }

        // 🔑 4. INTERCEPTOR DE LOGIN
        if (routeName != null &&
            (routeName == '/ingresar' || routeName.contains('ingresar'))) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const LoginScreen(),
          );
        }

        // 📊 5. DASHBOARD ADMINISTRACIÓN
        if (routeName != null &&
            (routeName == '/admin_dashboard' ||
                routeName.contains('admin_dashboard'))) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const AdminDashboardScreen(),
          );
        }

        // 🩺 6. PERFILES DE MÉDICOS (Ej: /perfil?id=123)
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

        // 🏠 7. RUTA POR DEFECTO (Home / Inicio)
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
