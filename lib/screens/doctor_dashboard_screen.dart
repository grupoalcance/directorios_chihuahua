import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

// 🔑 IMPORTACIÓN RELATIVA Y DINÁMICA DE CONFIGURACIÓN REGIONAL
import '../config/app_config.dart';

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

  // 🔑 LISTA NORMALIZADA DE CIUDADES DESDE AppConfig
  final List<String> _listaCiudades = AppConfig.ciudadesActivas;

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
            .doc(targetUid)
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

  Future<void> _seleccionarImagenBlog() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 400,
      imageQuality: 30,
    );

    if (image != null) {
      try {
        Uint8List imageBytes = await image.readAsBytes();

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

  Map<String, dynamic> _crearEstructuraHorarioDefecto() {
    return {
      for (var dia in diasSemana)
        dia: {
          'abierto': dia != 'Sábado' && dia != 'Domingo',
          'de': '09:00 AM',
          'a': '05:00 PM',
          'tieneTurno2': false,
          'de2': '05:00 PM',
          'a2': '08:00 PM',
        },
    };
  }

  void _agregarNuevoConsultorio() {
    setState(() {
      consultorios.add({
        'nombre': 'Consultorio ${consultorios.length + 1}',
        'calle_numero': '',
        'ciudad': _listaCiudades.first,
        'direccion': '',
        'telefono': '',
        'whatsapp': '',
        'horario': _crearEstructuraHorarioDefecto(),
      });
    });
  }

  Future<void> _loadDoctorData() async {
    if (targetUid != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(targetUid)
            .get();

        if (doc.exists) {
          QuerySnapshot blogsSnapshot = await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(targetUid)
              .collection('mis_blogs')
              .orderBy('fecha', descending: true)
              .get();

          setState(() {
            userData = doc.data() as Map<String, dynamic>? ?? {};
            isPro = userData?['tipo_perfil'] == 'pro';
            _fotoUrl = userData?['foto_url'] ?? '';
            servicios = userData?['servicios'] ?? [];

            blogs = blogsSnapshot.docs.map((blogDoc) {
              var data = blogDoc.data() as Map<String, dynamic>;
              data['id'] = blogDoc.id;
              return data;
            }).toList();

            _nombreCtrl.text = userData?['nombre'] ?? '';
            _apellidosCtrl.text = userData?['apellidos'] ?? '';
            _especialidadCtrl.text = userData?['especialidad'] ?? '';
            _cedulaCtrl.text = userData?['cedula'] ?? '';

            if (userData?['consultorios'] != null &&
                (userData!['consultorios'] is List) &&
                (userData!['consultorios'] as List).isNotEmpty) {
              consultorios = List<Map<String, dynamic>>.from(
                userData!['consultorios'].map((item) {
                  var map = Map<String, dynamic>.from(item as Map);

                  if (map['horario'] == null || map['horario'] is! Map) {
                    map['horario'] = _crearEstructuraHorarioDefecto();
                  } else {
                    Map<String, dynamic> horario = Map<String, dynamic>.from(
                      map['horario'] as Map,
                    );
                    for (String dia in diasSemana) {
                      if (horario[dia] == null || horario[dia] is! Map) {
                        horario[dia] = {
                          'abierto': false,
                          'de': '09:00 AM',
                          'a': '05:00 PM',
                          'tieneTurno2': false,
                          'de2': '05:00 PM',
                          'a2': '08:00 PM',
                        };
                      } else {
                        Map<String, dynamic> diaData =
                            Map<String, dynamic>.from(horario[dia] as Map);
                        diaData['abierto'] ??= false;
                        diaData['de'] ??= '09:00 AM';
                        diaData['a'] ??= '05:00 PM';
                        diaData['tieneTurno2'] ??= false;
                        diaData['de2'] ??= '05:00 PM';
                        diaData['a2'] ??= '08:00 PM';
                        horario[dia] = diaData;
                      }
                    }
                    map['horario'] = horario;
                  }

                  String ciudadGuardada = map['ciudad'] ?? '';
                  if (!_listaCiudades.contains(ciudadGuardada)) {
                    map['ciudad'] = _listaCiudades.first;
                  }
                  map['calle_numero'] ??= map['direccion'] ?? '';

                  return map;
                }),
              );
            } else {
              consultorios = [];
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

            List<dynamic> aseguradorasGuardadas =
                userData?['aseguradoras'] ?? [];
            for (var ase in aseguradorasGuardadas) {
              if (aseguradoras.containsKey(ase)) aseguradoras[ase] = true;
            }

            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint("Error al cargar datos del doctor: $e");
        setState(() => _isLoading = false);
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
        c['direccion'] = '${c['calle_numero'] ?? ''}, ${c['ciudad'] ?? ''}'
            .trim();
      }

      Map<String, dynamic> datosActualizados = {
        'nombre': _nombreCtrl.text.trim(),
        'apellidos': _apellidosCtrl.text.trim(),
        'especialidad': _especialidadCtrl.text.trim(),
        'cedula': _cedulaCtrl.text.trim(),
        'consultorios': consultorios,
        'servicios': servicios,
      };

      if (isPro) {
        datosActualizados.addAll({
          'descripcion': _descripcionCtrl.text.trim(),
          'costo_consulta': _costoCtrl.text.trim(),
          'experiencia': _experienciaCtrl.text.trim(),
          'link_facebook': _facebookCtrl.text.trim(),
          'link_instagram': _instagramCtrl.text.trim(),
          'link_tiktok': _tiktokCtrl.text.trim(),
          'link_x': _xCtrl.text.trim(),
          'link_web': _webCtrl.text.trim(),
          'metodos_pago': pagosSeleccionados,
          'aseguradoras': aseguradorasSeleccionadas,
        });
      }

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(targetUid)
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
                    labelColor: AppConfig.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppConfig.primaryColor,
                    tabs: const [
                      Tab(icon: Icon(Icons.bar_chart), text: 'Estadísticas'),
                      Tab(icon: Icon(Icons.edit), text: 'Editar perfil'),
                      Tab(icon: Icon(Icons.article), text: 'Blogs'),
                      Tab(icon: Icon(Icons.star_outline), text: 'Reseñas'),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 3000,
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
    String n = _nombreCtrl.text.trim();
    String a = _apellidosCtrl.text.trim();
    String iniciales = '${n.isNotEmpty ? n[0] : ''}${a.isNotEmpty ? a[0] : ''}';
    if (iniciales.isEmpty) iniciales = 'MD';

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
                        color: AppConfig.primaryColor,
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
              Text(
                '$n $a'.trim().isEmpty ? 'Doctor' : '$n $a'.trim(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    _especialidadCtrl.text.isEmpty
                        ? 'Medicina General'
                        : _especialidadCtrl.text,
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
          widget.adminViewUid != null
              ? TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back, color: AppConfig.primaryColor),
                  label: Text(
                    'Volver al Panel',
                    style: TextStyle(color: AppConfig.primaryColor),
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
            color: AppConfig.primaryColor.withOpacity(0.7),
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
                                .doc(targetUid)
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
                        backgroundColor: AppConfig.primaryColor,
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
                                      .doc(targetUid)
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
                child: _textField('Nombre (Ej: Dr. Armando)', _nombreCtrl),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _textField('Apellidos (Ej: Lozano)', _apellidosCtrl),
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
              Text(
                'Tus Consultorios y Horarios',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConfig.primaryColor,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _agregarNuevoConsultorio,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar Consultorio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor.withOpacity(0.1),
                  foregroundColor: AppConfig.primaryColor,
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
              backgroundColor: AppConfig.primaryColor,
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
    String ciudadActual = clinic['ciudad'] ?? _listaCiudades.first;
    if (!_listaCiudades.contains(ciudadActual)) {
      ciudadActual = _listaCiudades.first;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppConfig.primaryColor.withOpacity(0.2),
          width: 1.5,
        ),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppConfig.primaryColor,
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
                  initialValue: clinic['calle_numero'] ?? '',
                  onChanged: (val) => consultorios[index]['calle_numero'] = val,
                  decoration: InputDecoration(
                    labelText: 'Calle, Hospital o Número',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(
                      Icons.location_on,
                      color: AppConfig.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: ciudadActual,
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
                  initialValue: clinic['telefono'] ?? '',
                  onChanged: (val) => consultorios[index]['telefono'] = val,
                  decoration: InputDecoration(
                    labelText: 'Teléfono fijo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(
                      Icons.phone,
                      color: AppConfig.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TextFormField(
                  initialValue: clinic['whatsapp'] ?? '',
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
          ...diasSemana.map((dia) => _buildHorarioRow(index, dia)).toList(),
        ],
      ),
    );
  }

  Widget _buildHorarioRow(int clinicIndex, String dia) {
    Map<String, dynamic> horarioMap =
        consultorios[clinicIndex]['horario'] ?? {};
    Map<String, dynamic> diaData = horarioMap[dia] ?? {};

    bool abierto = diaData['abierto'] ?? false;
    bool tieneTurno2 = diaData['tieneTurno2'] ?? false;

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
                  activeColor: AppConfig.primaryColor,
                  onChanged: (val) => setState(() {
                    consultorios[clinicIndex]['horario'][dia]['abierto'] = val;
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

                if (!tieneTurno2)
                  TextButton.icon(
                    onPressed: () => setState(
                      () =>
                          consultorios[clinicIndex]['horario'][dia]['tieneTurno2'] =
                              true,
                    ),
                    icon: Icon(
                      Icons.add,
                      size: 14,
                      color: AppConfig.primaryColor,
                    ),
                    label: Text(
                      'Turno tarde',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConfig.primaryColor,
                      ),
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
    String horaSeleccionada =
        consultorios[clinicIdx]['horario'][dia][key] ?? '09:00 AM';

    if (!horasDisponibles.contains(horaSeleccionada)) {
      horaSeleccionada = '09:00 AM';
    }

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
          value: horaSeleccionada,
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
