import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'doctor_dashboard_screen.dart';
import 'medicos_page_screen.dart';
import 'establishment_dashboard_screen.dart'; 

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Llave y Controladores para el Formulario de Alta Manual
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _especialidadController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  String _perfilParaRegistrar = 'Médico';
  bool _guardandoPerfil = false;

  // Stream unificado nativo para escuchar las 3 colecciones en paralelo sin librerías externas
  Stream<List<QuerySnapshot>> _obtenerDatosCombinados() {
    final usuariosStream = FirebaseFirestore.instance
        .collection('usuarios')
        .snapshots();
    final hospitalesStream = FirebaseFirestore.instance
        .collection('hospitales')
        .snapshots();
    final farmaciasStream = FirebaseFirestore.instance
        .collection('farmacias')
        .snapshots();

    return StreamController<List<QuerySnapshot>>.broadcast(
      onListen: () {},
    ).stream;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreController.dispose();
    _apellidosController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _especialidadController.dispose();
    _cedulaController.dispose();
    super.dispose();
  }

  Future<void> _toggleEstadoDocumento(
    String coleccion,
    String docId,
    bool estadoActual,
  ) async {
    await FirebaseFirestore.instance.collection(coleccion).doc(docId).update({
      'activo': !estadoActual,
    });
  }

  Future<void> _toggleNivelDoctor(String docId, String nivelActual) async {
    String nuevoNivel = nivelActual == 'pro' ? 'basico' : 'pro';
    await FirebaseFirestore.instance.collection('usuarios').doc(docId).update({
      'tipo_perfil': nuevoNivel,
    });
  }

  Future<void> _guardarAltaManual() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardandoPerfil = true);

    try {
      final String nombre = _nombreController.text.trim();
      final String telefono = _telefonoController.text.trim();
      final String direccion = _direccionController.text.trim();
      final String ciudad = _ciudadController.text.trim();

      List<Map<String, dynamic>> consultoriosEstructura = [
        {'direccion': direccion, 'ciudad': ciudad, 'whatsapp': telefono},
      ];

      if (_perfilParaRegistrar == 'Médico' ||
          _perfilParaRegistrar == 'Enfermero') {
        String rol = _perfilParaRegistrar == 'Médico' ? 'medico' : 'enfermero';
        await FirebaseFirestore.instance.collection('usuarios').add({
          'nombre': nombre,
          'apellidos': _apellidosController.text.trim(),
          'especialidad': _perfilParaRegistrar == 'Enfermero'
              ? 'Enfermería General'
              : _especialidadController.text.trim(),
          'cedula': _cedulaController.text.trim(),
          'rol': rol,
          'activo': true,
          'tipo_perfil': 'basic',
          'reseñas_count': 0,
          'clics_wa': 0,
          'visitas': 0,
          'foto_url': '',
          'consultorios': consultoriosEstructura,
          'fecha_registro': FieldValue.serverTimestamp(),
        });
      } else {
        String coleccion = _perfilParaRegistrar == 'Hospital'
            ? 'hospitales'
            : 'farmacias';
        await FirebaseFirestore.instance.collection(coleccion).add({
          'nombre': nombre,
          'direccion': direccion,
          'ciudad': ciudad,
          'telefono': telefono,
          'activo': true,
          'score': '5.0',
          'fecha_registro': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡$_perfilParaRegistrar dado de alta con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _limpiarControladores();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el registro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _guardandoPerfil = false);
    }
  }

  void _limpiarControladores() {
    _nombreController.clear();
    _apellidosController.clear();
    _telefonoController.clear();
    _direccionController.clear();
    _ciudadController.clear();
    _especialidadController.clear();
    _cedulaController.clear();
  }

  void _mostrarModalAlta() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool esMedico = _perfilParaRegistrar == 'Médico';
            bool esEnfermero = _perfilParaRegistrar == 'Enfermero';

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.add_business_rounded, color: Colors.blue),
                  const SizedBox(width: 10),
                  const Text(
                    'Nuevo Registro Manual',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selecciona el tipo de perfil a registrar:',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _perfilParaRegistrar,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          items:
                              [
                                'Médico',
                                'Hospital',
                                'Farmacias',
                                'Enfermero',
                              ].map((String val) {
                                return DropdownMenuItem<String>(
                                  value: val,
                                  child: Text(val),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              _perfilParaRegistrar = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildInputLabel('Nombre / Razón Social'),
                        TextFormField(
                          controller: _nombreController,
                          decoration: _inputDecoration(
                            'Ej. Dr. Armando Lozano o Farmacia Central',
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Campo requerido' : null,
                        ),
                        if (esMedico || esEnfermero) ...[
                          const SizedBox(height: 16),
                          _buildInputLabel('Apellidos'),
                          TextFormField(
                            controller: _apellidosController,
                            decoration: _inputDecoration('Ej. Martínez Ruiz'),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Campo requerido'
                                : null,
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildInputLabel('Teléfono / WhatsApp de Contacto'),
                        TextFormField(
                          controller: _telefonoController,
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration('Ej. 8711234567'),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildInputLabel('Dirección Física'),
                        TextFormField(
                          controller: _direccionController,
                          decoration: _inputDecoration(
                            'Ej. Av. Juárez #123 Col. Centro',
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildInputLabel('Ciudad'),
                        TextFormField(
                          controller: _ciudadController,
                          decoration: _inputDecoration(
                            'Ej. Torreón, Gómez Palacio, Lerdo',
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Campo requerido' : null,
                        ),
                        if (esMedico) ...[
                          const SizedBox(height: 16),
                          _buildInputLabel('Especialidad Médica'),
                          TextFormField(
                            controller: _especialidadController,
                            decoration: _inputDecoration(
                              'Ej. Cardiología, Pediatría',
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Campo requerido'
                                : null,
                          ),
                        ],
                        if (esMedico || esEnfermero) ...[
                          const SizedBox(height: 16),
                          _buildInputLabel('Cédula Profesional'),
                          TextFormField(
                            controller: _cedulaController,
                            decoration: _inputDecoration('Ej. 12345678'),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Campo requerido'
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _limpiarControladores();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: _guardandoPerfil ? null : _guardarAltaManual,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0061E0),
                  ),
                  child: _guardandoPerfil
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Guardar Alta',
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const Icon(Icons.settings, color: Colors.blueGrey),
            const SizedBox(width: 10),
            const Text(
              'Panel Administrador',
              style: TextStyle(
                color: Color(0xFF1A1F36),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 15),
            Text(
              'Médicos Laguna · Control total del directorio',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MedicosPageScreen(),
              ),
            ),
            icon: const Icon(Icons.public, color: Colors.blue),
            label: const Text(
              'Ver sitio público',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          TextButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MedicosPageScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout, color: Colors.grey),
            label: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Text('No hay datos disponibles en Firebase.'),
            );
          }

          final usuariosDocs = snapshot.data!.docs;

          final doctores = usuariosDocs
              .where(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['rol'] == 'medico',
              )
              .toList();
          final enfermeros = usuariosDocs
              .where(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['rol'] == 'enfermero',
              )
              .toList();

          final solicitudesPendientes = usuariosDocs.where((doc) {
            var d = doc.data() as Map<String, dynamic>;
            return (d['rol'] == 'medico' || d['rol'] == 'enfermero') &&
                (d['activo'] ?? false) == false;
          }).toList();

          int perfilesActivos =
              doctores
                  .where(
                    (d) =>
                        (d.data() as Map<String, dynamic>)['activo'] ?? false,
                  )
                  .length +
              enfermeros
                  .where(
                    (e) =>
                        (e.data() as Map<String, dynamic>)['activo'] ?? false,
                  )
                  .length;

          int perfilesDestacados = doctores
              .where(
                (d) =>
                    (d.data() as Map<String, dynamic>)['tipo_perfil'] == 'pro',
              )
              .length;
          int totalRegistradosGlobal = doctores.length + enfermeros.length;
          int totalClicsWA = 0;
          for (var doc in doctores) {
            totalClicsWA +=
                ((doc.data() as Map<String, dynamic>)['clics_wa'] as int?) ?? 0;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    _buildKpiCard(
                      'Solicitudes Pendientes',
                      solicitudesPendientes.length.toString(),
                      const Icon(
                        Icons.notification_important,
                        color: Colors.redAccent,
                        size: 30,
                      ),
                      Colors.redAccent,
                    ),
                    _buildKpiCard(
                      'Total Activos',
                      perfilesActivos.toString(),
                      const Icon(
                        Icons.check_box,
                        color: Colors.green,
                        size: 30,
                      ),
                      Colors.green,
                    ),
                    _buildKpiCard(
                      'Médicos Pro',
                      perfilesDestacados.toString(),
                      const Icon(Icons.star, color: Colors.amber, size: 30),
                      Colors.amber,
                    ),
                    _buildKpiCard(
                      'Directorio Global',
                      totalRegistradosGlobal.toString(),
                      const Icon(
                        Icons.analytics_rounded,
                        color: Colors.blue,
                        size: 30,
                      ),
                      Colors.blue,
                    ),
                    _buildKpiCard(
                      'Clics WA',
                      totalClicsWA.toString(),
                      const FaIcon(
                        FontAwesomeIcons.whatsapp,
                        color: Colors.green,
                        size: 30,
                      ),
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                    onTap: (index) => setState(() => _currentTabIndex = index),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.hourglass_empty),
                            const SizedBox(width: 6),
                            const Text('Pendientes'),
                            if (solicitudesPendientes.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${solicitudesPendientes.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Tab(
                        icon: Icon(Icons.medical_services_outlined),
                        text: 'Doctores',
                      ),
                      const Tab(
                        icon: Icon(Icons.local_hospital_outlined),
                        text: 'Hospitales',
                      ),
                      const Tab(
                        icon: Icon(Icons.local_pharmacy_outlined),
                        text: 'Farmacias',
                      ),
                      const Tab(
                        icon: Icon(Icons.people_outline),
                        text: 'Enfermeros',
                      ),
                      const Tab(
                        icon: Icon(Icons.bar_chart),
                        text: 'Estadísticas',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_currentTabIndex != 5)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: _mostrarModalAlta,
                              icon: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: const Text(
                                'Registrar Nuevo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0061E0),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: _buildCurrentTabContent(
                          doctores,
                          enfermeros,
                          solicitudesPendientes,
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
    );
  }

  Widget _buildCurrentTabContent(
    List<QueryDocumentSnapshot> doctores,
    List<QueryDocumentSnapshot> enfermeros,
    List<QueryDocumentSnapshot> pendientes,
  ) {
    switch (_currentTabIndex) {
      case 0:
        return _buildDirectorioTable(
          pendientes,
          'usuarios',
          esPestanaPendientes: true,
        );
      case 1:
        return _buildDirectorioTable(doctores, 'usuarios');
      case 2:
        return _buildColeccionEstaticaTable('hospitales');
      case 3:
        return _buildColeccionEstaticaTable('farmacias');
      case 4:
        return _buildDirectorioTable(enfermeros, 'usuarios', esEnfermero: true);
      default:
        return _buildEstadisticasList(doctores);
    }
  }

  Widget _buildKpiCard(
    String title,
    String value,
    Widget iconWidget,
    Color textColor,
  ) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          iconWidget,
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectorioTable(
    List<QueryDocumentSnapshot> registros,
    String nombreColeccion, {
    bool esPestanaPendientes = false,
    bool esEnfermero = false,
  }) {
    if (registros.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(
          child: Text(
            'No hay registros dados de alta en este apartado.',
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              horizontalMargin: 24,
              columnSpacing: 16,
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
              columns: [
                const DataColumn(label: Text('Nombre Completo')),
                const DataColumn(label: Text('Ciudad / Dirección')),
                const DataColumn(label: Text('Especialidad')),
                if (!esPestanaPendientes)
                  const DataColumn(label: Text('Estado')),
                const DataColumn(label: Text('Acciones')),
              ],
              rows: registros.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                bool isActive = data['activo'] ?? false;
                String uid = doc.id;

                String tituloVisual =
                    '${data['nombre'] ?? ''} ${data['apellidos'] ?? ''}';
                String subtituloFiltro = data['especialidad'] ?? 'General';

                String ubicacionVisual =
                    (data['consultorios'] != null &&
                        (data['consultorios'] as List).isNotEmpty)
                    ? '${data['consultorios'][0]['ciudad'] ?? ''} - ${data['consultorios'][0]['direccion'] ?? ''}'
                    : 'Sin dirección configurada';

                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            backgroundColor: esEnfermero
                                ? Colors.purple
                                : Colors.teal,
                            radius: 14,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () {
                              if (!esEnfermero && !esPestanaPendientes) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DoctorDashboardScreen(
                                      adminViewUid: uid,
                                    ),
                                  ),
                                );
                              }
                            },
                            hoverColor: (esEnfermero || esPestanaPendientes)
                                ? Colors.transparent
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              tituloVisual,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: (esEnfermero || esPestanaPendientes)
                                    ? const Color(0xFF334155)
                                    : const Color(0xFF0061E0),
                                decoration: (esEnfermero || esPestanaPendientes)
                                    ? TextDecoration.none
                                    : TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        ubicacionVisual,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataCell(Text(subtituloFiltro)),
                    if (!esPestanaPendientes)
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActive ? Icons.circle : Icons.circle_outlined,
                              color: isActive ? Colors.green : Colors.red,
                              size: 10,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isActive ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                color: isActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (nombreColeccion == 'usuarios' &&
                              !esPestanaPendientes &&
                              !esEnfermero) ...[
                            TextButton.icon(
                              onPressed: () => _toggleNivelDoctor(
                                uid,
                                data['tipo_perfil'] ?? 'basico',
                              ),
                              icon: Icon(
                                Icons.star,
                                color: (data['tipo_perfil'] == 'pro')
                                    ? Colors.grey
                                    : Colors.amber,
                                size: 15,
                              ),
                              label: Text(
                                (data['tipo_perfil'] == 'pro')
                                    ? 'Quitar Pro'
                                    : 'Destacar',
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: isActive
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: BorderSide(
                                  color: isActive
                                      ? Colors.red.shade200
                                      : Colors.green.shade200,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () => _toggleEstadoDocumento(
                              nombreColeccion,
                              uid,
                              isActive,
                            ),
                            icon: Icon(
                              isActive
                                  ? Icons.power_settings_new
                                  : Icons.check_circle,
                              size: 14,
                              color: isActive ? Colors.red : Colors.green,
                            ),
                            label: Text(
                              isActive
                                  ? 'Desactivar'
                                  : (esPestanaPendientes
                                        ? 'Autorizar y Activar'
                                        : 'Activar'),
                              style: TextStyle(
                                color: isActive ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // --- TABLA DE HOSPITALES Y FARMACIAS TOTALMENTE REDIRIGIDA AL DASHBOARD DE EDICIÓN ---
  Widget _buildColeccionEstaticaTable(String nombreColeccion) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(nombreColeccion)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final registros = snapshot.data!.docs;

        if (registros.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(
              child: Text(
                'No hay registros en esta sección.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  horizontalMargin: 24,
                  columnSpacing: 16,
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                  columns: [
                    DataColumn(
                      label: Text(
                        nombreColeccion == 'hospitales'
                            ? 'Hospital / Clínica'
                            : 'Establecimiento',
                      ),
                    ),
                    const DataColumn(label: Text('Ciudad / Dirección')),
                    const DataColumn(label: Text('Giro')),
                    const DataColumn(label: Text('Estado')),
                    const DataColumn(label: Text('Acciones')),
                  ],
                  rows: registros.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    bool isActive = data['activo'] ?? false;
                    String uid = doc.id;

                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue,
                                radius: 14,
                                child: Icon(
                                  nombreColeccion == 'hospitales'
                                      ? Icons.local_hospital
                                      : Icons.storefront,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 10),

                              // 👈 CORREGIDO: Redirección directa a EstablishmentDashboardScreen para edición
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EstablishmentDashboardScreen(
                                            estId:
                                                uid, // Envia el ID del documento
                                            tipo:
                                                nombreColeccion, // Envia 'hospitales' o 'farmacias'
                                          ),
                                    ),
                                  );
                                },
                                hoverColor: Colors.blue.shade50,
                                child: Text(
                                  data['nombre'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0061E0),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            '${data['ciudad'] ?? ''} - ${data['direccion'] ?? ''}',
                          ),
                        ),
                        DataCell(
                          Text(
                            nombreColeccion == 'hospitales'
                                ? 'Salud Integral'
                                : 'Farmacia',
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              Icon(
                                isActive ? Icons.circle : Icons.circle_outlined,
                                color: isActive ? Colors.green : Colors.red,
                                size: 10,
                              ),
                              const SizedBox(width: 6),
                              Text(isActive ? 'Activo' : 'Inactivo'),
                            ],
                          ),
                        ),
                        DataCell(
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: isActive
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                            ),
                            onPressed: () => _toggleEstadoDocumento(
                              nombreColeccion,
                              uid,
                              isActive,
                            ),
                            icon: Icon(
                              isActive
                                  ? Icons.power_settings_new
                                  : Icons.check_circle,
                              size: 14,
                              color: isActive ? Colors.red : Colors.green,
                            ),
                            label: Text(
                              isActive ? 'Desactivar' : 'Activar',
                              style: TextStyle(
                                color: isActive ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEstadisticasList(List<QueryDocumentSnapshot> doctores) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: doctores.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        var data = doctores[index].data() as Map<String, dynamic>;
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.blueGrey,
            child: Icon(Icons.analytics_outlined, color: Colors.white),
          ),
          title: Text(
            'Dr. ${data['nombre']} ${data['apellidos']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(data['especialidad'] ?? 'Sin especialidad'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _miniStat(
                Icons.remove_red_eye,
                '${data['visitas'] ?? 0}',
                'visitas',
                Colors.blueGrey,
              ),
              const SizedBox(width: 15),
              _miniStat(
                Icons.chat_bubble,
                '${data['clics_wa'] ?? 0}',
                'WA clics',
                Colors.purple.shade300,
              ),
              const SizedBox(width: 15),
              _miniStat(
                Icons.star,
                '${data['reseñas_count'] ?? 0}',
                'reseñas',
                Colors.amber,
              ),
              const SizedBox(width: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Último contacto WA',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    data['ultimo_contacto'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _miniStat(IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInputLabel(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        texto,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0061E0), width: 1.5),
      ),
    );
  }
}
