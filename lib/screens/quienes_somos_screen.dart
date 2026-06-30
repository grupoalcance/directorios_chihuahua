import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/phone_menu_drawer.dart';

class QuienesSomosScreen extends StatelessWidget {
  const QuienesSomosScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fondo Slate 50
      appBar: const CustomAppBar(),
      drawer: width < 1100 ? const PhoneMenuDrawer() : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- BLOQUE 1: ENCABEZADO / HERO ---
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: width < 600 ? 40 : 60,
                horizontal: 20,
              ),
              color: const Color(0xFF1E3A8A),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      const Text(
                        '¿Quiénes Somos?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Conectamos a la Comarca Lagunera con la atención médica de la más alta calidad de manera rápida, directa y transparente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- CONTENEDOR MÁSTER DE CONTENIDO ---
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                padding: EdgeInsets.symmetric(
                  horizontal: width < 600 ? 20.0 : 40.0,
                  vertical: 40.0,
                ),
                child: Column(
                  children: [
                    // --- BLOQUE 2: HISTORIA E IMAGEN ---
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool esPC = constraints.maxWidth > 750;
                        return esPC
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(child: _buildTextoIntroductorio()),
                                  const SizedBox(width: 40),
                                  Expanded(child: _buildImagenDestacada()),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildTextoIntroductorio(),
                                  const SizedBox(height: 30),
                                  _buildImagenDestacada(),
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 50),

                    // --- BLOQUE 3: PILARES (MISIÓN Y VISIÓN) ---
                    _buildSeccionPilares(width),
                    const SizedBox(height: 50),

                    // --- BLOQUE 4: NUESTROS VALORES ---
                    _buildSeccionValores(width),
                    const SizedBox(height: 60),

                    // --- BLOQUE 5: CONTADORES / NÚMEROS CLAVE (Modificado de forma simétrica) ---
                    _buildSeccionNumeros(width),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextoIntroductorio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Médicos Laguna',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Nacimos como una iniciativa tecnológica local con el propósito de modernizar y digitalizar el acceso a la salud en nuestra región.\n\nSabemos lo difícil y tedioso que puede ser buscar un especialista confiable, encontrar sus horarios disponibles o contactar a su consultorio. Por ello, diseñamos un directorio médico inteligente donde los pacientes pueden explorar perfiles detallados, verificar cédulas profesionales y agendar citas de forma directa a través de WhatsApp, eliminando intermediarios y comisiones.',
          style: TextStyle(fontSize: 15, color: Color(0xFF475569), height: 1.5),
        ),
      ],
    );
  }

  Widget _buildImagenDestacada() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        'assets/images/medicos_laguna_portada.png',
        fit: BoxFit.cover,
        height: 280,
        width: double.infinity,
      ),
    );
  }

  Widget _buildSeccionPilares(double width) {
    bool esPC = width > 750;
    return esPC
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _cardPilar(
                  Icons.track_changes_rounded,
                  Colors.blue,
                  'Nuestra Misión',
                  'Proveer a los habitantes de Torreón, Gómez Palacio, Lerdo y alrededores una plataforma digital intuitiva y centralizada que facilite el contacto directo con profesionales de la salud certificados, promoviendo el bienestar lagunero.',
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _cardPilar(
                  Icons.remove_red_eye_rounded,
                  Colors.teal,
                  'Nuestra Visión',
                  'Consolidarnos como el directorio médico y de salud referente de la Comarca Lagunera, reconocido por la veracidad de su información, la calidad visual de sus perfiles y el impulso al crecimiento de la comunidad médica local.',
                ),
              ),
            ],
          )
        : Column(
            children: [
              _cardPilar(
                Icons.track_changes_rounded,
                Colors.blue,
                'Nuestra Misión',
                'Proveer a los habitantes de Torreón, Gómez Palacio, Lerdo y alrededores una plataforma digital intuitiva y centralizada que facilite el contacto directo con profesionales de la salud certificados, promoviendo el bienestar lagunero.',
              ),
              const SizedBox(height: 20),
              _cardPilar(
                Icons.remove_red_eye_rounded,
                Colors.teal,
                'Nuestra Visión',
                'Consolidarnos como el directorio médico y de salud referente de la Comarca Lagunera, reconocido por la veracidad de su información, la calidad visual de sus perfiles y el impulso al crecimiento de la comunidad médica local.',
              ),
            ],
          );
  }

  Widget _cardPilar(IconData icon, Color color, String titulo, String desc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionValores(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Valores que nos guían',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 20),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: width > 750 ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: width > 750 ? 1.1 : 0.95,
          ),
          children: [
            _itemValor(
              Icons.gavel_rounded,
              'Transparencia',
              'Contacto directo paciente-médico, sin costos ocultos.',
            ),
            _itemValor(
              Icons.verified_user_rounded,
              'Veracidad',
              'Validamos de forma rigurosa la autenticidad y cédulas.',
            ),
            _itemValor(
              Icons.speed_rounded,
              'Inmediatez',
              'Búsquedas predictivas eficaces y agendamiento veloz.',
            ),
            _itemValor(
              Icons.people_alt_rounded,
              'Comunidad',
              'Impulsamos el desarrollo de nuestra Comarca Lagunera.',
            ),
          ],
        ),
      ],
    );
  }

  Widget _itemValor(IconData icon, String titulo, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 28),
          const SizedBox(height: 10),
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionNumeros(double width) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          bool esPC = width > 600;
          return esPC
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _datoMetrico('+100', 'Especialidades y Subespecialidades Médicas'),
                    _datoMetrico('6', 'Ciudades de Cobertura'),
                  ],
                )
              : Column(
                  children: [
                    _datoMetrico('+100', 'Especialidades y Subespecialidades Médicas'),
                    const Divider(color: Colors.white24, height: 30),
                    _datoMetrico('6', 'Ciudades de Cobertura'),
                  ],
                );
        },
      ),
    );
  }

  Widget _datoMetrico(String numero, String texto) {
    return Column(
      children: [
        Text(
          numero,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
