import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/login_screen.dart';
import '../screens/doctor_dashboard_screen.dart';
import '../screens/paciente_dashboard_screen.dart';
import '../screens/all_blogs_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(80);

  // --- LÓGICA INTELIGENTE DE PERFIL ---
  Future<void> _abrirMiPerfilInteligente(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        String rol = doc.get('rol');
        if (!context.mounted) return;

        if (rol == 'medico') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DoctorDashboardScreen(),
            ),
          );
        } else if (rol == 'paciente') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PacienteDashboardScreen(),
            ),
          );
        }
      }
    }
  }

  // --- BOTÓN DE MENÚ TEXTO ---
  Widget _menuButton(BuildContext context, String text, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextButton(
        onPressed: onTap ?? () {},
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.white,
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      title: Container(
        padding: EdgeInsets.symmetric(
          horizontal: width > 1000 ? width * 0.1 : 10,
        ),
        child: Row(
          children: [
            // --- LOGO DE LA PLATAFORMA ---
            InkWell(
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () => Navigator.popUntil(
                context,
                (route) => route.isFirst,
              ), // Regresa al Home
              child: Image.asset(
                'assets/images/logo.png', // <-- AQUÍ SE CARGA TU LOGO
                height:
                    40, // Ajusta este tamaño si lo ves muy grande o muy chico
                // Si la imagen no carga, mostramos el texto clásico como respaldo
                errorBuilder: (context, error, stackTrace) => const Row(
                  children: [
                    Icon(Icons.medical_services, color: Colors.blue, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Médicos Laguna',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),

            // --- MENÚ DERECHO ---
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(width: 100);
                }

                bool isLogged = snapshot.hasData;

                if (width > 800) {
                  // --- VISTA COMPUTADORA ---
                  return Row(
                    children: [
                      _menuButton(
                        context,
                        'Inicio',
                        onTap: () => Navigator.popUntil(
                          context,
                          (route) => route.isFirst,
                        ),
                      ),
                      _menuButton(
                        context,
                        'Blog',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllBlogsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 15),

                      if (isLogged)
                        ElevatedButton.icon(
                          onPressed: () => _abrirMiPerfilInteligente(context),
                          icon: const Icon(Icons.person, size: 18),
                          label: const Text('Mi Perfil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade50,
                            foregroundColor: Colors.blue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Iniciar Sesión',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                    ],
                  );
                } else {
                  // --- VISTA CELULAR ---
                  return Row(
                    children: [
                      if (isLogged)
                        IconButton(
                          onPressed: () => _abrirMiPerfilInteligente(context),
                          icon: const Icon(Icons.person, color: Colors.blue),
                        )
                      else
                        IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.login, color: Colors.blue),
                        ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
