import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_app_bar.dart'; // <-- IMPORTAMOS LA NUEVA BARRA

class DoctorBasicProfileScreen extends StatefulWidget {
  final Map<String, dynamic> doctorData;

  const DoctorBasicProfileScreen({super.key, required this.doctorData});

  @override
  State<DoctorBasicProfileScreen> createState() =>
      _DoctorBasicProfileScreenState();
}

class _DoctorBasicProfileScreenState extends State<DoctorBasicProfileScreen> {
  // --- VARIABLE DE ESTADO PARA CONTROLAR LA PESTAÑA ---
  int _selectedClinicIndex = 0;

  // --- FUNCIÓN PARA LEER EL HORARIO DÍA POR DÍA ---
  String _formatearHorario(Map<String, dynamic>? horarioMap) {
    if (horarioMap == null || horarioMap.isEmpty) return 'Previa Cita';

    List<String> dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    String resultado = '';

    for (String dia in dias) {
      if (horarioMap.containsKey(dia)) {
        var config = horarioMap[dia];
        bool abierto = config['abierto'] ?? false;
        if (abierto) {
          resultado += '$dia: ${config['de']} - ${config['a']}\n';
        } else {
          resultado += '$dia: Cerrado\n';
        }
      }
    }
    return resultado.trim();
  }

  // --- 1. FUNCIÓN PARA LLAMAR ---
  Future<void> _llamarTelefono(String telefono) async {
    if (telefono.isEmpty) return;

    // Limpiamos el número de espacios o guiones
    String cleanPhone = telefono.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri url = Uri.parse('tel:$cleanPhone');

    if (!await launchUrl(url)) {
      debugPrint('No se pudo abrir la app de teléfono');
    }
  }

