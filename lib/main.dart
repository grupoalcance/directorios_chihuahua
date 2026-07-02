import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Tus rutas de pantallas mapeadas correctamente
import 'package:directorios_laguna/screens/medicos_page_screen.dart';
import 'package:directorios_laguna/screens/doctor_profile_screen.dart';
import 'package:directorios_laguna/screens/admin_dashboard_screen.dart';
import 'package:directorios_laguna/screens/login_screen.dart'; // 👈 IMPORTADO: Para el acceso oculto seguro

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

      // --- MAGIA DE ENLACES CRUZADOS Y RUTAS WEB ---
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // 🔑 1. INTERCEPTOR DE ACCESO OCULTO PARA ADMINISTRADORES Y DOCTORES
        // Al escribir tudominio.com/#/ingresar en producción, saltará la pantalla de login de forma segura
        if (settings.name != null && settings.name == '/ingresar') {
          return MaterialPageRoute(builder: (context) => const LoginScreen());
        }

        // 📊 2. RUTA RESPALDO PARA EL DASHBOARD DE ADMINISTRACIÓN
        if (settings.name != null && settings.name == '/admin_dashboard') {
          return MaterialPageRoute(
            builder: (context) => const AdminDashboardScreen(),
          );
        }

        // 🩺 3. ENLACES COMPARTIDOS DIRECTOS (Tu código original intacto)
        if (settings.name != null && settings.name!.startsWith('/perfil')) {
          final uri = Uri.parse(settings.name!);
          final doctorId =
              uri.queryParameters['id']; // Extraemos el ID del médico del link

          if (doctorId != null && doctorId.isNotEmpty) {
            // Mandamos al usuario a nuestra pantalla puente de carga
            return MaterialPageRoute(
              builder: (context) => CargarPerfilPuente(doctorId: doctorId),
            );
          }
        }

        // 🏠 4. RUTA POR DEFECTO: Si el link no coincide con nada, abre el Home principal
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
