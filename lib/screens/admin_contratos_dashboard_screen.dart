import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/phone_menu_drawer.dart';
import '../services/auth_service.dart';
import 'dart:convert';

class AdminContratosDashboardScreen extends StatefulWidget {
  const AdminContratosDashboardScreen({super.key});

  @override
  State<AdminContratosDashboardScreen> createState() =>
      _AdminContratosDashboardScreenState();
}

class _AdminContratosDashboardScreenState
    extends State<AdminContratosDashboardScreen> {
  Future<Map<String, dynamic>?> _obtenerDatosUsuarioActual() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data() != null) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(),
      drawer: width < 1100 ? const PhoneMenuDrawer() : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera Exclusiva del Panel de Contratos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Módulo de Contratos y Membresías',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Text(
                          'Validación de firmas digitalizadas, estatus de pago y auditoría de cierres comerciales.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Actualizar Lista'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Monitor de contratos desde la colección 'registro_contratos'
                _buildStreamContratos(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreamContratos() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _obtenerDatosUsuarioActual(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          );
        }

        final userData = userSnapshot.data;
        String rol = (userData?['rol'] ?? 'vendedor')
            .toString()
            .trim()
            .toLowerCase();
        String nombreAsesor = (userData?['nombre'] ?? '').toString().trim();

        Query queryContratos = FirebaseFirestore.instance.collection(
          'registro_contratos',
        );

        if (rol == 'vendedor' && nombreAsesor.isNotEmpty) {
          queryContratos = queryContratos.where(
            'metadata.asesor_comercial',
            isEqualTo: nombreAsesor,
          );
        }

        queryContratos = queryContratos.orderBy(
          'metadata.fecha_captura',
          descending: true,
        );

        return StreamBuilder<QuerySnapshot>(
          stream: queryContratos.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al conectar con el servidor: ${snapshot.error}',
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              );
            }

            final documentos = snapshot.data?.docs ?? [];

            if (documentos.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.assignment_late_outlined,
                      size: 48,
                      color: Color(0xFF94A3B8),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No se han encontrado contratos registrados por los vendedores.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      const Color(0xFFF8FAFC),
                    ),
                    dataRowHeight: 64,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Establecimiento / Médico',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Vendedor',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Estatus Pago',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Expediente Digital',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: documentos.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final perfil = data['perfil_medico'] ?? {};
                      final metadata = data['metadata'] ?? {};

                      String medico =
                          perfil['nombre_establecimiento'] ?? 'Sin nombre';
                      String vendedor = metadata['asesor_comercial'] ?? 'N/A';
                      bool pagado = metadata['pagado'] ?? false;

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              medico,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(Text(vendedor)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: pagado
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                pagado ? 'PAGADO' : 'PENDIENTE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: pagado
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _verDetalleContrato(doc.id, data),
                              icon: const Icon(
                                Icons.analytics_outlined,
                                size: 14,
                              ),
                              label: const Text(
                                'Revisar Expediente',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _verDetalleContrato(String docId, Map<String, dynamic> data) {
    final perfil = data['perfil_medico'] ?? {};
    final metadata = data['metadata'] ?? {};
    final regulacion = data['regulacion_sanitaria'] ?? {};
    final facturacion = data['datos_facturacion'] ?? {};
    final direccionFiscal = facturacion['direccion_fiscal'] ?? {};
    final agendaHorarios = data['agenda_horarios'] ?? {};
    final anexos = data['archivos_anexos_urls'] ?? {};
    final ubicacion = data['ubicacion_consultorio'] ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF64748B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Barra de control del visor
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Visor de Expediente Digital (Vista Previa)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // =========================================================================
              // 📄 VISTA DE HOJA MEMBRETADA DIGITAL (ESTILO REPORTE / PDF)
              // =========================================================================
              Expanded(
                child: Center(
                  child: Container(
                    // 🔑 PARÁMETRO CORREGIDO CON BOXCONSTRAINTS
                    constraints: const BoxConstraints(maxWidth: 850),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListView(
                      children: [
                        // Encabezado del reporte
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'MÉDICOS LAGUNA',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0061E0),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Directorio Médico Web de la Comarca Laguna',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'REF: ${docId.toUpperCase().substring(0, 8)}',
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(thickness: 2, color: Color(0xFF0F172A)),
                        const SizedBox(height: 15),

                        Center(
                          child: Text(
                            'EXPEDIENTE DE CONTRATACIÓN Y AUDITORÍA COMERCIAL',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Bloque 1: Información General
                        _buildFilaPdf(
                          titulo: 'Establecimiento / Médico',
                          valor: perfil['nombre_establecimiento'],
                        ),
                        _buildFilaPdf(
                          titulo: 'Especialidad Registrada',
                          valor: perfil['especialidad'],
                        ),
                        _buildFilaPdf(
                          titulo: 'Costo de Consulta Regular',
                          valor: '\$${perfil['costo_consulta'] ?? "0.00"} M.N.',
                        ),
                        _buildFilaPdf(
                          titulo: 'Asesor Comercial / Vendedor',
                          valor: metadata['asesor_comercial'],
                        ),
                        _buildFilaPdf(
                          titulo: 'Periodo Gratuito',
                          valor:
                              'Del ${perfil['periodo_gratuito']?['del'] ?? "N/A"} al ${perfil['periodo_gratuito']?['al'] ?? "N/A"}',
                        ),
                        _buildFilaPdf(
                          titulo: 'Estatus de Cobro',
                          valor: metadata['pagado'] == true
                              ? 'LIQUIDADO / PAGADO'
                              : 'PENDIENTE DE PAGO',
                          esAlerta: metadata['pagado'] != true,
                        ),

                        const SizedBox(height: 20),
                        _buildSubtituloPdf('REGULACIÓN SANITARIA (COFEPRIS)'),
                        _buildFilaPdf(
                          titulo: 'Aviso Hospitalario',
                          valor: regulacion['aviso_hospital'] == true
                              ? 'CUMPLE (No: ${regulacion['aviso_hospital_num']})'
                              : 'No Registrado / No aplica',
                        ),
                        _buildFilaPdf(
                          titulo: 'Aviso de Publicidad Individual',
                          valor: regulacion['aviso_individual'] == true
                              ? 'CUMPLE (No: ${regulacion['aviso_individual_num']})'
                              : 'No Registrado / No aplica',
                        ),
                        _buildFilaPdf(
                          titulo: 'Requiere Apoyo Técnico en Trámite',
                          valor: regulacion['requiere_ayuda_tramite'] == true
                              ? 'SÍ'
                              : 'NO',
                        ),

                        const SizedBox(height: 20),
                        _buildSubtituloPdf('DATOS FISCALES DE FACTURACIÓN'),
                        _buildFilaPdf(
                          titulo: 'Razón Social',
                          valor: facturacion['razon_social'],
                        ),
                        _buildFilaPdf(titulo: 'RFC', valor: facturacion['rfc']),
                        _buildFilaPdf(
                          titulo: 'Correo Electrónico SAT',
                          valor: facturacion['email_factura'],
                        ),
                        _buildFilaPdf(
                          titulo: 'Domicilio Fiscal Completo',
                          valor:
                              '${direccionFiscal['calle'] ?? "N/A"} No. ${direccionFiscal['numero'] ?? "N/A"}, Col. ${direccionFiscal['colonia'] ?? "N/A"}, ${direccionFiscal['ciudad_municipio'] ?? "N/A"}',
                        ),
                        _buildFilaPdf(
                          titulo: 'Modalidad contratada',
                          valor:
                              '${facturacion['modalidad'] ?? "Único"} (Fecha de cargo: ${facturacion['inicio_facturacion_de'] ?? "N/A"})',
                        ),

                        const SizedBox(height: 20),
                        _buildSubtituloPdf('LOGÍSTICA Y AGENDA DE CONSULTORIO'),
                        _buildFilaPdf(
                          titulo: 'Domicilio de Atención',
                          valor:
                              '${ubicacion['calle'] ?? "N/A"} No. ${ubicacion['numero'] ?? "N/A"}, Col. ${ubicacion['colonia'] ?? "N/A"}, ${ubicacion['ciudad'] ?? "N/A"}',
                        ),
                        _buildFilaPdf(
                          titulo: 'Teléfonos Reservaciones',
                          valor: ubicacion['telefonos_citas'],
                        ),
                        _buildFilaPdf(
                          titulo: 'Atiende Emergencias Médicas 24/7',
                          valor: agendaHorarios['atiende_emergencias'] == true
                              ? 'SÍ (Activo en Web Pública)'
                              : 'NO',
                        ),
                        _buildFilaPdf(
                          titulo: 'Realiza Interconsultas Privadas',
                          valor:
                              agendaHorarios['visita_hospital_privado'] == true
                              ? 'SÍ'
                              : 'NO',
                        ),

                        const SizedBox(height: 35),
                        const Divider(thickness: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 15),

                        // =========================================================================
                        // ✍️ SECCIÓN DE FIRMAS AUTÓGRAFAS INTEGRADAS AL REPORTE
                        // =========================================================================
                        const Center(
                          child: Text(
                            'FIRMAS ELECTRÓNICAS DE CONFORMIDAD Y CIERRE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Eje Firma Cliente
                            Column(
                              children: [
                                Container(
                                  width: 220,
                                  height: 90,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    color: const Color(0xFFFAFBFD),
                                  ),
                                  child:
                                      data['firma_cliente_base64'] != null &&
                                          data['firma_cliente_base64']
                                              .toString()
                                              .isNotEmpty
                                      ? Image.memory(
                                          base64Decode(
                                            data['firma_cliente_base64']
                                                .toString()
                                                .split(',')
                                                .last,
                                          ),
                                          fit: BoxFit.contain,
                                        )
                                      : const Text(
                                          '⚠️ Trazo no capturado',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  metadata['nombre_firmante'] ??
                                      'Representante Legal',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  metadata['puesto_cargo'] ??
                                      'Cliente / Médico',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            // Eje Firma Asesor
                            Column(
                              children: [
                                Container(
                                  width: 220,
                                  height: 90,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    color: const Color(0xFFFAFBFD),
                                  ),
                                  child:
                                      data['firma_asesor_base64'] != null &&
                                          data['firma_asesor_base64']
                                              .toString()
                                              .isNotEmpty
                                      ? Image.memory(
                                          base64Decode(
                                            data['firma_asesor_base64']
                                                .toString()
                                                .split(',')
                                                .last,
                                          ),
                                          fit: BoxFit.contain,
                                        )
                                      : const Text(
                                          '⚠️ Trazo no capturado',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  metadata['asesor_comercial'] ??
                                      'Asesor Comercial',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const Text(
                                  'Agencia Alcance Comercial',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Controles del pie del modal fuera del documento
              Container(
                // 🔑 PARÁMETRO CORREGIDO CON BOXCONSTRAINTS
                constraints: const BoxConstraints(maxWidth: 850),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white60),
                          fixedSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Cerrar Expediente',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          final authService = AuthService();
                          bool exito = await authService
                              .migrarContratoAPerfilPublico(
                                contratoId: docId,
                                contratoData: data,
                              );

                          if (!mounted) return;
                          navigator.pop();

                          if (exito) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '¡Expediente aprobado y dado de alta en la web pública con éxito!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Error al procesar la clonación del expediente hacia perfiles públicos.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.verified_user_outlined,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Aprobar y Sincronizar en Directorio',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0061E0),
                          fixedSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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

  // Helper visual para maquetar filas con estructura formal de reporte
  Widget _buildFilaPdf({
    required String titulo,
    required dynamic valor,
    bool esAlerta = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 210,
            child: Text(
              '$titulo:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              (valor ?? 'N/A').toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: esAlerta ? FontWeight.bold : FontWeight.w500,
                color: esAlerta
                    ? const Color(0xFFB91C1C)
                    : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper para pintar subtítulos divisores en el reporte
  Widget _buildSubtituloPdf(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Color(0xFF0061E0),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSeccionAuditoria({
    required String titulo,
    required IconData icon,
    required List<String> datos,
  }) {
    return const SizedBox.shrink();
  }
}
