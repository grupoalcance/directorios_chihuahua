import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/phone_menu_drawer.dart';
import '../services/auth_service.dart';

class RegistroContratoVendedorScreen extends StatefulWidget {
  const RegistroContratoVendedorScreen({super.key});

  @override
  State<RegistroContratoVendedorScreen> createState() =>
      _RegistroContratoVendedorScreenState();
}

class _HighlightTextEditingControllers {
  // Section 1: Datos de Registro y Membresia
  final nombreMedico = TextEditingController();
  final specialty = TextEditingController();
  final fechaRegistro = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );
  final inicioDirectorio = TextEditingController();
  final gratuitoDel = TextEditingController();
  final gratuitoAl = TextEditingController();
  final avisoHospitalNum = TextEditingController();
  final avisoIndividualNum = TextEditingController();
  final inicioFacturacionDe = TextEditingController();
  final inicioFacturacionDel = TextEditingController();

  // Section 2: Ubicacion
  final direccionCalle = TextEditingController();
  final direccionNum = TextEditingController();
  final direccionColonia = TextEditingController();
  final direccionCiudad = TextEditingController();
  final ubicacionGps = TextEditingController();
  final telefonosCitas = TextEditingController();

  // Section 3: Redes Sociales y Anexos (Links/URLs)
  final fbLink = TextEditingController();
  final igLink = TextEditingController();
  final tkLink = TextEditingController();
  final webLink = TextEditingController();
  final fotoMedicoUrl = TextEditingController();
  final fotoConsultorioUrl = TextEditingController();
  final logoResolucionUrl = TextEditingController();
  final emailFactura = TextEditingController();

  // Section 4: Firmas y Control
  final nombreFirmante = TextEditingController();
  final puestoCargo = TextEditingController();
  final telefonoFirmante = TextEditingController();
  final contratoDel = TextEditingController();
  final contratoAl = TextEditingController();
  final notasAdicionales = TextEditingController();
  final asesorComercial = TextEditingController();

  void dispose() {
    nombreMedico.dispose();
    specialty.dispose();
    fechaRegistro.dispose();
    inicioDirectorio.dispose();
    gratuitoDel.dispose();
    gratuitoAl.dispose();
    avisoHospitalNum.dispose();
    avisoIndividualNum.dispose();
    inicioFacturacionDe.dispose();
    inicioFacturacionDel.dispose();
    direccionCalle.dispose();
    direccionNum.dispose();
    direccionColonia.dispose();
    direccionCiudad.dispose();
    ubicacionGps.dispose();
    telefonosCitas.dispose();
    fbLink.dispose();
    igLink.dispose();
    tkLink.dispose();
    webLink.dispose();
    fotoMedicoUrl.dispose();
    fotoConsultorioUrl.dispose();
    logoResolucionUrl.dispose();
    emailFactura.dispose();
    nombreFirmante.dispose();
    puestoCargo.dispose();
    telefonoFirmante.dispose();
    contratoDel.dispose();
    contratoAl.dispose();
    notasAdicionales.dispose();
    asesorComercial.dispose();
  }
}

