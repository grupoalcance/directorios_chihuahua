import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

// 🔑 IMPORTACIÓN DEL ARCHIVO MAESTRO
import 'package:directorios_durango/config/app_config.dart';

import '../screens/todas_especialidades_screen.dart';
import '../screens/lista_doctores_screen.dart';
import '../screens/lista_farmacias_screen.dart';
import '../screens/lista_hospitales_screen.dart';
import '../services/auth_service.dart';
import '../screens/contacto_screen.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Function(String)? onCiudadSeleccionada;

  const CustomAppBar({Key? key, this.onCiudadSeleccionada}) : super(key: key);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize {
    try {
      final dispatcher = PlatformDispatcher.instance;
      final screenWidth =
          dispatcher.views.first.physicalSize.width /
          dispatcher.views.first.devicePixelRatio;
      return Size.fromHeight(screenWidth < 1100 ? kToolbarHeight : 140);
    } catch (e) {
      return const Size.fromHeight(kToolbarHeight);
    }
  }
}

class _CustomAppBarState extends State<CustomAppBar> {
  late Stream<DateTime> _timeStream;

  // 🎯 BANNERS ESTÁTICOS CON URL DIRECTA (Cero fallos en Flutter Web)
  final List<Map<String, String>> misBannersEstaticos = [
    {
      'imagen': 'assets/banners/sanjorge.png',
      'url': 'https://www.facebook.com/HospitalSanJorgeDgo/?locale=es_LA',
    },
    {
      'imagen': 'assets/banners/alcance.gif',
      'url': 'https://agenciaalcance.com/',
    },
  ];

  // Variables para la rotación automática de Banners
  final PageController _bannerPageController = PageController();
  Timer? _bannerTimer;
  int _bannerPaginaActual = 0;

