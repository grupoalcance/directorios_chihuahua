import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
// IMPORTAMOS LA BARRA Y LAS OTRAS PANTALLAS CON SUS RUTAS
import '../widgets/custom_app_bar.dart';
import 'login_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  final String? adminViewUid;
  const DoctorDashboardScreen({super.key, this.adminViewUid});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // --- ATAJO PARA SABER A QUIÉN ESTAMOS EDITANDO ---
  String? get targetUid =>
      widget.adminViewUid ?? FirebaseAuth.instance.currentUser?.uid;

  // Controladores básicos
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _apellidosCtrl = TextEditingController();
  final TextEditingController _especialidadCtrl = TextEditingController();
  final TextEditingController _cedulaCtrl = TextEditingController();

  // Controladores Pro
  final TextEditingController _costoCtrl = TextEditingController();
  final TextEditingController _experienciaCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();

  // Redes Sociales Pro
  final TextEditingController _facebookCtrl = TextEditingController();
  final TextEditingController _instagramCtrl = TextEditingController();
  final TextEditingController _tiktokCtrl = TextEditingController();
  final TextEditingController _xCtrl = TextEditingController();
  final TextEditingController _webCtrl = TextEditingController();

  // --- Controladores para crear Blogs ---
  final TextEditingController _blogTituloCtrl = TextEditingController();
  final TextEditingController _blogDescCtrl = TextEditingController();
  String? _blogImgBase64;
  List<Map<String, dynamic>> blogs = [];

  // --- LÓGICA DE MÚLTIPLES CONSULTORIOS Y FOTO ---
  List<Map<String, dynamic>> consultorios = [];
  String? _fotoUrl;

  // Lista de servicios/etiquetas
  List<dynamic> servicios = [];
  final TextEditingController _servicioCtrl = TextEditingController();

  final List<String> _listaCiudades = [
    'Durango, Coah.',
    'Gómez Palacio, Dgo.',
    'Lerdo, Dgo.',
    'Matamoros, Coah.',
    'Francisco I. Madero, Coah.',
    'San Pedro, Coah.',
  ];

  final List<String> diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  final List<String> horasDisponibles = [
    '07:00 AM',
    '07:30 AM',
    '08:00 AM',
    '08:30 AM',
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '12:30 PM',
    '01:00 PM',
    '01:30 PM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
    '05:30 PM',
    '06:00 PM',
    '06:30 PM',
    '07:00 PM',
    '07:30 PM',
    '08:00 PM',
    '08:30 PM',
    '09:00 PM',
    '09:30 PM',
    '10:00 PM',
  ];

  Map<String, bool> metodosPago = {
    'Efectivo': false,
    'Tarjeta de crédito / débito': false,
    'Transferencia bancaria': false,
  };

  Map<String, bool> aseguradoras = {
    'GNP': false,
    'AXA': false,
    'MetLife': false,
    'Mapfre': false,
    'Seguros Monterrey': false,
  };

  bool _isLoading = true;
  Map<String, dynamic>? userData;
  bool isPro = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDoctorData();
  }

  Future<void> _subirImagen() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 40,
    );

    if (image != null && targetUid != null) {
      setState(() => _isLoading = true);

      try {
        Uint8List imageBytes = await image.readAsBytes();
        String base64Image = base64Encode(imageBytes);

        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(targetUid) // <-- Usamos targetUid
            .update({'foto_url': base64Image});

        setState(() {
          _fotoUrl = base64Image;
          _isLoading = false;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Foto de perfil actualizada!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- SELECCIONAR IMAGEN DEL BLOG CON COMPRESIÓN AGRESIVA ---
  Future<void> _seleccionarImagenBlog() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 400,
      imageQuality: 30, // Calidad baja para que no pese nada
    );

    if (image != null) {
      try {
        Uint8List imageBytes = await image.readAsBytes();

        // Bloqueo de seguridad: Si pesa más de 500KB no la dejamos pasar
        if (imageBytes.lengthInBytes > 500000) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La imagen es demasiado pesada. Usa una foto más pequeña.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _blogImgBase64 = base64Encode(imageBytes);
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al leer la imagen.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 👇 ACTUALIZADO PARA CREAR NUEVO CONSULTORIO CON ESTRUCTURA DE DOBLE TURNO
  void _agregarNuevoConsultorio() {
    setState(() {
      consultorios.add({
        'nombre': 'Consultorio ${consultorios.length + 1}',
        'calle_numero': '',
        'ciudad': 'Durango, Coah.',
        'direccion': '',
        'telefono': '',
        'whatsapp': '',
        'horario': {
          'Lunes': {
            'abierto': true,
            'de': '09:00 AM',
            'a': '05:00 PM',
            'tieneTurno2': false,
            'de2': '05:00 PM',
            'a2': '08:00 PM',
          },
          'Martes': {
            'abierto': true,
            'de': '09:00 AM',
            'a': '05:00 PM',
            'tieneTurno2': false,
            'de2': '05:00 PM',
            'a2': '08:00 PM',
          },
          'Miércoles': {
            'abierto': true,
            'de': '09:00 AM',
            'a': '05:00 PM',
            'tieneTurno2': false,
            'de2': '05:00 PM',
            'a2': '08:00 PM',
          },
          'Jueves': {
            'abierto': true,
            'de': '09:00 AM',
            'a': '05:00 PM',
            'tieneTurno2': false,
            'de2': '05:00 PM',
            'a2': '08:00 PM',
          },
          'Viernes': {
            'abierto': true,
            'de': '09:00 AM',
            'a': '05:00 PM',
            'tieneTurno2': false,
            'de2': '05:00 PM',
            'a2': '08:00 PM',
          },
          'Sábado': {
            'abierto': false,
            'de': '09:00 AM',
            'a': '02:00 PM',
            'tieneTurno2': false,
            'de2': '04:00 PM',
            'a2': '06:00 PM',
          },
          'Domingo': {
            'abierto': false,
            'de': '09:00 AM',
            'a': '02:00 PM',
            'tieneTurno2': false,
            'de2': '04:00 PM',
            'a2': '06:00 PM',
          },
        },
      });
    });
  }

  Future<void> _loadDoctorData() async {
    if (targetUid != null) {
      // 1. Cargamos los datos principales del doctor usando targetUid
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(targetUid) // <-- Usamos targetUid
          .get();

      if (doc.exists) {
        // 2. Cargamos los blogs desde la NUEVA Sub-colección
        QuerySnapshot blogsSnapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(targetUid) // <-- Usamos targetUid
            .collection('mis_blogs')
            .orderBy('fecha', descending: true)
            .get();

        setState(() {
          userData = doc.data() as Map<String, dynamic>;
          isPro = userData?['tipo_perfil'] == 'pro';
          _fotoUrl = userData?['foto_url'];
          servicios = userData?['servicios'] ?? [];

          // Guardamos los blogs traídos de la sub-colección
          blogs = blogsSnapshot.docs.map((blogDoc) {
            var data = blogDoc.data() as Map<String, dynamic>;
            data['id'] = blogDoc
                .id; // Guardamos el ID del documento para poder borrarlo después
            return data;
          }).toList();

          _nombreCtrl.text = userData?['nombre'] ?? '';
          _apellidosCtrl.text = userData?['apellidos'] ?? '';
          _especialidadCtrl.text = userData?['especialidad'] ?? '';
          _cedulaCtrl.text = userData?['cedula'] ?? '';

          if (userData?['consultorios'] != null) {
            consultorios = List<Map<String, dynamic>>.from(
              userData?['consultorios'].map((item) {
                var map = Map<String, dynamic>.from(item);

                // Asegurar que exista la estructura del segundo turno si es un doc viejo
                if (map['horario'] != null) {
                  Map<String, dynamic> horario = map['horario'];
                  for (String dia in diasSemana) {
                    if (horario[dia] != null) {
                      horario[dia]['tieneTurno2'] =
                          horario[dia]['tieneTurno2'] ?? false;
                      horario[dia]['de2'] = horario[dia]['de2'] ?? '05:00 PM';
                      horario[dia]['a2'] = horario[dia]['a2'] ?? '08:00 PM';
                    }
                  }
                }

                if (map['calle_numero'] == null || map['ciudad'] == null) {
                  String dirAntigua = map['direccion'] ?? '';
                  String ciudadAsignada = 'Durango, Coah.'; // Por defecto
                  String calleAsignada = dirAntigua;

                  for (String ciudad in _listaCiudades) {
                    if (dirAntigua.endsWith(ciudad)) {
                      ciudadAsignada = ciudad;
                      int index = dirAntigua.lastIndexOf(ciudad);
                      if (index > 0) {
                        calleAsignada = dirAntigua.substring(0, index).trim();
                        if (calleAsignada.endsWith(',')) {
                          calleAsignada = calleAsignada
                              .substring(0, calleAsignada.length - 1)
                              .trim();
                        }
                      }
                      break;
                    }
                  }
                  map['ciudad'] = ciudadAsignada;
                  map['calle_numero'] = calleAsignada;
                }
                return map;
              }),
            );
          } else {
            _agregarNuevoConsultorio();
          }

          _costoCtrl.text = userData?['costo_consulta'] ?? '';
          _experienciaCtrl.text = userData?['experiencia'] ?? '';
          _descripcionCtrl.text = userData?['descripcion'] ?? '';

          _facebookCtrl.text = userData?['link_facebook'] ?? '';
          _instagramCtrl.text = userData?['link_instagram'] ?? '';
          _tiktokCtrl.text = userData?['link_tiktok'] ?? '';
          _xCtrl.text = userData?['link_x'] ?? '';
          _webCtrl.text = userData?['link_web'] ?? '';

          List<dynamic> pagosGuardados = userData?['metodos_pago'] ?? [];
          for (var metodo in pagosGuardados) {
            if (metodosPago.containsKey(metodo)) metodosPago[metodo] = true;
          }

          List<dynamic> aseguradorasGuardadas = userData?['aseguradoras'] ?? [];
          for (var ase in aseguradorasGuardadas) {
            if (aseguradoras.containsKey(ase)) aseguradoras[ase] = true;
          }

          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveData() async {
    if (targetUid == null) return;
    setState(() => _isLoading = true);

    try {
      List<String> pagosSeleccionados = [];
      metodosPago.forEach((key, value) {
        if (value) pagosSeleccionados.add(key);
      });

      List<String> aseguradorasSeleccionadas = [];
      aseguradoras.forEach((key, value) {
        if (value) aseguradorasSeleccionadas.add(key);
      });

      for (var c in consultorios) {
        c['direccion'] = '${c['calle_numero']}, ${c['ciudad']}';
      }

      Map<String, dynamic> datosActualizados = {
        'nombre': _nombreCtrl.text,
        'apellidos': _apellidosCtrl.text,
        'especialidad': _especialidadCtrl.text,
        'cedula': _cedulaCtrl.text,
        'consultorios': consultorios,
        'servicios': servicios,
      };

      if (isPro) {
        datosActualizados.addAll({
          'descripcion': _descripcionCtrl.text,
          'costo_consulta': _costoCtrl.text,
          'experiencia': _experienciaCtrl.text,
          'link_facebook': _facebookCtrl.text,
          'link_instagram': _instagramCtrl.text,
          'link_tiktok': _tiktokCtrl.text,
          'link_x': _xCtrl.text,
          'link_web': _webCtrl.text,
          'metodos_pago': pagosSeleccionados,
          'aseguradoras': aseguradorasSeleccionadas,
        });
      }

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(targetUid) // <-- Usamos targetUid
          .set(datosActualizados, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Perfil actualizado con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                    tabs: const [
                      Tab(icon: Icon(Icons.bar_chart), text: 'Estadísticas'),
                      Tab(icon: Icon(Icons.edit), text: 'Editar perfil'),
                      Tab(icon: Icon(Icons.article), text: 'Blogs'),
                      Tab(icon: Icon(Icons.star_outline), text: 'Reseñas'),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height:
                        3000, // <-- Aumentamos el tamaño para los dobles turnos
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildStatsTab(),
                        _buildEditProfileTab(),
                        _buildBlogsTab(),
                        const Center(
                          child: Text('Sección de reseñas próximamente'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String iniciales =
        (_nombreCtrl.text.isNotEmpty ? _nombreCtrl.text[0] : '') +
        (_apellidosCtrl.text.isNotEmpty ? _apellidosCtrl.text[0] : '');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 100),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.teal.shade300,
                backgroundImage: (_fotoUrl != null && _fotoUrl!.isNotEmpty)
                    ? MemoryImage(base64Decode(_fotoUrl!))
                    : null,
                child: (_fotoUrl == null || _fotoUrl!.isEmpty)
                    ? Text(
                        iniciales.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              if (isPro)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _subirImagen,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 25),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👇 QUITAMOS EL "Dr(a)." QUEMADO AQUI
              Text(
                '${_nombreCtrl.text} ${_apellidosCtrl.text}'.trim(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    _especialidadCtrl.text,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const Text(
                    ' • Perfil ',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  if (isPro)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'DESTACADO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const Text(
                      'Básico',
                      style: TextStyle(color: Colors.blueGrey, fontSize: 14),
                    ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Si estás en "Modo Dios", mostramos un botón para volver al panel.
          // Si es el doctor real, mostramos el botón de cerrar sesión.
          widget.adminViewUid != null
              ? TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.blue),
                  label: const Text(
                    'Volver al Panel',
                    style: TextStyle(color: Colors.blue),
                  ),
                )
              : TextButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!mounted) return;
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Cerrar sesión',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 20,
      shrinkWrap: true,
      children: [
        _statCard(
          'Visitas al perfil',
          userData?['visitas']?.toString() ?? '0',
          Icon(
            Icons.remove_red_eye,
            color: Colors.blue.withOpacity(0.7),
            size: 40,
          ),
        ),
        _statCard(
          'Clics en WhatsApp',
          userData?['clics_wa']?.toString() ?? '0',
          FaIcon(
            FontAwesomeIcons.whatsapp,
            color: Colors.green.withOpacity(0.7),
            size: 40,
          ),
        ),
        _statCard(
          'Reseñas recibidas',
          '0',
          Icon(Icons.star, color: Colors.orange.withOpacity(0.7), size: 40),
        ),
        _statCard(
          'Último contacto WA',
          userData?['ultimo_contacto'] ?? '---',
          Icon(
            Icons.calendar_today,
            color: Colors.purple.withOpacity(0.7),
            size: 40,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, Widget iconWidget) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // --- SECCIÓN DE BLOGS ACTUALIZADA (AHORA GUARDA EN UNA SUB-COLECCIÓN) ---
  Widget _buildBlogsTab() {
    if (!isPro) {
      return const Center(
        child: Text(
          'Esta función es exclusiva para perfiles Pro.\n¡Actualiza tu plan para publicar artículos en el Blog!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agregar un nuevo artículo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const Divider(),
        const SizedBox(height: 15),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _seleccionarImagenBlog,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.grey.shade400,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _blogImgBase64 != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.memory(
                          base64Decode(_blogImgBase64!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 40,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Añadir Portada',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 20),

            Expanded(
              child: Column(
                children: [
                  _textField('Título del artículo', _blogTituloCtrl),
                  _textField(
                    'Contenido principal / Descripción',
                    _blogDescCtrl,
                    maxLines: 4,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_blogTituloCtrl.text.isEmpty ||
                            _blogDescCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Por favor llena el título y la descripción.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setState(() => _isLoading = true);

                        if (targetUid != null) {
                          try {
                            var nuevoBlog = {
                              'title': _blogTituloCtrl.text.trim(),
                              'desc': _blogDescCtrl.text.trim(),
                              'img': _blogImgBase64,
                              'fecha': FieldValue.serverTimestamp(),
                            };

                            DocumentReference docRef = await FirebaseFirestore
                                .instance
                                .collection('usuarios')
                                .doc(targetUid) // <-- Usamos targetUid
                                .collection('mis_blogs')
                                .add(nuevoBlog);

                            setState(() {
                              blogs.insert(0, {'id': docRef.id, ...nuevoBlog});
                              _blogTituloCtrl.clear();
                              _blogDescCtrl.clear();
                              _blogImgBase64 = null;
                            });

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Artículo publicado con éxito.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al publicar: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }

                        setState(() => _isLoading = false);
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Agregar Artículo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),
        const Text(
          'Tus Artículos Publicados',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const Divider(),
        const SizedBox(height: 15),

        if (blogs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Aún no has publicado ningún artículo.',
              style: TextStyle(color: Colors.grey),
            ),
          ),

        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: blogs.asMap().entries.map((entry) {
            int idx = entry.key;
            var blog = entry.value;
            return Container(
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                    ),
                    child:
                        (blog['img'] != null &&
                            blog['img'].toString().isNotEmpty)
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15),
                            ),
                            child: Image.memory(
                              base64Decode(blog['img']),
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.article,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                blog['title'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                if (targetUid != null && blog['id'] != null) {
                                  setState(() => _isLoading = true);
                                  await FirebaseFirestore.instance
                                      .collection('usuarios')
                                      .doc(targetUid) // <-- Usamos targetUid
                                      .collection('mis_blogs')
                                      .doc(blog['id'])
                                      .delete();

                                  setState(() {
                                    blogs.removeAt(idx);
                                    _isLoading = false;
                                  });
                                }
                              },
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              tooltip: 'Eliminar artículo',
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          blog['desc'] ?? '',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildEditProfileTab() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          const Text(
            'Información Básica',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _textField(
                  'Nombre (Ej: Clínica Sonrisas, Dr. Juan)',
                  _nombreCtrl,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _textField(
                  'Apellidos (Opcional si eres Clínica)',
                  _apellidosCtrl,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: _textField('Especialidad', _especialidadCtrl)),
              const SizedBox(width: 20),
              Expanded(child: _textField('Cédula Profesional', _cedulaCtrl)),
            ],
          ),
          const SizedBox(height: 40),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tus Consultorios y Horarios',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _agregarNuevoConsultorio,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar Consultorio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue,
                  elevation: 0,
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),

          ...consultorios.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> clinic = entry.value;
            return _buildConsultorioCard(index, clinic);
          }).toList(),

          const SizedBox(height: 40),

          Row(
            children: [
              const Text(
                'Información Adicional (Perfil Pro)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              if (!isPro)
                const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text(
                    '(Solo habilitado para Pro)',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(),

          _textField(
            'Sobre el doctor/clínica (Breve descripción de tu perfil)',
            _descripcionCtrl,
            enabled: isPro,
            maxLines: 3,
          ),

          const SizedBox(height: 15),
          const Text(
            'Servicios Destacados o Palabras Clave',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _textField(
                  'Ej: Cirugía Láser, Atención a Diabéticos...',
                  _servicioCtrl,
                  enabled: isPro,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: isPro
                    ? () {
                        if (_servicioCtrl.text.isNotEmpty) {
                          setState(() {
                            servicios.add(_servicioCtrl.text.trim());
                            _servicioCtrl.clear();
                          });
                        }
                      }
                    : null,
                icon: const Icon(
                  Icons.add_circle,
                  color: Colors.green,
                  size: 45,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: servicios
                .map(
                  (s) => Chip(
                    label: Text(s.toString()),
                    deleteIconColor: Colors.red,
                    onDeleted: isPro
                        ? () {
                            setState(() {
                              servicios.remove(s);
                            });
                          }
                        : null,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _textField(
                  'Costo de consulta (Ej: \$800 MXN)',
                  _costoCtrl,
                  enabled: isPro,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _textField(
                  'Años de experiencia',
                  _experienciaCtrl,
                  enabled: isPro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Métodos de Pago aceptados:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...metodosPago.keys.map((String key) {
                      return CheckboxListTile(
                        title: Text(key, style: const TextStyle(fontSize: 13)),
                        value: metodosPago[key],
                        onChanged: isPro
                            ? (bool? value) {
                                setState(() => metodosPago[key] = value!);
                              }
                            : null,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aseguradoras aceptadas:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...aseguradoras.keys.map((String key) {
                      return CheckboxListTile(
                        title: Text(key, style: const TextStyle(fontSize: 13)),
                        value: aseguradoras[key],
                        onChanged: isPro
                            ? (bool? value) {
                                setState(() => aseguradoras[key] = value!);
                              }
                            : null,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Redes Sociales y Contacto',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Expanded(
                child: _textField(
                  'Facebook (Link)',
                  _facebookCtrl,
                  enabled: isPro,
                  iconWidget: const FaIcon(
                    FontAwesomeIcons.facebook,
                    size: 18,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _textField(
                  'Instagram (Link)',
                  _instagramCtrl,
                  enabled: isPro,
                  iconWidget: const FaIcon(
                    FontAwesomeIcons.instagram,
                    size: 18,
                    color: Colors.pink,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _textField(
                  'TikTok (Link)',
                  _tiktokCtrl,
                  enabled: isPro,
                  iconWidget: const FaIcon(
                    FontAwesomeIcons.tiktok,
                    size: 18,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _textField(
                  'X / Twitter (Link)',
                  _xCtrl,
                  enabled: isPro,
                  iconWidget: const FaIcon(
                    FontAwesomeIcons.xTwitter,
                    size: 18,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          _textField(
            'Sitio Web Profesional',
            _webCtrl,
            enabled: isPro,
            iconWidget: const FaIcon(
              FontAwesomeIcons.globe,
              size: 18,
              color: Colors.blueGrey,
            ),
          ),

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _saveData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            child: const Text(
              'Guardar todos los cambios',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildConsultorioCard(int index, Map<String, dynamic> clinic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                clinic['nombre'] ?? 'Consultorio',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: 16,
                ),
              ),
              if (consultorios.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      consultorios.removeAt(index);
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 15),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: clinic['calle_numero'],
                  onChanged: (val) => consultorios[index]['calle_numero'] = val,
                  decoration: InputDecoration(
                    labelText: 'Calle, Hospital o Número',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _listaCiudades.contains(clinic['ciudad'])
                      ? clinic['ciudad']
                      : 'Durango, Coah.',
                  decoration: InputDecoration(
                    labelText: 'Ciudad',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: _listaCiudades.map((String ciudad) {
                    return DropdownMenuItem<String>(
                      value: ciudad,
                      child: Text(ciudad, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      consultorios[index]['ciudad'] = val;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: clinic['telefono'],
                  onChanged: (val) => consultorios[index]['telefono'] = val,
                  decoration: InputDecoration(
                    labelText: 'Teléfono fijo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TextFormField(
                  initialValue: clinic['whatsapp'],
                  onChanged: (val) => consultorios[index]['whatsapp'] = val,
                  decoration: InputDecoration(
                    labelText: 'WhatsApp para Citas (Opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: FaIcon(
                        FontAwesomeIcons.whatsapp,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          const Text(
            'Días y Horas de Atención:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 10),
          // 👇 AQUÍ LLAMAMOS A LA NUEVA LÓGICA DE TURNOS
          ...diasSemana.map((dia) => _buildHorarioRow(index, dia)).toList(),
        ],
      ),
    );
  }

  // 👇 LÓGICA DE DOBLE TURNO INCORPORADA 👇
  Widget _buildHorarioRow(int clinicIndex, String dia) {
    var diaData = consultorios[clinicIndex]['horario'][dia];
    bool abierto = diaData['abierto'];
    bool tieneTurno2 =
        diaData['tieneTurno2'] ?? false; // Seguro para los doctores viejos

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 140,
                child: CheckboxListTile(
                  title: Text(
                    dia,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: abierto ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  value: abierto,
                  onChanged: (val) => setState(() {
                    consultorios[clinicIndex]['horario'][dia]['abierto'] = val;
                    // Si cierras el día, apagamos automáticamente el turno 2
                    if (val == false) {
                      consultorios[clinicIndex]['horario'][dia]['tieneTurno2'] =
                          false;
                    }
                  }),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              if (abierto) ...[
                const Text(
                  'De: ',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                _timeDrop(clinicIndex, dia, 'de'),
                const SizedBox(width: 10),
                const Text(
                  'A: ',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                _timeDrop(clinicIndex, dia, 'a'),

                // BOTÓN PARA AGREGAR EL SEGUNDO TURNO
                if (!tieneTurno2)
                  TextButton.icon(
                    onPressed: () => setState(
                      () =>
                          consultorios[clinicIndex]['horario'][dia]['tieneTurno2'] =
                              true,
                    ),
                    icon: const Icon(Icons.add, size: 14, color: Colors.blue),
                    label: const Text(
                      'Turno tarde',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Text(
                    'Cerrado',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),

          // FILA DEL SEGUNDO TURNO (Aparece abajo si le dio a +)
          if (abierto && tieneTurno2)
            Padding(
              padding: const EdgeInsets.only(left: 140, top: 5),
              child: Row(
                children: [
                  const Text(
                    'De: ',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  _timeDrop(clinicIndex, dia, 'de2'),
                  const SizedBox(width: 10),
                  const Text(
                    'A: ',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  _timeDrop(clinicIndex, dia, 'a2'),

                  // Botón para eliminar el turno de tarde
                  IconButton(
                    onPressed: () => setState(
                      () =>
                          consultorios[clinicIndex]['horario'][dia]['tieneTurno2'] =
                              false,
                    ),
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    tooltip: 'Quitar turno de tarde',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _timeDrop(int clinicIdx, String dia, String key) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value:
              consultorios[clinicIdx]['horario'][dia][key] ??
              '05:00 PM', // Fallback por si acaso
          items: horasDisponibles
              .map(
                (h) => DropdownMenuItem(
                  value: h,
                  child: Text(h, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: (val) => setState(
            () => consultorios[clinicIdx]['horario'][dia][key] = val,
          ),
        ),
      ),
    );
  }

  Widget _textField(
    String label,
    TextEditingController ctrl, {
    Widget? iconWidget,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: ctrl,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: iconWidget != null
              ? Padding(padding: const EdgeInsets.all(12.0), child: iconWidget)
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade200,
        ),
      ),
    );
  }
}
