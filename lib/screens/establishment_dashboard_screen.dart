import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../widgets/custom_app_bar.dart';
import '../widgets/phone_menu_drawer.dart';

// 🔑 IMPORTACIÓN DINÁMICA DE CONFIGURACIÓN REGIONAL
import '../config/app_config.dart';

class EstablishmentDashboardScreen extends StatefulWidget {
  final String estId; // ID del documento en Firebase
  final String tipo; // 'hospitales' o 'farmacias'

  const EstablishmentDashboardScreen({
    super.key,
    required this.estId,
    required this.tipo,
  });

  @override
  State<EstablishmentDashboardScreen> createState() =>
      _EstablishmentDashboardScreenState();
}

class _EstablishmentDashboardScreenState
    extends State<EstablishmentDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _urgenciasController = TextEditingController();
  final TextEditingController _horarioController = TextEditingController();

  // 🏥 Catálogo de Servicios e Infraestructura para Hospitales
  final List<String> _serviciosHospital = [
    'Urgencias Médicas 24/7',
    'Unidad de Cuidados Intensivos (UCI)',
    'Laboratorio Clínico y de Análisis',
    'Radiología e Imagenología Avanzada',
    'Quirófanos de Alta Tecnología',
    'Especialidades Médicas Integrales',
    'Banco de Sangre',
    'Maternidad y Neonatología',
    'Ambulancia y Traslado de Urgencia',
  ];

  // 💊 Catálogo de Servicios y Ventajas para Farmacias
  final List<String> _serviciosFarmacia = [
    'Servicio a Domicilio Express',
    'Consultorio Médico Adyacente',
    'Aceptamos Tarjetas de Crédito/Débito',
    'Medicamentos de Patente y Genéricos',
    'Servicio 24 Horas',
    'Programa Círculo de la Salud',
    'Facturación Electrónica',
    'Dermatología y Especialidad',
  ];

  List<String> _serviciosSeleccionados = [];

  bool _cargando = true;
  bool _actualizando = false;
  String _nombreOriginal = '';

  // Variables para la gestión de imágenes
  String _fotoUrlActual = '';
  XFile? _imagenSeleccionada;
  dynamic _vistaPreviaWebBytes;

  @override
  void initState() {
    super.initState();
    _cargarDatosOriginales();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _telefonoController.dispose();
    _whatsappController.dispose();
    _scoreController.dispose();
    _descripcionController.dispose();
    _urgenciasController.dispose();
    _horarioController.dispose();
    super.dispose();
  }

  // 🔥 LÓGICA DE FIREBASE: Cargar datos actuales
  Future<void> _cargarDatosOriginales() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection(widget.tipo)
          .doc(widget.estId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nombreOriginal = data['nombre'] ?? '';
          _nombreController.text = _nombreOriginal;
          _direccionController.text = data['direccion'] ?? '';
          _ciudadController.text =
              data['ciudad'] ?? AppConfig.ciudadesActivas[0];
          _telefonoController.text = data['telefono'] ?? '';
          _whatsappController.text = data['whatsapp'] ?? '';
          _scoreController.text = data['score'] ?? '5.0';
          _descripcionController.text = data['descripcion'] ?? '';
          _horarioController.text =
              data['horario'] ??
              (widget.tipo == 'hospitales'
                  ? 'Abierto las 24 horas (Lunes a Domingo)'
                  : 'Abierto de 8:00 AM a 10:00 PM');
          _fotoUrlActual = data['foto_url'] ?? '';

          if (widget.tipo == 'hospitales') {
            _urgenciasController.text = data['telefono_urgencias'] ?? '';
          }

          if (data['servicios'] != null && data['servicios'] is List) {
            _serviciosSeleccionados = List<String>.from(data['servicios']);
          }

          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos: $e');
    }
  }

  // 📸 LÓGICA DE SELECCIÓN DE IMAGEN
  Future<void> _seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (imagen != null) {
      final bytes = await imagen.readAsBytes();
      setState(() {
        _imagenSeleccionada = imagen;
        _vistaPreviaWebBytes = bytes;
      });
    }
  }

  // 🔥 LÓGICA DE FIREBASE: Actualizar datos y servicios
  Future<void> _actualizarInformacion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _actualizando = true);

    try {
      String urlFinalImagen = _fotoUrlActual;

      if (_imagenSeleccionada != null && _vistaPreviaWebBytes != null) {
        String base64Image = base64Encode(_vistaPreviaWebBytes);
        urlFinalImagen = 'data:image/png;base64,$base64Image';
      }

      Map<String, dynamic> datosActualizados = {
        'nombre': _nombreController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'ciudad': _ciudadController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'score': _scoreController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'horario': _horarioController.text.trim(),
        'servicios': _serviciosSeleccionados,
        'foto_url': urlFinalImagen,
      };

      if (widget.tipo == 'hospitales') {
        datosActualizados['telefono_urgencias'] = _urgenciasController.text
            .trim();
      }

      await FirebaseFirestore.instance
          .collection(widget.tipo)
          .doc(widget.estId)
          .update(datosActualizados);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Información y servicios actualizados con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _actualizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    bool esHospital = widget.tipo == 'hospitales';

    String tituloPagina = esHospital
        ? 'Panel de Hospital'
        : 'Panel de Farmacia';
    IconData iconoPagina = esHospital
        ? Icons.local_hospital_rounded
        : Icons.local_pharmacy_rounded;
    List<String> catalogoActual = esHospital
        ? _serviciosHospital
        : _serviciosFarmacia;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(),
      drawer: width < 1100 ? const PhoneMenuDrawer() : null,
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado
                      Row(
                        children: [
                          Icon(iconoPagina, color: Colors.blueGrey, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            tituloPagina,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1F36),
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text('Volver al Panel Administrador'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Editando: $_nombreOriginal',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Formulario
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Información Básica del Establecimiento',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Fotografía
                              _buildFieldLabel('Logotipo o Imagen de Fachada'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: _vistaPreviaWebBytes != null
                                          ? Image.memory(
                                              _vistaPreviaWebBytes!,
                                              fit: BoxFit.cover,
                                            )
                                          : _fotoUrlActual.isNotEmpty
                                          ? (_fotoUrlActual.startsWith(
                                                  'data:image',
                                                )
                                                ? Image.memory(
                                                    base64Decode(
                                                      _fotoUrlActual
                                                          .split(',')
                                                          .last,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  )
                                                : Image.network(
                                                    _fotoUrlActual,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (c, e, s) =>
                                                        const Icon(
                                                          Icons.broken_image,
                                                          color: Colors.grey,
                                                        ),
                                                  ))
                                          : Icon(
                                              iconoPagina,
                                              size: 40,
                                              color: const Color(0xFF94A3B8),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _seleccionarImagen,
                                        icon: const Icon(
                                          Icons.cloud_upload_outlined,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          'Subir Imagen',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF64748B,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Formatos admitidos: JPG, PNG. Máx 2MB.',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),

                              _buildFieldLabel('Nombre / Razón Social'),
                              TextFormField(
                                controller: _nombreController,
                                decoration: _inputStyle(
                                  esHospital
                                      ? 'Ej. Hospital de Especialidades'
                                      : 'Ej. Farmacia Central',
                                  Icons.business,
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Campo requerido'
                                    : null,
                              ),
                              const SizedBox(height: 20),

                              _buildFieldLabel('Descripción / Acerca de'),
                              TextFormField(
                                controller: _descripcionController,
                                maxLines: 3,
                                decoration: _inputStyle(
                                  'Describe brevemente los servicios del establecimiento...',
                                  Icons.notes,
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Campo requerido'
                                    : null,
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel('Dirección Física'),
                                        TextFormField(
                                          controller: _direccionController,
                                          decoration: _inputStyle(
                                            'Ej. Av. Principal #123, Zona Centro',
                                            Icons.location_on_outlined,
                                          ),
                                          validator: (v) =>
                                              v == null || v.isEmpty
                                              ? 'Campo requerido'
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel('Ciudad'),
                                        TextFormField(
                                          controller: _ciudadController,
                                          decoration: _inputStyle(
                                            'Ej. ${AppConfig.ciudadesActivas[0]}',
                                            Icons.map_outlined,
                                          ),
                                          validator: (v) =>
                                              v == null || v.isEmpty
                                              ? 'Campo requerido'
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel(
                                          'Teléfono General (Llamadas)',
                                        ),
                                        TextFormField(
                                          controller: _telefonoController,
                                          keyboardType: TextInputType.phone,
                                          decoration: _inputStyle(
                                            'Ej. 8711234567',
                                            Icons.phone,
                                          ),
                                          validator: (v) =>
                                              v == null || v.isEmpty
                                              ? 'Campo requerido'
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel(
                                          'WhatsApp (Cotizaciones)',
                                        ),
                                        TextFormField(
                                          controller: _whatsappController,
                                          keyboardType: TextInputType.phone,
                                          decoration: _inputStyle(
                                            'Ej. 8717654321',
                                            Icons.chat_bubble_outline_rounded,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel(
                                          'Horario de Operación',
                                        ),
                                        TextFormField(
                                          controller: _horarioController,
                                          decoration: _inputStyle(
                                            esHospital
                                                ? 'Ej. Abierto las 24 horas (Lunes a Domingo)'
                                                : 'Ej. Abierto de 8:00 AM a 10:00 PM',
                                            Icons.access_time_rounded,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel(
                                          'Calificación Destacada (1.0 - 5.0)',
                                        ),
                                        TextFormField(
                                          controller: _scoreController,
                                          keyboardType: TextInputType.number,
                                          decoration: _inputStyle(
                                            'Ej. 5.0',
                                            Icons.star_border_rounded,
                                          ),
                                          validator: (v) =>
                                              v == null || v.isEmpty
                                              ? 'Campo requerido'
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              if (esHospital) ...[
                                const SizedBox(height: 20),
                                _buildFieldLabel('Teléfono de Urgencias 24h'),
                                TextFormField(
                                  controller: _urgenciasController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _inputStyle(
                                    'Ej. 8711234567',
                                    Icons.phone_android_rounded,
                                  ),
                                ),
                              ],

                              // 🔑 SERVICIOS E INFRAESTRUCTURA (CHIPS)
                              const SizedBox(height: 24),
                              _buildFieldLabel('Servicios y Ventajas Clave'),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: catalogoActual.map((servicio) {
                                  bool seleccionado = _serviciosSeleccionados
                                      .contains(servicio);
                                  return FilterChip(
                                    label: Text(
                                      servicio,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: seleccionado
                                            ? Colors.white
                                            : const Color(0xFF334155),
                                        fontWeight: seleccionado
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    selected: seleccionado,
                                    selectedColor: esHospital
                                        ? AppConfig.primaryColor
                                        : const Color(0xFF0D9488),
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    checkmarkColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    onSelected: (bool selected) {
                                      setState(() {
                                        if (selected) {
                                          _serviciosSeleccionados.add(servicio);
                                        } else {
                                          _serviciosSeleccionados.remove(
                                            servicio,
                                          );
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),

                              const Divider(
                                height: 48,
                                color: Color(0xFFF1F5F9),
                              ),

                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: _actualizando
                                      ? null
                                      : _actualizarInformacion,
                                  icon: _actualizando
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.save_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                  label: const Text(
                                    'Guardar Cambios',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: esHospital
                                        ? AppConfig.primaryColor
                                        : const Color(0xFF0D9488),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFieldLabel(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        texto,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: widget.tipo == 'hospitales'
              ? AppConfig.primaryColor
              : const Color(0xFF0D9488),
          width: 1.5,
        ),
      ),
    );
  }
}