  // --- 2. FUNCIÓN PARA WHATSAPP (Con mensaje predeterminado) ---
  Future<void> _abrirWhatsApp(String whatsapp) async {
    if (whatsapp.isEmpty) return;

    // Limpiamos el número
    String cleanPhone = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');

    // Si el número tiene 10 dígitos (normal en México), le agregamos el código de país (52)
    if (!cleanPhone.startsWith('52') && cleanPhone.length == 10) {
      cleanPhone = '52$cleanPhone';
    }

    // Creamos un mensaje automático genial
    String mensaje = Uri.encodeComponent(
      'Hola Doctor(a), vi su perfil en médicosdurango.com y me gustaría agendar una cita.',
    );
    final Uri url = Uri.parse('https://wa.me/$cleanPhone?text=$mensaje');

    // LaunchMode.externalApplication fuerza a que se abra la app de WhatsApp y no el navegador web
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('No se pudo abrir WhatsApp');
    }
  }

  // --- 3. FUNCIÓN PARA GOOGLE MAPS ---
  Future<void> _abrirGoogleMaps(String direccion) async {
    if (direccion.isEmpty) return;

    // Codificamos la dirección para que sea una búsqueda válida en Maps (le añadimos "Durango" por defecto para ayudar al mapa)
    final String query = Uri.encodeComponent('$direccion, Durango, Coahuila');
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('No se pudo abrir Google Maps');
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = widget.doctorData;

    String doctorId = data['uid'] ?? ''; // Para el link de compartir

    String nombreCompleto = '${data['nombre'] ?? ''} ${data['apellidos'] ?? ''}'
        .trim();
    String especialidad = data['especialidad'] ?? 'Medicina General';
    String cedula = data['cedula'] ?? 'S/N';

    // --- EXTRAEMOS LA LISTA DE CONSULTORIOS ---
    List<dynamic> consultorios = data['consultorios'] ?? [];

    Map<String, dynamic> currentClinic =
        consultorios.isNotEmpty && _selectedClinicIndex < consultorios.length
        ? consultorios[_selectedClinicIndex]
        : {};

    // --- VARIABLES DINÁMICAS ---
    String direccionActiva =
        currentClinic['direccion'] ?? 'Dirección por confirmar';
    String telefonoActivo = currentClinic['telefono'] ?? '';
    String whatsappActivo = currentClinic['whatsapp'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: const CustomAppBar(), // <-- LA LÍNEA MÁGICA
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBreadcrumbs(especialidad, nombreCompleto, doctorId),
                const SizedBox(height: 20),

                // PASAMOS EL TELÉFONO Y WHATSAPP ACTIVO A LA TARJETA
                _buildDoctorMainCard(
                  doctorId, // Añadido para los favoritos
                  nombreCompleto,
                  especialidad,
                  cedula,
                  telefonoActivo,
                  whatsappActivo,
                ),
                const SizedBox(height: 40),

                // --- PESTAÑAS (TABS) DE LOS CONSULTORIOS ---
                _buildClinicTabs(consultorios),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _buildLeftColumn(currentClinic)),
                    const SizedBox(width: 30),
                    Expanded(
                      flex: 4,
                      child: _buildRightColumn(direccionActiva),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
                _buildBottomCTA(nombreCompleto, whatsappActivo, telefonoActivo),
                const SizedBox(height: 40),
                _buildFooterBadges(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET DE PESTAÑAS (TABS) ---
  Widget _buildClinicTabs(List<dynamic> consultorios) {
    if (consultorios.isEmpty || consultorios.length == 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: consultorios.asMap().entries.map((entry) {
            int index = entry.key;
            String nombre = entry.value['nombre'] ?? 'Consultorio ${index + 1}';
            bool isSelected = _selectedClinicIndex == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedClinicIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 15),
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      nombre,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs(
    String especialidad,
    String nombre,
    String doctorId,
  ) {
    // Generamos el link único de este doctor
    String dominio = "https://medicosdurango.com";
    String urlPerfil = "$dominio/#/perfil?id=$doctorId";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Inicio  >  Médicos  >  $especialidad  >  $nombre',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        Row(
          children: [
            const Text(
              'Compartir perfil: ',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(width: 10),

            // --- BOTÓN DE WHATSAPP ---
            InkWell(
              onTap: () async {
                String mensaje = Uri.encodeComponent(
                  'Te recomiendo a este especialista en Médicos durango: $urlPerfil',
                );
                final Uri url = Uri.parse('https://wa.me/?text=$mensaje');
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
              child: _iconButton(
                const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  size: 14,
                  color: Colors.green,
                ),
                Colors.green,
              ),
            ),
            const SizedBox(width: 5),

            // --- BOTÓN DE FACEBOOK ---
            InkWell(
              onTap: () async {
                final Uri url = Uri.parse(
                  'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(urlPerfil)}',
                );
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
              child: _iconButton(
                const FaIcon(
                  FontAwesomeIcons.facebook,
                  size: 14,
                  color: Colors.blue,
                ),
                Colors.blue,
              ),
            ),
            const SizedBox(width: 5),

            // --- BOTÓN DE COPIAR LINK ---
            InkWell(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: urlPerfil));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '¡Enlace del perfil copiado al portapapeles!',
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              },
              child: _iconButton(
                Icon(Icons.link, size: 14, color: Colors.grey.shade600),
                Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _iconButton(Widget iconWidget, Color color) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: color.withOpacity(0.1),
      child: iconWidget,
    );
  }

  Widget _buildDoctorMainCard(
    String doctorId,
    String nombre,
    String especialidad,
    String cedula,
    String telActivo,
    String waActivo,
  ) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  size: 100,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'Doctor verificado',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 30),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // FUNCIONALIDAD DE FAVORITOS
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseAuth.instance.currentUser != null
                          ? FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .get()
                          : null,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData &&
                            snapshot.data!.exists) {
                          String rol = snapshot.data!.get('rol') ?? '';
                          if (rol == 'paciente') {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: InkWell(
                                onTap: () async {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user != null) {
                                    await FirebaseFirestore.instance
                                        .collection('usuarios')
                                        .doc(user.uid)
                                        .collection('favoritos')
                                        .doc(doctorId)
                                        .set({
                                          'nombre': nombre,
                                          'especialidad': especialidad,
                                          'fecha_guardado':
                                              FieldValue.serverTimestamp(),
                                        });

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            '¡Doctor guardado en tus favoritos!',
                                          ),
                                          backgroundColor: Colors.pink,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Icon(
                                  Icons.favorite_border,
                                  color: Colors.blue,
                                ),
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1F36),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  especialidad,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Especialista de confianza en la región',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 15),
                const Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    SizedBox(width: 5),
                    Text(
                      'Nuevo Perfil',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        'Enviar mensaje',
                        const FaIcon(
                          FontAwesomeIcons.whatsapp,
                          color: Colors.white,
                          size: 18,
                        ),
                        Colors.green.shade600,
                        () => _abrirWhatsApp(waActivo),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _llamarTelefono(telActivo),
                        icon: const Icon(Icons.phone, color: Colors.blue),
                        label: const Text(
                          'Llamar',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Divider(color: Colors.black12),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem(
                      Icons.medical_information,
                      'Cédula Profesional',
                      cedula,
                    ),
                    _statItem(
                      Icons.location_city,
                      'Atención',
                      'En Consultorio',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modificamos el ActionButton para que reciba el onTap
  Widget _actionButton(
    String text,
    Widget iconWidget,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: iconWidget,
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade200, size: 30),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  // --- COLUMNA IZQUIERDA DINÁMICA ---
  Widget _buildLeftColumn(Map<String, dynamic> clinic) {
    if (clinic.isEmpty)
      return _contentCard(
        'Información del consultorio',
        const Text(
          'No hay consultorios registrados.',
          style: TextStyle(color: Colors.grey),
        ),
      );

    String horarioFormateado = _formatearHorario(clinic['horario']);
    String telefono = clinic['telefono']?.toString().isNotEmpty == true
        ? clinic['telefono']
        : 'No disponible';
    String whatsapp = clinic['whatsapp']?.toString().isNotEmpty == true
        ? clinic['whatsapp']
        : '';

    return _contentCard(
      'Información del consultorio',
      Column(
        children: [
          _infoRow(
            const Icon(Icons.access_time, color: Colors.blue, size: 20),
            'Horarios de atención',
            horarioFormateado,
          ),
          const SizedBox(height: 15),
          _infoRow(
            const Icon(Icons.phone, color: Colors.blue, size: 20),
            'Teléfono',
            telefono,
          ),
          if (whatsapp.isNotEmpty) ...[
            const SizedBox(height: 15),
            _infoRow(
              const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: Colors.green,
                size: 20,
              ),
              'WhatsApp',
              whatsapp,
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(Widget iconWidget, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        iconWidget,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- COLUMNA DERECHA DINÁMICA ---
  Widget _buildRightColumn(String direccion) {
    return _contentCard(
      'Ubicación',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  direccion,
                  style: const TextStyle(color: Colors.grey, height: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          OutlinedButton.icon(
            onPressed: () =>
                _abrirGoogleMaps(direccion), // <-- AHORA RESPONDE A CLIC
            icon: const Icon(Icons.map, size: 16),
            label: const Text('Ver mapa'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentCard(String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 20),
          ],
          content,
        ],
      ),
    );
  }

  Widget _buildBottomCTA(
    String nombre,
    String whatsappActivo,
    String telefonoActivo,
  ) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, color: Colors.white, size: 50),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Listo para agendar tu cita?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Contacta al $nombre de\nmanera rápida y segura.',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _abrirWhatsApp(whatsappActivo),
                icon: const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'Enviar WhatsApp',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              ElevatedButton(
                onPressed: () => _llamarTelefono(telefonoActivo),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Llamar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _footerBadge(
          Icons.verified_user_outlined,
          'Perfiles verificados',
          'Médicos certificados',
        ),
        _footerBadge(
          Icons.check_circle_outline,
          'Información confiable',
          'Datos actualizados',
        ),
        _footerBadge(
          Icons.star_border,
          'Opiniones reales',
          'Pacientes como tú',
        ),
        _footerBadge(
          Icons.support_agent,
          'Atención personalizada',
          'Estamos para ayudarte',
        ),
      ],
    );
  }

  Widget _footerBadge(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 30),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
