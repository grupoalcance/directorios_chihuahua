import 'package:flutter/material.dart';
import 'dart:ui';
import '../screens/lista_doctores_screen.dart';
import '../screens/todas_especialidades_screen.dart';
import '../screens/quienes_somos_screen.dart';
import '../screens/contacto_screen.dart';
import '../screens/suscribirse_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Function(String)? onCiudadSeleccionada;

  const CustomAppBar({Key? key, this.onCiudadSeleccionada}) : super(key: key);

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
                  'assets/images/logo.png',
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            actions: const [],
          );
        }

        return Container(
          color: Colors.white,
          child: Column(
            children: [
              // --- PISO 1: LOGOTIPO Y BANNER ---
              Container(
                height: 90,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 65,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    Container(
                      width: 500,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Espacio para Banner Comercial / GIF',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const QuienesSomosScreen(), // 👈 Agregado aquí
                          ),
                        );
                      },
                      child: Text('¿Quiénes somos?', style: menuStyle),
                    ),
                    const SizedBox(width: 5),

                    // Menú de Ciudad Corregido para Redirigir si es necesario
                    _buildDropdownMenu(
                      context: context,
                      label: 'Ciudad',
                      style: menuStyle,
                      items: [
                        'Torreón',
                        'Gómez Palacio',
                        'Lerdo',
                        'San Pedro',
                        'Fco. I. Madero',
                        'Matamoros',
                      ],
                    ),
                    const SizedBox(width: 5),

                    // --- DESPLEGABLE DE ESPECIALIDADES ---
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
                          // 👇 CORREGIDO: Ahora redirige de forma directa a tu nuevo Grid global de especialidades
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
                            _buildMenuItem(
                              'Pediatría',
                            ), // 👈 Cortado estratégicamente en la 10 alfabética
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'ver_todas',
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Ver todas las especialidades',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                    ),
                    const SizedBox(width: 5),

                    TextButton(
                      onPressed: () {},
                      child: Text('Hospitales', style: menuStyle),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text('Farmacias', style: menuStyle),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text('Enfermería', style: menuStyle),
                    ),

                    TextButton(
                      onPressed: () {},
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
                      child: Text('Contacto', style: menuStyle),
                    ),

                    const SizedBox(width: 15),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SuscribirseScreen(), 
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
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

  // Molde del Menú Desplegable Inteligente con Redirección Integrada
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
        if (onCiudadSeleccionada != null) {
          onCiudadSeleccionada!.call(valorElegido);
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
