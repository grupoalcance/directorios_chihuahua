import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // 🔑 IMPORTACIÓN AÑADIDA: Necesaria para activar los dragDevices
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:directorios_laguna/screens/medicos_page_screen.dart';
import 'package:directorios_laguna/screens/doctor_profile_screen.dart';
import 'package:directorios_laguna/screens/admin_dashboard_screen.dart';
import 'package:directorios_laguna/screens/login_screen.dart';
import 'package:directorios_laguna/screens/registro_contrato_vendedor_screen.dart';
import 'package:directorios_laguna/screens/admin_contratos_dashboard_screen.dart'; 

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
      title: 'Médicos Laguna',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      
      // 🔑 CONFIGURACIÓN GLOBAL DE SCROLL AÑADIDA: Homologa mouse, touch y trackpads
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.trackpad,
        },
      ),

      // --- MAGIA DE ENLACES CRUZADOS Y RUTAS WEB ---
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final String? routeName = settings.name;

        // 🔑 1. INTERCEPTOR FLEXIBLE DE ACCESO OCULTO PARA LOGIN (Inmune a variaciones de hash web)
        if (routeName != null &&
            (routeName == '/ingresar' || routeName.contains('ingresar'))) {
          return MaterialPageRoute(builder: (context) => const LoginScreen());
        }

        // 📊 2. RUTA RESPALDO PARA EL DASHBOARD DE ADMINISTRACIÓN
        if (routeName != null &&
            (routeName == '/admin_dashboard' ||
                routeName.contains('admin_dashboard'))) {
          return MaterialPageRoute(
            builder: (context) => const AdminDashboardScreen(),
          );
        }

        // 📝 3. REGISTRO DE CONTRATOS PARA VENDEDORES (Filtro ultra tolerante para la URL)
        if (routeName != null &&
            (routeName == '/captura-contratos' ||
                routeName.contains('captura-contratos'))) {
          return MaterialPageRoute(
            builder: (context) => const RegistroContratoVendedorScreen(),
          );
        }

        // 📂 4. ¡LA PIEZA FALTANTE!: REGISTRO Y ACTIVACIÓN DE LA RUTA DE CONTRATOS
        if (routeName != null &&
            (routeName == '/admin_contratos' ||
                routeName.contains('admin_contratos'))) {
          return MaterialPageRoute(
            builder: (context) => const AdminContratosDashboardScreen(),
          );
        }

        // 🩺 5. ENLACES COMPARTIDOS DIRECTOS (Tu código original intacto)
        if (routeName != null && routeName.startsWith('/perfil')) {
          final uri = Uri.parse(routeName);
          final doctorId =
              uri.queryParameters['id']; // Extraemos el ID del médico del link

          if (doctorId != null && doctorId.isNotEmpty) {
            // Mandamos al usuario a nuestra pantalla puente de carga
            return MaterialPageRoute(
              builder: (context) => CargarPerfilPuente(doctorId: doctorId),
            );
          }
        }

        // 🏠 6. RUTA POR DEFECTO: Si el link no coincide con nada, abre el Home principal
        return MaterialPageRoute(
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
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MedicosPageScreen(),
                      ),
                    ),
                    child: const Text('Volver al inicio'),
                  ),
                ],
              ),
            );
          }

          // Si el registro existe en Firestore, armamos el mapa e inyectamos su UID
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          data['uid'] = snapshot.data!.id;

          return DoctorProfileScreen(doctorData: data);
        },
      ),
    );
  }
}