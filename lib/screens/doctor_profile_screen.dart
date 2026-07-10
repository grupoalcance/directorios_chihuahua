import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/services.dart';
import 'blog_detail_screen.dart';
import 'login_screen.dart';
import '../widgets/custom_app_bar.dart';

class DoctorProfileScreen extends StatefulWidget {
  final Map<String, dynamic> doctorData;

  const DoctorProfileScreen({super.key, required this.doctorData});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  int _selectedClinicIndex = 0;

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
        bool tieneTurno2 = config['tieneTurno2'] ?? false;

        if (abierto) {
          String turno1 = '${config['de']} - ${config['a']}';
          if (tieneTurno2) {
            String turno2 = '${config['de2']} - ${config['a2']}';
            resultado += '$dia: $turno1  y  $turno2\n';
          } else {
            resultado += '$dia: $turno1\n';
          }
        } else {
          resultado += '$dia: Cerrado\n';
        }
      }
    }
    return resultado.trim();
  }

  Future<void> _llamarTelefono(String telefono) async {
    if (telefono.isEmpty) return;
    String cleanPhone = telefono.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri url = Uri.parse('tel:$cleanPhone');
    if (!await launchUrl(url))
      debugPrint('No se pudo abrir la app de teléfono');
  }

  Future<void> _abrirWhatsApp(String whatsapp) async {
    if (whatsapp.isEmpty) return;
    String cleanPhone = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    if (!cleanPhone.startsWith('52') && cleanPhone.length == 10)
      cleanPhone = '52$cleanPhone';
    String mensaje = Uri.encodeComponent(
      'Hola, vi su perfil en médicoslaguna.com y me gustaría pedir información o agendar una cita.',
    );
    final Uri url = Uri.parse('https://wa.me/$cleanPhone?text=$mensaje');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication))
      debugPrint('No se pudo abrir WhatsApp');
  }

  Future<void> _abrirGoogleMaps(String direccion) async {
    if (direccion.isEmpty) return;
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(direccion)}',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication))
      debugPrint('No se pudo abrir Google Maps');
  }

  Widget _buildMapIframe(String direccion) {
    if (direccion.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Icon(Icons.map, size: 30, color: Colors.grey),
        ),
      );
    }
    final String viewId = 'map-iframe-${direccion.hashCode}';

    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final html.IFrameElement iframe = html.IFrameElement()
        ..width = '100%'
        ..height = '100%'
        ..src =
            'https://maps.google.com/maps?q=${Uri.encodeComponent(direccion)}&output=embed'
        ..style.border = 'none'
        ..style.borderRadius = '10px';
      return iframe;
    });

    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: HtmlElementView(viewType: viewId),
      ),
    );
  }

  Future<void> _abrirLink(String link) async {
    if (link.isEmpty) return;
    String urlValida = link.trim();
    if (!urlValida.startsWith('http://') && !urlValida.startsWith('https://')) {
      urlValida = 'https://$urlValida';
    }
    final Uri url = Uri.parse(urlValida);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication))
      debugPrint('No se pudo abrir el enlace: $urlValida');
  }

  // =========================================================================
  // 💬 LÓGICA DE DIÁLOGOS DE RESEÑA ACTUALIZADA (NUEVA VENTANA EMERGENTE)
  // =========================================================================
  void _mostrarDialogoResena(String doctorId) {
    final user = FirebaseAuth.instance.currentUser;

    // 👇 REEMPLAZADO: Si no hay sesión, se muestra un AlertDialog premium en vez del SnackBar/Franja naranja 👇
    if (user == null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(Icons.lock_outline_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Text(
                  'Acceso requerido',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              'Debes iniciar sesión para dejar una opinión o calificar tu experiencia.',
              style: TextStyle(color: Color(0xFF475569), fontSize: 14.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo emergente
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const LoginScreen(vieneDesdeOpinio: true),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    int calificacionSeleccionada = 5;
    final TextEditingController comentarioCtrl = TextEditingController();
    bool guardando = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                'Califica tu experiencia',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '¿Cuántas estrellas le das?',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {
                          setStateDialog(() {
                            calificacionSeleccionada = index + 1;
                          });
                        },
                        icon: Icon(
                          index < calificacionSeleccionada
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 35,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: comentarioCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Cuéntanos cómo te fue (opcional)...',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          setStateDialog(() => guardando = true);

                          String nombrePaciente = 'Paciente Anónimo';
                          DocumentSnapshot userDoc = await FirebaseFirestore
                              .instance
                              .collection('usuarios')
                              .doc(user.uid)
                              .get();
                          if (userDoc.exists) {
                            final userData =
                                userDoc.data() as Map<String, dynamic>? ?? {};
                            String pNombre = userData['nombre'] ?? '';
                            String pApellidos = userData['apellidos'] ?? '';
                            nombrePaciente = '$pNombre $pApellidos'.trim();
                            if (nombrePaciente.isEmpty)
                              nombrePaciente = 'Paciente Anónimo';
                          }

                          await FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(doctorId)
                              .collection('resenas')
                              .add({
                                'paciente_id': user.uid,
                                'nombre_paciente': nombrePaciente,
                                'calificacion': calificacionSeleccionada,
                                'comentario': comentarioCtrl.text.trim(),
                                'fecha': FieldValue.serverTimestamp(),
                              });

                          await FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(doctorId)
                              .update({
                                'reseñas_count': FieldValue.increment(1),
                              })
                              .catchError(
                                (e) =>
                                    debugPrint("Error en sensor Reseñas: $e"),
                              );

                          setStateDialog(() => guardando = false);
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('¡Gracias por tu opinión!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: guardando
                      ? const SizedBox(
                          height: 15,
                          width: 15,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Publicar',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    Map<String, dynamic> data = widget.doctorData;

    String doctorId = data['uid'] ?? '';
    String nombreCompleto = '${data['nombre'] ?? ''} ${data['apellidos'] ?? ''}'
        .trim();
    String honestyName = nombreCompleto.isNotEmpty
        ? nombreCompleto
        : 'Especialista';
    String especialidad = data['especialidad'] ?? 'Especialista';
    String cedula = data['cedula'] ?? 'S/N';
    String descripcion =
        data['descripcion'] ??
        'Especialista con amplia experiencia en diagnóstico y tratamiento.';
    String experiencia = data['experiencia'] ?? '--';
    String costo = data['costo_consulta'] ?? 'Consultar';

    String? fotoUrl = data['foto_url'];
    List<dynamic> servicios = data['servicios'] ?? [];
    List<dynamic> metodos = data['metodos_pago'] ?? [];
    List<dynamic> aseguradoras = data['aseguradoras'] ?? [];

    String fb = data['link_facebook'] ?? '';
    String ig = data['link_instagram'] ?? '';
    String tk = data['link_tiktok'] ?? '';
    String xTw = data['link_x'] ?? '';
    String web = data['link_web'] ?? '';

    List<dynamic> consultorios = data['consultorios'] ?? [];
    Map<String, dynamic> currentClinic =
        consultorios.isNotEmpty && _selectedClinicIndex < consultorios.length
        ? consultorios[_selectedClinicIndex]
        : {};

    String direccionActiva =
        currentClinic['direccion'] ?? 'Dirección por confirmar';
    String telefonoActivo = currentClinic['telefono'] ?? '';
    String whatsappActivo = currentClinic['whatsapp'] ?? '';
    String ciudadActiva = currentClinic['ciudad'] ?? 'Torreón, Coahuila';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBreadcrumbs(especialidad, honestyName, doctorId),
                const SizedBox(height: 20),

                _buildDoctorMainCard(
                  doctorId,
                  honestyName,
                  especialidad,
                  cedula,
                  experiencia,
                  telefonoActivo,
                  whatsappActivo,
                  fotoUrl,
                  ciudadActiva,
                ),
                const SizedBox(height: 40),
                _buildClinicTabs(consultorios),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _buildLeftColumn(
                        descripcion,
                        currentClinic,
                        metodos,
                        aseguradoras,
                        servicios,
                      ),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      flex: 4,
                      child: _buildRightColumn(
                        direccionActiva,
                        costo,
                        fb,
                        ig,
                        tk,
                        xTw,
                        web,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
                _buildReviewsCardReal(doctorId),
                const SizedBox(height: 40),

                _buildDoctorBlogSection(screenWidth, honestyName, doctorId),

                _buildBottomCTA(honestyName, whatsappActivo, telefonoActivo),
                const SizedBox(height: 40),
                _buildFooterBadges(),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
            String nombre = entry.value['nombre'] ?? 'Ubicación ${index + 1}';
            bool isSelected = _selectedClinicIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedClinicIndex = index),
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
    String dominio = "https://medicoslaguna.com";
    String urlPerfil = "$dominio/#/perfil?id=$doctorId";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Inicio  >  Directorio  >  $especialidad  >  $nombre',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        Row(
          children: [
            const Text(
              'Compartir perfil: ',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () async {
                String mensaje = Uri.encodeComponent(
                  'Te recomiendo a este especialista en Médicos Laguna: $urlPerfil',
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
    String experiencia,
    String telActivo,
    String waActivo,
    String? fotoUrl,
    String ciudad,
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
              WidgetAvatar(fotoUrl: fotoUrl),
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
                      'Verificado',
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
                          final mapData =
                              snapshot.data!.data() as Map<String, dynamic>? ??
                              {};
                          String rol = mapData.containsKey('rol')
                              ? mapData['rol'].toString()
                              : '';

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
                                            '¡Guardado en tus favoritos!',
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
                  'Alta especialidad y trato humanitario.',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 15),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(doctorId)
                      .collection('resenas')
                      .snapshots(),
                  builder: (context, snapshot) {
                    double promedio = 0.0;
                    int total = snapshot.data?.docs.length ?? 0;

                    if (total > 0) {
                      double suma = 0;
                      for (var doc in snapshot.data!.docs) {
                        final resData =
                            doc.data() as Map<String, dynamic>? ?? {};
                        suma += (resData.containsKey('calificacion')
                            ? resData['calificacion']
                            : 5);
                      }
                      promedio = suma / total;
                    }

                    return Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 5),
                        Text(
                          total == 0 ? 'Nuevo' : promedio.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          ' ($total opiniones)   •   ',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.grey,
                          size: 18,
                        ),
                        Text(
                          ' $ciudad',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    );
                  },
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
                        Colors.green,
                        () {
                          if (doctorId.isNotEmpty) {
                            String fechaHoy =
                                "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
                            FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(doctorId)
                                .update({
                                  'clics_wa': FieldValue.increment(1),
                                  'ultimo_contacto': fechaHoy,
                                })
                                .catchError(
                                  (e) => debugPrint("Error en sensor WA: $e"),
                                );
                          }
                          _abrirWhatsApp(waActivo);
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _llamarTelefono(telActivo),
                        icon: const Icon(Icons.phone, color: Colors.blue),
                        label: const Text(
                          'Llamar',
                          style: TextStyle(color: Colors.blue),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.blue),
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
                      Icons.calendar_month,
                      experiencia,
                      'Años de experiencia',
                    ),
                    _statItem(
                      Icons.medical_information,
                      'Cédula / Permiso',
                      cedula,
                    ),
                    _statItem(
                      Icons.people_outline,
                      '500+',
                      'Pacientes atendidos',
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

  Widget _buildLeftColumn(
    String descripcion,
    Map<String, dynamic> clinic,
    List<dynamic> metodos,
    List<dynamic> aseguradoras,
    List<dynamic> servicios,
  ) {
    String horarioFormateado = clinic.isNotEmpty
        ? _formatearHorario(clinic['horario'])
        : 'Previa Cita';
    String telefono =
        clinic.isNotEmpty && clinic['telefono']?.toString().isNotEmpty == true
        ? clinic['telefono']
        : 'No disponible';
    String whatsapp =
        clinic.isNotEmpty && clinic['whatsapp']?.toString().isNotEmpty == true
        ? clinic['whatsapp']
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _contentCard(
          'Acerca de',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                descripcion.isEmpty
                    ? 'Sin descripción disponible.'
                    : descripcion,
                style: const TextStyle(color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 20),
              if (servicios.isEmpty)
                const Text(
                  'No hay servicios destacados registrados.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: servicios.map((s) => _tag(s.toString())).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _contentCard(
                'Información de la sucursal',
                Column(
                  children: [
                    _infoRow(
                      const Icon(
                        Icons.access_time,
                        color: Colors.blue,
                        size: 20,
                      ),
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
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _contentCard(
                'Métodos de pago y Seguros',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (metodos.isEmpty)
                      const Text(
                        'Pago en sucursal',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ...metodos
                        .map(
                          (m) => _paymentRow(Icons.check_circle, m.toString()),
                        )
                        .toList(),
                    const SizedBox(height: 20),
                    const Text(
                      'Aseguradoras o Convenios',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (aseguradoras.isEmpty)
                      const Text(
                        'Sin convenios registrados',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: aseguradoras
                          .map(
                            (a) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              color: Colors.blue.shade900,
                              child: Text(
                                a.toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, color: Colors.green.shade700, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(color: Colors.green.shade800, fontSize: 12),
          ),
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

  Widget _paymentRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade700, size: 18),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildReviewsCardReal(String doctorId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(doctorId)
          .collection('resenas')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];
        double promedio = 0.0;
        int total = docs.length;
        List<int> conteoEstrellas = [0, 0, 0, 0, 0, 0];

        if (total > 0) {
          double suma = 0;
          for (var d in docs) {
            final resData = d.data() as Map<String, dynamic>? ?? {};
            int calif = resData.containsKey('calificacion')
                ? resData['calificacion']
                : 5;
            suma += calif;
            if (calif >= 1 && calif <= 5) conteoEstrellas[calif]++;
          }
          promedio = suma / total;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(35),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Opiniones de clientes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _mostrarDialogoResena(doctorId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: BorderSide(color: Colors.blue.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Escribir opinión',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              if (total == 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Sé el primero en dejar una opinión sobre este servicio.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 700) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 320,
                            child: _buildResumenEstrellas(
                              promedio,
                              total,
                              conteoEstrellas,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 200,
                            color: Colors.grey.shade200,
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                          ),
                          Expanded(child: _buildListaComentarios(docs)),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildResumenEstrellas(
                            promedio,
                            total,
                            conteoEstrellas,
                          ),
                          const SizedBox(height: 40),
                          const Divider(),
                          const SizedBox(height: 20),
                          _buildListaComentarios(docs),
                        ],
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResumenEstrellas(double promedio, int total, List<int> conteo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              promedio.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.bold,
                height: 1,
                color: Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < promedio.round() ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Basado en $total opiniones',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 25),
        _ratingBar('5', conteo[5] / total, conteo[5].toString()),
        _ratingBar('4', conteo[4] / total, conteo[4].toString()),
        _ratingBar('3', conteo[3] / total, conteo[3].toString()),
        _ratingBar('2', conteo[2] / total, conteo[2].toString()),
        _ratingBar('1', conteo[1] / total, conteo[1].toString()),
      ],
    );
  }

  Widget _buildListaComentarios(List<QueryDocumentSnapshot> docs) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      separatorBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 15),
        child: Divider(color: Colors.black12),
      ),
      itemBuilder: (context, index) {
        var r = docs[index].data() as Map<String, dynamic>;

        String nombrePx = r['nombre_paciente'] ?? 'Cliente';
        String iniciales = nombrePx.isNotEmpty
            ? nombrePx[0].toUpperCase()
            : 'C';
        int calif = r.containsKey('calificacion') ? r['calificacion'] : 5;
        String comentario = r['comentario'] ?? '';

        String fechaStr = 'Recientemente';
        if (r['fecha'] != null) {
          DateTime fechaReal = (r['fecha'] as Timestamp).toDate();
          fechaStr = '${fechaReal.day}/${fechaReal.month}/${fechaReal.year}';
        }

        return _reviewItemReal(
          iniciales,
          Colors.blue.shade50,
          nombrePx,
          calif,
          comentario,
          fechaStr,
        );
      },
    );
  }

  Widget _ratingBar(String star, double percent, String count) {
    if (percent.isNaN) percent = 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            star,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.star, color: Colors.amber, size: 12),
          const SizedBox(width: 15),
          Expanded(
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey.shade200,
              color: Colors.amber,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 15),
          SizedBox(
            width: 25,
            child: Text(
              count,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewItemReal(
    String initials,
    Color color,
    String name,
    int calificacion,
    String comment,
    String date,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color,
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < calificacion
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  $date',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRightColumn(
    String direccion,
    String costo,
    String fb,
    String ig,
    String tk,
    String xTw,
    String web,
  ) {
    return Column(
      children: [
        _contentCard(
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
                onPressed: () => _abrirGoogleMaps(direccion),
                icon: const Icon(Icons.map, size: 16),
                label: const Text('Ver en Google Maps'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
              const SizedBox(height: 15),
              _buildMapIframe(direccion),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _contentCard(
          '',
          Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade600,
                    child: const Icon(Icons.attach_money, color: Colors.white),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Costo de atención',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        costo.isNotEmpty ? costo : 'Consultar',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _contentCard(
          'Redes Sociales',
          Column(
            children: [
              if (fb.isEmpty &&
                  ig.isEmpty &&
                  tk.isEmpty &&
                  xTw.isEmpty &&
                  web.isEmpty)
                const Text(
                  'No hay redes sociales enlazadas.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              if (fb.isNotEmpty)
                _socialRow(
                  const FaIcon(
                    FontAwesomeIcons.facebook,
                    color: Colors.blue,
                    size: 18,
                  ),
                  Colors.blue,
                  'Facebook',
                  () => _abrirLink(fb),
                ),
              if (ig.isNotEmpty)
                _socialRow(
                  const FaIcon(
                    FontAwesomeIcons.instagram,
                    color: Colors.pink,
                    size: 18,
                  ),
                  Colors.pink,
                  'Instagram',
                  () => _abrirLink(ig),
                ),
              if (tk.isNotEmpty)
                _socialRow(
                  const FaIcon(
                    FontAwesomeIcons.tiktok,
                    color: Colors.black,
                    size: 18,
                  ),
                  Colors.black,
                  'TikTok',
                  () => _abrirLink(tk),
                ),
              if (xTw.isNotEmpty)
                _socialRow(
                  const FaIcon(
                    FontAwesomeIcons.xTwitter,
                    color: Colors.black,
                    size: 18,
                  ),
                  Colors.black,
                  'X (Twitter)',
                  () => _abrirLink(xTw),
                ),
              if (web.isNotEmpty)
                _socialRow(
                  const FaIcon(
                    FontAwesomeIcons.globe,
                    color: Colors.blueGrey,
                    size: 18,
                  ),
                  Colors.blueGrey,
                  'Sitio Web',
                  () => _abrirLink(web),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _socialRow(
    Widget iconWidget,
    Color color,
    String text,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.1),
              child: iconWidget,
            ),
            const SizedBox(width: 15),
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey.shade400,
            ),
          ],
        ),
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

  Widget _buildDoctorBlogSection(double width, String nombre, String doctorId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(doctorId)
          .collection('mis_blogs')
          .orderBy('fecha', descending: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const SizedBox.shrink();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const SizedBox.shrink();

        List<dynamic> blogsFirebase = snapshot.data!.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Novedades y Artículos de $nombre',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1F36),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 350,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: blogsFirebase.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 20),
                  itemBuilder: (context, index) {
                    var post = blogsFirebase[index];
                    String? imgData = post['img'];

                    return Container(
                      width: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                              child: (imgData != null && imgData.isNotEmpty)
                                  ? (imgData.startsWith('http')
                                        ? Image.network(
                                            imgData,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.memory(
                                            base64Decode(imgData),
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ))
                                  : Image.network(
                                      'https://via.placeholder.com/400x300',
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post['title'] ?? 'Sin título',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  post['desc'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              BlogDetailScreen(
                                                blogPost: post,
                                                doctorName: nombre,
                                                allBlogs: blogsFirebase,
                                                doctorData: widget.doctorData,
                                              ),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Colors.blue,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      'Leer más',
                                      style: TextStyle(fontSize: 12),
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomCTA(
    String nombre,
    String whatsappActivo,
    String telefonoActivo,
  ) {
    String doctorId = widget.doctorData['uid'] ?? '';

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
                    'Contacta a $nombre de\nmanera rápida y segura.',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  if (doctorId.isNotEmpty) {
                    String fechaHoy =
                        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
                    FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(doctorId)
                        .update({
                          'clics_wa': FieldValue.increment(1),
                          'ultimo_contacto': fechaHoy,
                        })
                        .catchError(
                          (e) => debugPrint("Error en sensor WA: $e"),
                        );
                  }
                  _abrirWhatsApp(whatsappActivo);
                },
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
                    vertical: 18,
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
          'Especialistas certificados',
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

class WidgetAvatar extends StatelessWidget {
  final String? fotoUrl;
  const WidgetAvatar({Key? key, this.fotoUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (fotoUrl != null && fotoUrl!.isNotEmpty) {
      if (fotoUrl!.startsWith('http')) {
        return Image.network(
          fotoUrl!,
          width: 180,
          height: 180,
          fit: BoxFit.cover,
        );
      } else {
        return Image.memory(
          base64Decode(fotoUrl!),
          width: 180,
          height: 180,
          fit: BoxFit.cover,
        );
      }
    }
    return Container(
      width: 180,
      height: 180,
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.person_outline_rounded,
        size: 65,
        color: Color(0xFF64748B),
      ),
    );
  }
}
