import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // 👈 Requiere agregar image_picker en tu pubspec.yaml
import 'dart:convert'; // Para codificar la imagen de manera segura si es entorno Web
import '../widgets/custom_app_bar.dart';
import '../widgets/phone_menu_drawer.dart';

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
  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _urgenciasController =
      TextEditingController(); // Solo para hospitales

  bool _cargando = true;
  bool _actualizando = false;
  String _nombreOriginal = '';

  // Variables para la gestión de imágenes
  String _fotoUrlActual = '';
  XFile? _imagenSeleccionada;
  dynamic
  _vistaPreviaWebBytes; // Guarda los bytes temporales para la previsualización en Web

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
    _scoreController.dispose();
    _descripcionController.dispose();
    _urgenciasController.dispose();
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
          _ciudadController.text = data['ciudad'] ?? '';
          _telefonoController.text = data['telefono'] ?? '';
          _scoreController.text = data['score'] ?? '5.0';
          _descripcionController.text = data['descripcion'] ?? '';
          _fotoUrlActual =
              data['foto_url'] ?? ''; // Recupera el campo de la foto

          if (widget.tipo == 'hospitales') {
            _urgenciasController.text = data['telefono_urgencias'] ?? '';
          }
          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos: $e');
    }
  }

  // 📸 LÓGICA DE SELECCIÓN DE IMAGEN (Compatible Web y Celular)
  Future<void> _seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Optimiza el peso de manera automática
    );

    if (imagen != null) {
      final bytes = await imagen.readAsBytes();
      setState(() {
        _imagenSeleccionada = imagen;
        _vistaPreviaWebBytes =
            bytes; // Asigna los bytes para renderizar la vista previa en caliente
      });
    }
  }

  // 🔥 LÓGICA DE FIREBASE: Actualizar datos y subir imagen si aplica
  Future<void> _actualizarInformacion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _actualizando = true);

    try {
      String urlFinalImagen = _fotoUrlActual;

      // Si el administrador seleccionó una nueva imagen, la procesamos
      if (_imagenSeleccionada != null && _vistaPreviaWebBytes != null) {
        // Formato Base64 seguro para Cloud Firestore o Firebase Storage
        String base64Image = base64Encode(_vistaPreviaWebBytes);
        urlFinalImagen = 'data:image/png;base64,$base64Image';
      }

      Map<String, dynamic> datosActualizados = {
        'nombre': _nombreController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'ciudad': _ciudadController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'score': _scoreController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'foto_url':
            urlFinalImagen, // Guardamos la nueva imagen o mantenemos la anterior
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
            content: Text('¡Información y fotografía actualizadas con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Regresa al panel administrador
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
    String tituloPagina = widget.tipo == 'hospitales'
        ? 'Panel de Hospital'
        : 'Panel de Farmacia';
    IconData iconoPagina = widget.tipo == 'hospitales'
        ? Icons.local_hospital_rounded
        : Icons.local_pharmacy_rounded;

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
                      // Encabezado de la pantalla privada
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

                      // Sección de "Editar Perfil" con Formulario e Imagen Integrada
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

                              // 🖼️ SECCIÓN DINÁMICA DE FOTOGRAFÍA / LOGOTIPO
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
                                            ) // Previsualización local
                                          : _fotoUrlActual.isNotEmpty
                                          ? Image.network(
                                              _fotoUrlActual,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                  ),
                                            ) // Imagen de Firebase
                                          : Icon(
                                              iconoPagina,
                                              size: 40,
                                              color: const Color(0xFF94A3B8),
                                            ), // Icono por defecto
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
                                  'Ej. Sanatorio Español, Klyns Jardín',
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
                                            'Ej. Av. Allende 755',
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
                                            'Ej. Torreón',
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
                                        _buildFieldLabel('Teléfono General'),
                                        TextFormField(
                                          controller: _telefonoController,
                                          keyboardType: TextInputType.phone,
                                          decoration: _inputStyle(
                                            'Ej. 8717123456',
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

                              if (widget.tipo == 'hospitales') ...[
                                const SizedBox(height: 20),
                                _buildFieldLabel('Teléfono de Urgencias 24h'),
                                TextFormField(
                                  controller: _urgenciasController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _inputStyle(
                                    'Ej. 8717654321',
                                    Icons.phone_android_rounded,
                                  ),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Campo requerido'
                                      : null,
                                ),
                              ],

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
                                    backgroundColor: const Color(0xFF0061E0),
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
        borderSide: const BorderSide(color: Color(0xFF0061E0), width: 1.5),
      ),
    );
  }
}