class _RegistroContratoVendedorScreenState
    extends State<RegistroContratoVendedorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = _HighlightTextEditingControllers();

  // Controladores para las firmas digitales tactiles
  final SignatureController _firmaClienteController = SignatureController(
    penStrokeWidth: 3,
    penColor: const Color(0xFF0F172A),
    exportBackgroundColor: Colors.transparent,
  );

  final SignatureController _firmaAsesorController = SignatureController(
    penStrokeWidth: 3,
    penColor: const Color(0xFF0F172A),
    exportBackgroundColor: Colors.transparent,
  );

  String _avisoHospital = 'No';
  String _avisoIndividual = 'No';
  String _ayudaTramiteAviso = 'No';
  String _estacionamiento = 'No';
  String _statusPago = 'No';

  final Map<String, bool> _diasSeleccionados = {
    'Lunes': true,
    'Martes': true,
    'Miércoles': true,
    'Jueves': true,
    'Viernes': true,
    'Sábado': false,
    'Domingo': false,
  };

  final Map<String, Map<String, String>> _horariosActividad = {
    'Consulta': {'de': '09:00', 'a': '18:00'},
    'Emergencias': {'de': '00:00', 'a': '23:59'},
    'Visita Hospital': {'de': '--:--', 'a': '--:--'},
    'Privado': {'de': '--:--', 'a': '--:--'},
  };

  final List<TextEditingController> _serviciosControllers = List.generate(
    10,
    (_) => TextEditingController(),
  );

  bool _isCheckingRole = true;
  bool _isAuthorized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _verificarPermisosVendedor();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _firmaClienteController.dispose();
    _firmaAsesorController.dispose();
    for (var c in _serviciosControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _verificarPermisosVendedor() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _denegarAcceso();
      return;
    }
    String rol = 'desconocido';
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('rol') && userData['rol'] != null) {
          rol = userData['rol'].toString().trim();
        }
        if (rol == 'vendedor' || rol == 'admin') {
          setState(() {
            _isAuthorized = true;
            _isCheckingRole = false;
          });
          return;
        }
      }
      _denegarAcceso();
    } catch (e) {
      _denegarAcceso();
    }
  }

  void _denegarAcceso() {
    if (mounted) {
      setState(() {
        _isAuthorized = false;
        _isCheckingRole = false;
      });
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Future<void> _guardarContratoDirectorio() async {
    if (!_formKey.currentState!.validate()) return;

    if (_firmaClienteController.isEmpty || _firmaAsesorController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, ambas firmas son obligatorias antes de guardar.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    List<String> listaServicios = [];
    for (var controller in _serviciosControllers) {
      if (controller.text.trim().isNotEmpty) {
        listaServicios.add(controller.text.trim());
      }
    }

    Map<String, dynamic> contratoPayload = {
      'metadata': {
        'fecha_captura': FieldValue.serverTimestamp(),
        'asesor_comercial': _ctrl.asesorComercial.text.trim(),
        'nombre_firmante': _ctrl.nombreFirmante.text.trim(),
        'puesto_cargo': _ctrl.puestoCargo.text.trim(),
        'telefono_firmante': _ctrl.telefonoFirmante.text.trim(),
        'contrato_periodo': {
          'del': _ctrl.contratoDel.text.trim(),
          'al': _ctrl.contratoAl.text.trim(),
        },
        'pagado': _statusPago == 'Si',
        'firmas_digitalizadas': {
          'cliente_firmó': !_firmaClienteController.isEmpty,
          'asesor_firmó': !_firmaAsesorController.isEmpty,
        },
        'notes_internas': _ctrl.notasAdicionales.text.trim(),
      },
      'perfil_medico': {
        'nombre_establecimiento': _ctrl.nombreMedico.text.trim(),
        'especialidad': _ctrl.specialty.text.trim(),
        'activo': true,
        'fecha_registro': _ctrl.fechaRegistro.text.trim(),
        'inicio_directorio': _ctrl.inicioDirectorio.text.trim(),
        'periodo_gratuito': {
          'del': _ctrl.gratuitoDel.text.trim(),
          'al': _ctrl.gratuitoAl.text.trim(),
        },
        'email_factura': _ctrl.emailFactura.text.trim(),
      },
      'regulacion_sanitaria': {
        'aviso_hospital': _avisoHospital == 'Si',
        'aviso_hospital_num': _ctrl.avisoHospitalNum.text.trim(),
        'aviso_individual': _avisoIndividual == 'Si',
        'aviso_individual_num': _ctrl.avisoIndividualNum.text.trim(),
        'requiere_ayuda_tramite': _ayudaTramiteAviso == 'Si',
        'inicio_facturacion': {
          'de': _ctrl.inicioFacturacionDe.text.trim(),
          'del': _ctrl.inicioFacturacionDel.text.trim(),
        },
      },
      'ubicacion_consultorio': {
        'calle': _ctrl.direccionCalle.text.trim(),
        'numero': _ctrl.direccionNum.text.trim(),
        'colonia': _ctrl.direccionColonia.text.trim(),
        'ciudad': _ctrl.direccionCiudad.text.trim(),
        'ubicacion_gps': _ctrl.ubicacionGps.text.trim(),
        'telefonos_citas': _ctrl.telefonosCitas.text.trim(),
        'estacionamiento_propio': _estacionamiento == 'Si',
      },
      'agenda_horarios': {
        'dias_atencion': _diasSeleccionados,
        'configuracion_horas': _horariosActividad,
      },
      'servicios_destacados': listaServicios,
      'redes_sociales': {
        'facebook': _ctrl.fbLink.text.trim(),
        'instagram': _ctrl.igLink.text.trim(),
        'tiktok': _ctrl.tkLink.text.trim(),
        'sitio_web': _ctrl.webLink.text.trim(),
      },
      'archivos_anexos_urls': {
        'foto_medico': _ctrl.fotoMedicoUrl.text.trim(),
        'foto_consultorio_fachada': _ctrl.fotoConsultorioUrl.text.trim(),
        'logo_alta_resolucion': _ctrl.logoResolucionUrl.text.trim(),
      },
    };

    try {
      await FirebaseFirestore.instance
          .collection('registro_contratos')
          .add(contratoPayload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Expediente de Directorio Registrado con Éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset();
        _firmaClienteController.clear();
        _firmaAsesorController.clear();
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    if (_isCheckingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

    if (!_isAuthorized) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(),
      drawer: width < 1100 ? const PhoneMenuDrawer() : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Registro de Médicos para Directorio Web',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'Formulario digital de captura exclusiva para Asesores Comerciales - Agencia Alcance.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 🏢 SECCIÓN 1
                  _buildSectionCard(
                    title: '1. Identificación del Médico y Periodo de Contrato',
                    icon: Icons.assignment_ind_outlined,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool useVertical = constraints.maxWidth < 600;
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: useVertical ? 1 : 2,
                                    child: _buildTextField(
                                      label:
                                          'Nombre del Médico o Establecimiento *',
                                      controller: _ctrl.nombreMedico,
                                      validator: (v) =>
                                          v!.isEmpty ? 'Requerido' : null,
                                    ),
                                  ),
                                  if (!useVertical) const SizedBox(width: 16),
                                  if (!useVertical)
                                    Expanded(
                                      flex: 1,
                                      child: _buildTextField(
                                        label:
                                            'Especialidad Médica o Actividad *',
                                        controller: _ctrl.specialty,
                                        validator: (v) =>
                                            v!.isEmpty ? 'Requerido' : null,
                                      ),
                                    ),
                                ],
                              ),
                              if (useVertical) const SizedBox(height: 16),
                              if (useVertical)
                                _buildTextField(
                                  label: 'Especialidad Médica o Actividad *',
                                  controller: _ctrl.specialty,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Requerido' : null,
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool useVertical = constraints.maxWidth < 750;
                          return useVertical
                              ? Column(
                                  children: [
                                    _buildTextField(
                                      label: 'Fecha de Registro',
                                      controller: _ctrl.fechaRegistro,
                                      enabled: false,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Inicio en el Directorio',
                                      controller: _ctrl.inicioDirectorio,
                                      keyboardType: TextInputType.datetime,
                                      hintText: 'dd/mm/aaaa',
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Periodo Gratuito (Del)',
                                      controller: _ctrl.gratuitoDel,
                                      hintText: 'dd/mm/aaaa',
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Periodo Gratuito (Al)',
                                      controller: _ctrl.gratuitoAl,
                                      hintText: 'dd/mm/aaaa',
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Fecha de Registro',
                                        controller: _ctrl.fechaRegistro,
                                        enabled: false,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Inicio en el Directorio',
                                        controller: _ctrl.inicioDirectorio,
                                        keyboardType: TextInputType.datetime,
                                        hintText: 'dd/mm/aaaa',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Periodo Gratuito (Del)',
                                        controller: _ctrl.gratuitoDel,
                                        hintText: 'dd/mm/aaaa',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Periodo Gratuito (Al)',
                                        controller: _ctrl.gratuitoAl,
                                        hintText: 'dd/mm/aaaa',
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 🛡️ SECCIÓN 2
                  _buildSectionCard(
                    title: '2. Regulación Sanitaria e Inicio de Facturación',
                    icon: Icons.gavel_rounded,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool useVertical = constraints.maxWidth < 650;
                          return useVertical
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildRadioRow(
                                      label:
                                          '¿Cuenta con Aviso de Publicidad el Hospital en el que trabaja?',
                                      value: _avisoHospital,
                                      onChanged: (v) =>
                                          setState(() => _avisoHospital = v!),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      label: 'Número de Aviso Hospital',
                                      controller: _ctrl.avisoHospitalNum,
                                      enabled: _avisoHospital == 'Si',
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildRadioRow(
                                        label:
                                            '¿Cuenta con Aviso de Publicidad el Hospital en el que trabaja?',
                                        value: _avisoHospital,
                                        onChanged: (v) =>
                                            setState(() => _avisoHospital = v!),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Número de Aviso Hospital',
                                        controller: _ctrl.avisoHospitalNum,
                                        enabled: _avisoHospital == 'Si',
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                      const Divider(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool useVertical = constraints.maxWidth < 650;
                          return useVertical
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildRadioRow(
                                      label:
                                          '¿Cuenta con Aviso de Publicidad Individual?',
                                      value: _avisoIndividual,
                                      onChanged: (v) =>
                                          setState(() => _avisoIndividual = v!),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      label: 'Número de Aviso Individual',
                                      controller: _ctrl.avisoIndividualNum,
                                      enabled: _avisoIndividual == 'Si',
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildRadioRow(
                                        label:
                                            '¿Cuenta con Aviso de Publicidad Individual?',
                                        value: _avisoIndividual,
                                        onChanged: (v) => setState(
                                          () => _avisoIndividual = v!,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Número de Aviso Individual',
                                        controller: _ctrl.avisoIndividualNum,
                                        enabled: _avisoIndividual == 'Si',
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                      const Divider(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool useVertical = constraints.maxWidth < 750;
                          return useVertical
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildRadioRow(
                                      label:
                                          '¿Requiere que le ayuden a tramitar el aviso como Médico Individual?',
                                      value: _ayudaTramiteAviso,
                                      onChanged: (v) => setState(
                                        () => _ayudaTramiteAviso = v!,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Inicio de Facturación (De)',
                                      controller: _ctrl.inicioFacturacionDe,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Inicio de Facturación (Del)',
                                      controller: _ctrl.inicioFacturacionDel,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildRadioRow(
                                        label:
                                            '¿Requiere que le ayuden a tramitar el aviso como Médico Individual?',
                                        value: _ayudaTramiteAviso,
                                        onChanged: (v) => setState(
                                          () => _ayudaTramiteAviso = v!,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Inicio de Facturación (De)',
                                        controller: _ctrl.inicioFacturacionDe,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Inicio de Facturación (Del)',
                                        controller: _ctrl.inicioFacturacionDel,
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 📍 SECCIÓN 3
                  _buildSectionCard(
                    title: '3. Ubicación Geográfica del Establecimiento',
                    icon: Icons.map_outlined,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool useVertical = constraints.maxWidth < 650;
                          return useVertical
                              ? Column(
                                  children: [
                                    _buildTextField(
                                      label: 'Calle',
                                      controller: _ctrl.direccionCalle,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'No. Exterior/Interior',
                                      controller: _ctrl.direccionNum,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Colonia o Fraccionamiento',
                                      controller: _ctrl.direccionColonia,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: _buildTextField(
                                        label: 'Calle',
                                        controller: _ctrl.direccionCalle,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: _buildTextField(
                                        label: 'No. Exterior/Interior',
                                        controller: _ctrl.direccionNum,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 2,
                                      child: _buildTextField(
                                        label: 'Colonia o Fraccionamiento',
                                        controller: _ctrl.direccionColonia,
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool useVertical = constraints.maxWidth < 750;
                          return useVertical
                              ? Column(
                                  children: [
                                    _buildTextField(
                                      label: 'Ciudad o Municipio',
                                      controller: _ctrl
                                          .direccionCiudad, // 🔑 CORREGIDO EL ESPACIO EN BLANCO
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label:
                                          'Coordenadas GPS (Link o Lat, Lon)',
                                      controller: _ctrl.ubicacionGps,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Teléfonos para Reservar Citas',
                                      controller: _ctrl.telefonosCitas,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Ciudad o Municipio',
                                        controller: _ctrl
                                            .direccionCiudad, // 🔑 CORREGIDO EL ESPACIO EN BLANCO
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label:
                                            'Coordenadas GPS (Link o Lat, Lon)',
                                        controller: _ctrl.ubicacionGps,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Teléfonos para Reservar Citas',
                                        controller: _ctrl.telefonosCitas,
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildRadioRow(
                        label: '¿Cuenta con Estacionamiento Propio?',
                        value: _estacionamiento,
                        onChanged: (v) => setState(() => _estacionamiento = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 🗓️ SECCIÓN 4
                  _buildSectionCard(
                    title: '4. Días de Consulta y Configuración de Horarios',
                    icon: Icons.calendar_month_outlined,
                    children: [
                      const Text(
                        'Selecciona los días laborables:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: _diasSeleccionados.keys.map((dia) {
                          return FilterChip(
                            label: Text(dia),
                            selected: _diasSeleccionados[dia]!,
                            onSelected: (val) =>
                                setState(() => _diasSeleccionados[dia] = val),
                            selectedColor: Colors.blue.shade100,
                            checkmarkColor: Colors.blue.shade900,
                          );
                        }).toList(),
                      ),
                      const Divider(height: 32),
                      const Text(
                        'Horarios por Tipo de Actividad (Formatos de Turno):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGridHorarios(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 🩺 SECCIÓN 5
                  _buildSectionCard(
                    title:
                        '5. Servicios Destacados que Ofrecen en el Consultorio (Máximo 10)',
                    icon: Icons.medical_services_outlined,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = constraints.maxWidth < 650
                              ? 1
                              : 2;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 10,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisExtent: 85,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 8,
                                ),
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: _buildTextField(
                                  label: 'Servicio ${index + 1}',
                                  controller: _serviciosControllers[index],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 🌐 SECCIÓN 6
                  _buildSectionCard(
                    title: '6. Canales Digitales y Enlaces de Archivos Anexos',
                    icon: Icons.cloud_circle_outlined,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool useVertical = constraints.maxWidth < 600;
                          return useVertical
                              ? Column(
                                  children: [
                                    _buildTextField(
                                      label: 'Enlace de Facebook',
                                      controller: _ctrl.fbLink,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Enlace de Instagram',
                                      controller: _ctrl.igLink,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Enlace de Facebook',
                                        controller: _ctrl.fbLink,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Enlace de Instagram',
                                        controller: _ctrl.igLink,
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool useVertical = constraints.maxWidth < 600;
                          return useVertical
                              ? Column(
                                  children: [
                                    _buildTextField(
                                      label: 'Enlace de Tik Tok',
                                      controller: _ctrl.tkLink,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Enlace de Sitio Web',
                                      controller: _ctrl.webLink,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Enlace de Tik Tok',
                                        controller: _ctrl.tkLink,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Enlace de Sitio Web',
                                        controller: _ctrl.webLink,
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                      const Divider(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool useVertical = constraints.maxWidth < 650;
                          return useVertical
                              ? Column(
                                  children: [
                                    _buildTextField(
                                      label:
                                          'URL Foto del Médico (Drive / Storage)',
                                      controller: _ctrl.fotoMedicoUrl,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'URL Foto Fachada/Consultorio',
                                      controller: _ctrl.fotoConsultorioUrl,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        label:
                                            'URL Foto del Médico (Drive / Storage)',
                                        controller: _ctrl.fotoMedicoUrl,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'URL Foto Fachada/Consultorio',
                                        controller: _ctrl.fotoConsultorioUrl,
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool useVertical = constraints.maxWidth < 650;
                          return useVertical
                              ? Column(
                                  children: [
                                    _buildTextField(
                                      label: 'URL Logotipo Alta Resolución',
                                      controller: _ctrl.logoResolucionUrl,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Email envío de Facturas',
                                      controller: _ctrl.emailFactura,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'URL Logotipo Alta Resolución',
                                        controller: _ctrl.logoResolucionUrl,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Email envío de Facturas',
                                        controller: _ctrl.emailFactura,
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ✍️ SECCIÓN 7
                  _buildSectionCard(
                    title: '7. Cierre de Contrato y Validación de Pago',
                    icon: Icons.border_color_outlined,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool useVertical = constraints.maxWidth < 750;
                          return useVertical
                              ? Column(
                                  children: [
                                    _buildTextField(
                                      label: 'Nombre del Firmante (Cliente) *',
                                      controller: _ctrl.nombreFirmante,
                                      validator: (v) =>
                                          v!.isEmpty ? 'Requerido' : null,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Puesto o Cargo *',
                                      controller: _ctrl.puestoCargo,
                                      validator: (v) =>
                                          v!.isEmpty ? 'Requerido' : null,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Teléfono de Contacto',
                                      controller: _ctrl.telefonoFirmante,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        label:
                                            'Nombre del Firmante (Cliente) *',
                                        controller: _ctrl.nombreFirmante,
                                        validator: (v) =>
                                            v!.isEmpty ? 'Requerido' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Puesto o Cargo *',
                                        controller: _ctrl.puestoCargo,
                                        validator: (v) =>
                                            v!.isEmpty ? 'Requerido' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Teléfono de Contacto',
                                        controller: _ctrl.telefonoFirmante,
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool useVertical = constraints.maxWidth < 750;
                          return useVertical
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTextField(
                                      label: 'Periodo de Contrato (Del)',
                                      controller: _ctrl.contratoDel,
                                      keyboardType: TextInputType.datetime,
                                      hintText: 'dd/mm/aaaa',
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Periodo de Contrato (Al)',
                                      controller: _ctrl.contratoAl,
                                      keyboardType: TextInputType.datetime,
                                      hintText: 'dd/mm/aaaa',
                                    ),
                                    const SizedBox(height: 16),
                                    _buildRadioRow(
                                      label: '¿Contrato Pagado?',
                                      value: _statusPago,
                                      onChanged: (v) =>
                                          setState(() => _statusPago = v!),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Periodo de Contrato (Del)',
                                        controller: _ctrl.contratoDel,
                                        keyboardType: TextInputType.datetime,
                                        hintText: 'dd/mm/aaaa',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Periodo de Contrato (Al)',
                                        controller: _ctrl.contratoAl,
                                        keyboardType: TextInputType.datetime,
                                        hintText: 'dd/mm/aaaa',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildRadioRow(
                                        label: '¿Contrato Pagado?',
                                        value: _statusPago,
                                        onChanged: (v) =>
                                            setState(() => _statusPago = v!),
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool useVertical = constraints.maxWidth < 700;
                          return useVertical
                              ? Column(
                                  children: [
                                    _buildTextField(
                                      label: 'Notas Especiales / Observaciones',
                                      controller: _ctrl.notasAdicionales,
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Nombre del Asesor Comercial *',
                                      controller: _ctrl.asesorComercial,
                                      validator: (v) =>
                                          v!.isEmpty ? 'Requerido' : null,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: _buildTextField(
                                        label:
                                            'Notas Especiales / Observaciones',
                                        controller: _ctrl.notasAdicionales,
                                        maxLines: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: _buildTextField(
                                        label: 'Nombre del Asesor Comercial *',
                                        controller: _ctrl.asesorComercial,
                                        validator: (v) =>
                                            v!.isEmpty ? 'Requerido' : null,
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(color: Color(0xFFCBD5E1), thickness: 1),
                      ),

                      const Text(
                        'Firmas de Conformidad del Acuerdo',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool compactFirmas = constraints.maxWidth < 650;
                          return compactFirmas
                              ? Column(
                                  children: [
                                    _buildSignatureBox(
                                      title:
                                          'Firma del Cliente (Médico / Representante)',
                                      controller: _firmaClienteController,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildSignatureBox(
                                      title: 'Firma del Asesor Comercial',
                                      controller: _firmaAsesorController,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildSignatureBox(
                                        title: 'Firma del Cliente (Médico)',
                                        controller: _firmaClienteController,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: _buildSignatureBox(
                                        title: 'Firma del Asesor Comercial',
                                        controller: _firmaAsesorController,
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // --- BOTÓN PRINCIPAL ---
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _guardarContratoDirectorio,
                      icon: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.cloud_upload_outlined,
                              color: Colors.white,
                            ),
                      label: Text(
                        _isSaving
                            ? 'Procesando Expediente...'
                            : 'Guardar y Dar de Alta Contrato',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0061E0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 🎨 COMPONENTES INTERNOS DE ESTILIZACIÓN PREMIUM
  // =========================================================================
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0061E0), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Divider(color: Color(0xFFF1F5F9)),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool enabled = true,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12.5,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          maxLines: maxLines,
          // 🔑 FORMATEADOR INTELIGENTE INTEGRADO:
          inputFormatters: keyboardType == TextInputType.datetime
              ? [FormateadorMascaraFecha()]
              : null,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            filled: true,
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            fillColor: enabled
                ? const Color(0xFFF8FAFC)
                : const Color(0xFFF1F5F9),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioRow({
    required String label,
    required String value,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12.5,
            color: Color(0xFF475569),
          ),
        ),
        Row(
          children: [
            Radio<String>(
              value: 'Si',
              groupValue: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF0061E0),
            ),
            const Text('Si', style: TextStyle(fontSize: 13.5)),
            const SizedBox(width: 20),
            Radio<String>(
              value: 'No',
              groupValue: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF0061E0),
            ),
            const Text('No', style: TextStyle(fontSize: 13.5)),
          ],
        ),
      ],
    );
  }

  Widget _buildSignatureBox({
    required String title,
    required SignatureController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Signature(
              controller: controller,
              height: 140,
              backgroundColor: const Color(0xFFF8FAFC),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: CalendarWithVisibility.centerRight,
          child: TextButton.icon(
            onPressed: () => controller.clear(),
            icon: const Icon(
              Icons.delete_sweep_outlined,
              size: 16,
              color: Colors.redAccent,
            ),
            label: const Text(
              'Limpiar Trazo',
              style: TextStyle(fontSize: 11, color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridHorarios() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool compactMode = constraints.maxWidth < 500;
        return Table(
          columnWidths: compactMode
              ? const {
                  0: FlexColumnWidth(1.5),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                }
              : const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: _horariosActividad.keys.map((actividad) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    actividad,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                      fontSize: 13,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      const Text(
                        'De: ',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: TextFormField(
                            initialValue: _horariosActividad[actividad]!['de'],
                            onChanged: (val) =>
                                _horariosActividad[actividad]!['de'] = val,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      const Text(
                        'A: ',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: TextFormField(
                            initialValue: _horariosActividad[actividad]!['a'],
                            onChanged: (val) =>
                                _horariosActividad[actividad]!['a'] = val,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

class CalendarWithVisibility {
  static const Alignment centerRight = Alignment.centerRight;
}

// =========================================================================
// 🚀 CLASE FORMATEADORA INTEGRADA (MÁSCARA DE FECHAS AUTOMÁTICA)
// =========================================================================
class FormateadorMascaraFecha extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length < oldValue.text.length) {
      return newValue;
    }

    var numeroSolo = text.replaceAll('/', '');
    var buffer = StringBuffer();

    if (numeroSolo.length > 8) {
      numeroSolo = numeroSolo.substring(0, 8);
    }

    for (int i = 0; i < numeroSolo.length; i++) {
      buffer.write(numeroSolo[i]);
      var index = i + 1;
      if (index == 2 && index != numeroSolo.length) {
        buffer.write('/');
      } else if (index == 4 && index != numeroSolo.length) {
        buffer.write('/');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
