import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Tus rutas de pantallas
import 'package:directorios_laguna/screens/medicos_page_screen.dart';
import 'package:directorios_laguna/screens/doctor_profile_screen.dart';
// (Nota: Si doctor_profile_screen.dart no está en la carpeta /screens, ajusta ese import)

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

      // --- MAGIA DE ENLACES ---
      // Quitamos "home" y definimos la ruta inicial
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Si el enlace empieza con "/perfil"...
        if (settings.name != null && settings.name!.startsWith('/perfil')) {
          final uri = Uri.parse(settings.name!);
          final doctorId = uri.queryParameters['id']; // Sacamos el ID del link

          if (doctorId != null && doctorId.isNotEmpty) {
            // Lo mandamos a nuestra pantalla puente
            return MaterialPageRoute(
              builder: (context) => CargarPerfilPuente(doctorId: doctorId),
            );
          }
        }

        // Si no es un link de perfil, abrimos el Home normal
        return MaterialPageRoute(
          builder: (context) => const MedicosPageScreen(),
        );
      },
    );
  }
}

// --- PANTALLA PUENTE ---
// Esta pantalla carga 1 segundo mientras va a Firebase por los datos del link
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

          // Si lo encuentra, extraemos los datos y abrimos el perfil
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          data['uid'] = snapshot.data!.id; // Aseguramos que lleve su ID

          return DoctorProfileScreen(doctorData: data);
        },
      ),
    );
  }
}