  @override
  void initState() {
    super.initState();
    _timeStream = Stream<DateTime>.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );
    _iniciarTemporizadorBanners();
  }

  void _iniciarTemporizadorBanners() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (misBannersEstaticos.length > 1 && _bannerPageController.hasClients) {
        _bannerPaginaActual++;
        if (_bannerPaginaActual >= misBannersEstaticos.length) {
          _bannerPaginaActual = 0;
        }
        _bannerPageController.animateToPage(
          _bannerPaginaActual,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    super.dispose();
  }

  Future<void> _abrirEnlaceAnuncio(String urlStr) async {
    if (urlStr.isEmpty) return;
    final Uri url = Uri.parse(urlStr);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('No se pudo abrir el enlace publicitario');
    }
  }

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
      debugPrint("Error al obtener rol: $e");
    }
    return 'paciente';
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle menuStyle = const TextStyle(
      color: Color(0xFF334155),
      fontWeight: FontWeight.w600,
      fontSize: 14,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        bool esCelular = constraints.maxWidth < 1100;

        if (esCelular) {
          return AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 1,
            iconTheme: const IconThemeData(color: Color(0xFF334155)),
            title: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                ),
                child: Image.asset(
                  AppConfig.logoPath,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        }

        return Container(
          color: Colors.white,
          child: Column(
            children: [
              // --- PISO 1: LOGOTIPO, ANUNCIOS ROTATIVOS Y CLIMA ---
              Container(
                height: 90,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: [
                    // LOGO (IZQUIERDA)
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/',
                              (route) => false,
                            ),
                            child: Image.asset(
                              AppConfig.logoPath,
                              height: 65,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 🎯 PUBLICIDAD MASTER
                    misBannersEstaticos.isEmpty
                        ? Container(
                            width: 500,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: const Center(
                              child: Text(
                                'Espacio Disponible para Publicidad',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: 500,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: PageView.builder(
                                controller: _bannerPageController,
                                itemCount: misBannersEstaticos.length,
                                onPageChanged: (index) =>
                                    _bannerPaginaActual = index,
                                itemBuilder: (context, index) {
                                  var bannerData = misBannersEstaticos[index];
                                  String fotoRuta = bannerData['imagen'] ?? '';
                                  String destinoUrl = bannerData['url'] ?? '';

                                  return MouseRegion(
                                    cursor: destinoUrl.isNotEmpty
                                        ? SystemMouseCursors.click
                                        : SystemMouseCursors.basic,
                                    child: GestureDetector(
                                      onTap: () =>
                                          _abrirEnlaceAnuncio(destinoUrl),
                                      child: fotoRuta.startsWith('http')
                                          ? Image.network(
                                              fotoRuta,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) =>
                                                  _buildErrorPlaceholder(),
                                            )
                                          : Image.asset(
                                              fotoRuta,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) =>
                                                  _buildErrorPlaceholder(),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                    // CLIMA Y HORA (DERECHA)
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(
                            Icons.wb_sunny_rounded,
                            color: Colors.amber,
                            size: 26,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${AppConfig.ciudadesActivas[0]} 34°C',
                                style: const TextStyle(
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                              StreamBuilder<DateTime>(
                                stream: _timeStream,
                                builder: (context, snapshot) {
                                  final now = snapshot.data ?? DateTime.now();
                                  final String timeStr = DateFormat(
                                    'hh:mm:ss a',
                                  ).format(now);
                                  final String dateStr = DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(now);
                                  return Text(
                                    '$dateStr · $timeStr',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // --- PISO 2: BARRA DE NAVEGACIÓN ---
              Container(
                height: 49,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/quienes-somos'),
                      child: Text('¿Quiénes somos?', style: menuStyle),
                    ),
                    const SizedBox(width: 5),
                    _buildDropdownMenu(
                      context: context,
                      label: 'Ciudad',
                      style: menuStyle,
                      items: AppConfig.ciudadesActivas,
                    ),
                    const SizedBox(width: 5),
                    PopupMenuButton<String>(
                      tooltip: 'Seleccionar Especialidad',
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Row(
                          children: [
                            Text('Especialidad', style: menuStyle),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: menuStyle.color,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      onSelected: (String especialidad) {
                        if (especialidad == 'ver_todas') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TodasEspecialidadesScreen(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ListaDoctoresScreen(
                                especialidad: especialidad,
                                ciudad: '',
                              ),
                            ),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            _buildMenuItem('Cardiología'),
                            _buildMenuItem('Dermatología'),
                            _buildMenuItem('Ginecología y Obstetricia'),
                            _buildMenuItem('Medicina General'),
                            _buildMenuItem('Neumología'),
                            _buildMenuItem('Neurología'),
                            _buildMenuItem('Nutrición'),
                            _buildMenuItem('Odontología (Dentista)'),
                            _buildMenuItem('Oftalmología'),
                            _buildMenuItem('Pediatría'),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'ver_todas',
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Ver todas las especialidades',
                                    style: TextStyle(
                                      color: AppConfig.primaryColor,
                                      fontWeight: FontWeight.bold,
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
                          ],
                    ),
                    const SizedBox(width: 5),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ListaHospitalesScreen(),
                        ),
                      ),
                      child: Text('Hospitales', style: menuStyle),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ListaFarmaciasScreen(),
                        ),
                      ),
                      child: Text('Farmacias', style: menuStyle),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ListaDoctoresScreen(
                            especialidad: 'Enfermería General',
                            ciudad: '',
                          ),
                        ),
                      ),
                      child: Text('Enfermería', style: menuStyle),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ListaDoctoresScreen(
                            especialidad: 'Urgencias Médicas 24/7',
                            ciudad: '',
                          ),
                        ),
                      ),
                      child: const Text(
                        'Urgencias 24/hrs',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactoScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Contacto',
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(snapshot.data!.uid)
                                .get(),
                            builder: (context, userSnapshot) {
                              bool esAsesor = false;
                              String rolDetectado = 'paciente';

                              if (userDocExists(userSnapshot)) {
                                final uData =
                                    userSnapshot.data!.data()
                                        as Map<String, dynamic>;
                                rolDetectado = (uData['rol'] ?? 'paciente')
                                    .toString()
                                    .trim()
                                    .toLowerCase();
                                esAsesor =
                                    (rolDetectado == 'vendedor' ||
                                    rolDetectado == 'admin' ||
                                    rolDetectado == 'administrador');
                              }

                              return PopupMenuButton<String>(
                                color: Colors.white,
                                surfaceTintColor: Colors.white,
                                elevation: 4,
                                onSelected: (String valor) async {
                                  if (valor == 'ir_panel') {
                                    if (rolDetectado == 'admin' ||
                                        rolDetectado == 'administrador') {
                                      Navigator.pushNamed(
                                        context,
                                        '/admin_dashboard',
                                      );
                                    } else if (rolDetectado == 'vendedor') {
                                      final Uri url = Uri.parse(
                                        AppConfig.crmUrl,
                                      );
                                      launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } else {
                                      Navigator.pushNamed(
                                        context,
                                        '/paciente_dashboard',
                                      );
                                    }
                                  } else if (valor == 'ir_captura') {
                                    final Uri url = Uri.parse(AppConfig.crmUrl);
                                    launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else if (valor == 'cerrar_sesion') {
                                    await AuthService().cerrarSesion();
                                    if (context.mounted) {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/',
                                        (route) => false,
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.account_circle_rounded,
                                        color: AppConfig.primaryColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Mi Cuenta',
                                        style: TextStyle(
                                          color: Color(0xFF334155),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.grey,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                                itemBuilder: (context) => [
                                  PopupMenuItem<String>(
                                    value: 'ir_panel',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.dashboard_rounded,
                                          color: AppConfig.primaryColor,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          (rolDetectado == 'admin' ||
                                                  rolDetectado ==
                                                      'administrador')
                                              ? 'Panel Administrador'
                                              : rolDetectado == 'vendedor'
                                              ? 'Abrir Panel de Ventas'
                                              : 'Mi Panel de Control',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (esAsesor)
                                    const PopupMenuItem<String>(
                                      value: 'ir_captura',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.assignment_turned_in_outlined,
                                            color: Colors.green,
                                            size: 18,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Sistema de Asesores',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem<String>(
                                    value: 'cerrar_sesion',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.logout_rounded,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Cerrar Sesión',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    const SizedBox(width: 10),

                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/suscribirse'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Suscribirse',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Text(
          'Espacio Disponible para Publicidad',
          style: TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ),
    );
  }

  bool userDocExists(AsyncSnapshot<DocumentSnapshot> snap) {
    return snap.hasData &&
        snap.data != null &&
        snap.data!.exists &&
        snap.data!.data() != null;
  }

  Widget _buildDropdownMenu({
    required BuildContext context,
    required String label,
    required TextStyle style,
    required List<String> items,
  }) {
    return PopupMenuButton<String>(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          children: [
            Text(label, style: style),
            Icon(Icons.keyboard_arrow_down, color: style.color, size: 20),
          ],
        ),
      ),
      onSelected: (String valorElegido) {
        if (widget.onCiudadSeleccionada != null) {
          widget.onCiudadSeleccionada!.call(valorElegido);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ListaDoctoresScreen(especialidad: '', ciudad: valorElegido),
            ),
          );
        }
      },
      itemBuilder: (context) =>
          items.map((item) => _buildMenuItem(item)).toList(),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String texto) {
    return PopupMenuItem(
      value: texto,
      child: Text(texto, style: const TextStyle(color: Color(0xFF334155))),
    );
  }
}
