import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // <-- IMPORTANTE: Para el temporizador del carrusel
import 'package:url_launcher/url_launcher.dart'; // <-- Para abrir los links de los anuncios
import '../screens/login_screen.dart';
import '../screens/doctor_dashboard_screen.dart';
import '../screens/paciente_dashboard_screen.dart';
import '../screens/all_blogs_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(100);

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
      toolbarHeight: 100,
      automaticallyImplyLeading: false,
      title: Container(
        padding: EdgeInsets.symmetric(
          horizontal: width > 1000 ? width * 0.1 : 10,
        ),
        child: Row(
          children: [
            // --- ÁREA DEL LOGO Y CARRUSEL PUBLICITARIO ---
            Row(
              children: [
                // 1. TU LOGO
                InkWell(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 70,
                    errorBuilder: (context, error, stackTrace) => const Row(
                      children: [
                        Icon(
                          Icons.medical_services,
                          color: Colors.blue,
                          size: 35,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Médicos Laguna',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Separación entre el logo y el carrusel
                if (width > 600) const SizedBox(width: 30),

                // 👇 2. LLAMAMOS AL NUEVO CARRUSEL DE ANUNCIOS 👇
                if (width > 600) const BannerPublicitario(),
              ],
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

// =======================================================
// 🚀 NUEVO WIDGET: CARRUSEL DE PUBLICIDAD AUTOMÁTICO
// =======================================================
class BannerPublicitario extends StatefulWidget {
  const BannerPublicitario({super.key});

  @override
  State<BannerPublicitario> createState() => _BannerPublicitarioState();
}

class _BannerPublicitarioState extends State<BannerPublicitario> {
  int _currentIndex = 0;
  Timer? _timer;

  // 👇 AQUÍ PONES TUS ANUNCIOS (Imagen y a dónde lleva el clic)
  final List<Map<String, String>> _anuncios = [
    {
      'img':
          'https://via.placeholder.com/350x70/1E3A8A/FFFFFF?text=Anuncia+tu+Clínica+Aquí',
      'link': 'https://medicoslaguna.com/', // A dónde va al hacer clic
    },
    {
      'img':
          'https://via.placeholder.com/350x70/10B981/FFFFFF?text=Farmacia+San+Juan+-+24hrs',
      'link': 'https://google.com',
    },
    {
      'img':
          'https://via.placeholder.com/350x70/F59E0B/FFFFFF?text=Laboratorios+Laguna+-+10%25+Desc',
      'link': 'https://youtube.com',
    },
  ];

  @override
  void initState() {
    super.initState();
    // ⏱️ Cambia la imagen cada 5 segundos
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _anuncios.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Apagamos el reloj si cambiamos de pantalla
    super.dispose();
  }

  Future<void> _abrirLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('No se pudo abrir el anuncio');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800), // Qué tan suave es el cambio
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: InkWell(
        key: ValueKey<int>(_currentIndex), // Clave para que cambie la animación
        onTap: () => _abrirLink(_anuncios[_currentIndex]['link']!),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _anuncios[_currentIndex]['img']!,
            height: 70,
            width: 350,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox(width: 350, height: 70),
          ),
        ),
      ),
    );
  }
}
