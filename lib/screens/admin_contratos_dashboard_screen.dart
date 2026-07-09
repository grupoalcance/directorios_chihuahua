import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/phone_menu_drawer.dart';
import '../services/auth_service.dart';

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
                child: Column(
                  children: [
                    const Icon(
                      Icons.assignment_late_outlined,
                      size: 48,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      rol == 'admin'
                          ? 'No se han encontrado contratos registrados por los vendedores.'
                          : 'Aún no has registrado ningún contrato en tu historial.',
                      style: const TextStyle(
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
                          'Firmas',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Alta Web',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Auditoría',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: documentos.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final perfil = data['perfil_medico'] ?? {};
                      final metadata = data['metadata'] ?? {};
                      final firmas = metadata['firmas_digitalizadas'] ?? {};

                      String medico =
                          perfil['nombre_establecimiento'] ?? 'Sin nombre';
                      String vendedor = metadata['asesor_comercial'] ?? 'N/A';
                      bool pagado = metadata['pagado'] ?? false;
                      bool clienteFirmo = firmas['cliente_firmó'] ?? false;
                      bool asesorFirmo = firmas['asesor_firmó'] ?? false;
                      bool deAlta = perfil['activo'] ?? false;

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
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: clienteFirmo
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.badge_outlined,
                                  size: 16,
                                  color: asesorFirmo
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Icon(
                              deAlta
                                  ? Icons.cloud_done_rounded
                                  : Icons.cloud_upload_outlined,
                              color: deAlta
                                  ? Colors.green
                                  : Colors.amber.shade700,
                              size: 20,
                            ),
                          ),
                          DataCell(
                            ElevatedButton(
                              onPressed: () =>
                                  _verDetalleContrato(doc.id, data),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: const Text(
                                'Auditar Contrato',
                                style: TextStyle(fontSize: 12),
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
    final facturacion =
        data['datos_facturacion'] ??
        {}; // 🔑 Mapeado al nuevo mapa estructurado
    final direccionFiscal = facturacion['direccion_fiscal'] ?? {};
    final agendaHorarios = data['agenda_horarios'] ?? {};
    final anexos = data['archivos_anexos_urls'] ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          perfil['nombre_establecimiento'] ??
                              'Expediente Legal',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Código único de Registro: $docId',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildSeccionAuditoria(
                      titulo: 'Firmante y Poder Legal',
                      icon: Icons.draw_rounded,
                      datos: [
                        'Nombre del Firmante: ${metadata['nombre_firmante'] ?? "N/A"}',
                        'Cargo del Puesto: ${metadata['puesto_cargo'] ?? "N/A"}',
                        'Teléfono de Verificación: ${metadata['telefono_firmante'] ?? "N/A"}',
                        'Firma de Cliente: ${metadata['firmas_digitalizadas']?['cliente_firmó'] == true ? "Firmado Digitalmente" : "Falta Firma"}',
                        'Firma de Asesor: ${metadata['firmas_digitalizadas']?['asesor_firmó'] == true ? "Firmado Digitalmente" : "Falta Firma"}',
                      ],
                    ),
                    _buildSeccionAuditoria(
                      titulo: 'Términos Comerciales y Disponibilidad',
                      icon: Icons.monetization_on_outlined,
                      datos: [
                        'Estatus de Liquidación: ${metadata['pagado'] == true ? "PAGADO COMPLETO" : "PAGO PENDIENTE"}',
                        'Costo de Consulta Regular: \$${perfil['costo_consulta'] ?? "0.00"}', // 🔑 Añadido a auditoría
                        'Fecha de Alta Solicitada: ${perfil['inicio_directorio'] ?? "N/A"}',
                        'Especialidad Médica: ${perfil['especialidad'] ?? "N/A"}',
                        'Atiende Emergencias 24/7: ${agendaHorarios['atiende_emergencias'] == true ? "SÍ" : "NO"}', // 🔑 Mapeado de booleano
                        'Visita Hospital Privado: ${agendaHorarios['visita_hospital_privado'] == true ? "SÍ" : "NO"}', // 🔑 Mapeado de booleano
                      ],
                    ),
                    _buildSeccionAuditoria(
                      titulo: 'Validación Sanitaria (Cofepris)',
                      icon: Icons.health_and_safety_outlined,
                      datos: [
                        'Aviso de Funcionamiento Hospital: ${regulacion['aviso_hospital'] == true ? "CUMPLE (${regulacion['aviso_hospital_num']})" : "No Aplica / No tiene"}',
                        'Aviso de Publicidad Individual: ${regulacion['aviso_individual'] == true ? "CUMPLE (${regulacion['aviso_individual_num']})" : "No Aplica / No tiene"}',
                        'Solicitó Gestión de Trámite Técnico: ${regulacion['requiere_ayuda_tramite'] == true ? "SÍ" : "NO"}',
                      ],
                    ),
                    // 🔑 SECCIÓN EXHAUSTIVA DE FACTURACIÓN ACTUALIZADA CON LA NUEVA DIRECCIÓN FISCAL
                    _buildSeccionAuditoria(
                      titulo: 'Expediente de Facturación SAT',
                      icon: Icons.receipt_long_outlined,
                      datos: [
                        'Razón Social Fiscal: ${facturacion['razon_social'] ?? "N/A"}',
                        'RFC Contribuyente: ${facturacion['rfc'] ?? "N/A"}',
                        'Correo envío Facturas: ${facturacion['email_factura'] ?? "N/A"}',
                        'Calle Fiscal: ${direccionFiscal['calle'] ?? "N/A"}',
                        'No. Ext/Int Fiscal: ${direccionFiscal['numero'] ?? "N/A"}',
                        'Colonia Fiscal: ${direccionFiscal['colonia'] ?? "N/A"}',
                        'Ciudad o Municipio Fiscal: ${direccionFiscal['ciudad_municipio'] ?? "N/A"}',
                        'Inicio de Facturación (De): ${facturacion['inicio_facturacion_de'] ?? "N/A"}',
                        'Modalidad de Facturación: ${facturacion['modalidad'] ?? "Único"}',
                      ],
                    ),
                    _buildSeccionAuditoria(
                      titulo: 'Expediente Gráfico (URLs de Evidencia Cloud)',
                      icon: Icons.folder_shared_outlined,
                      datos: [
                        'Fotografía del Doctor: ${anexos['foto_medico'] ?? "No se cargó archivo"}',
                        'Fachada del Consultorio: ${anexos['foto_consultorio_fachada'] ?? "No se cargó archivo"}',
                        'Logotipo de Identidad: ${anexos['logo_alta_resolucion'] ?? "No se cargó archivo"}',
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        fixedSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cerrar Auditoría',
                        style: TextStyle(color: Color(0xFF475569)),
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
                                '¡Contrato auditado, aprobado y dado de alta en la web pública!',
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
                        'Aprobar Contrato y Dar de Alta',
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeccionAuditoria({
    required String titulo,
    required IconData icon,
    required List<String> datos,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: datos
                  .map(
                    (dato) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Text(
                        dato,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
