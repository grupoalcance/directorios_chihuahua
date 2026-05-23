import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'login_screen.dart';
import 'doctor_dashboard_screen.dart'; // <-- IMPORTAMOS EL DASHBOARD DEL DOCTOR

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0; // <-- NUEVO SISTEMA DE TABS MÁS SEGURO

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Funciones para manipular la base de datos
  Future<void> _toggleEstadoDoctor(String uid, bool estadoActual) async {
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
      'activo': !estadoActual,
    });
  }

  Future<void> _toggleNivelDoctor(String uid, String nivelActual) async {
    String nuevoNivel = nivelActual == 'pro' ? 'basico' : 'pro';
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
      'tipo_perfil': nuevoNivel,
    });
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
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
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
            return const Center(child: Text('No hay datos.'));
          }

          final usuarios = snapshot.data!.docs;

          // Separar doctores y pacientes
          final doctores = usuarios
              .where((doc) => doc['rol'] == 'medico')
              .toList();
          final pacientes = usuarios
              .where((doc) => doc['rol'] == 'paciente')
              .toList();

          // Calcular KPIs
          int perfilesActivos = 0;
          int perfilesDestacados = 0;
          int totalResenas = 0;
          int totalClicsWA = 0;

          for (var doc in doctores) {
            var data = doc.data() as Map<String, dynamic>;
            if (data['activo'] ?? true) perfilesActivos++;
            if (data['tipo_perfil'] == 'pro') perfilesDestacados++;
            totalResenas += (data['reseñas_count'] as int?) ?? 0;
            totalClicsWA += (data['clics_wa'] as int?) ?? 0;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TARJETAS DE KPIs ---
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    _buildKpiCard(
                      'Doctores registrados',
                      doctores.length.toString(),
                      const Icon(
                        Icons.medical_services,
                        color: Colors.blue,
                        size: 30,
                      ),
                      Colors.blue,
                    ),
                    _buildKpiCard(
                      'Perfiles activos',
                      perfilesActivos.toString(),
                      const Icon(
                        Icons.check_box,
                        color: Colors.green,
                        size: 30,
                      ),
                      Colors.green,
                    ),
                    _buildKpiCard(
                      'Perfiles destacados',
                      perfilesDestacados.toString(),
                      const Icon(Icons.star, color: Colors.amber, size: 30),
                      Colors.amber,
                    ),
                    _buildKpiCard(
                      'Pacientes',
                      pacientes.length.toString(),
                      const Icon(Icons.people, color: Colors.purple, size: 30),
                      Colors.purple,
                    ),
                    _buildKpiCard(
                      'Reseñas totales',
                      totalResenas.toString(),
                      const Icon(
                        Icons.comment,
                        color: Colors.pinkAccent,
                        size: 30,
                      ),
                      Colors.pinkAccent,
                    ),
                    // 👇 ÍCONO DE WHATSAPP SOLUCIONADO 👇
                    _buildKpiCard(
                      'Clics en WA',
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

                // --- TABS ---
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
                    onTap: (index) {
                      setState(() {
                        _currentTabIndex = index;
                      });
                    },
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.medical_services_outlined),
                        text: 'Doctores',
                      ),
                      Tab(icon: Icon(Icons.people_outline), text: 'Pacientes'),
                      Tab(icon: Icon(Icons.bar_chart), text: 'Estadísticas'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- CONTENIDO DE LOS TABS ---
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
                  child: _buildCurrentTabContent(doctores, pacientes),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildCurrentTabContent(
    List<QueryDocumentSnapshot> doctores,
    List<QueryDocumentSnapshot> pacientes,
  ) {
    if (_currentTabIndex == 0) return _buildDoctoresTable(doctores);
    if (_currentTabIndex == 1) return _buildPacientesTable(pacientes);
    return _buildEstadisticasList(doctores);
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

  Widget _buildDoctoresTable(List<QueryDocumentSnapshot> doctores) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
        columns: const [
          DataColumn(label: Text('Doctor')),
          DataColumn(label: Text('Especialidad')),
          DataColumn(label: Text('Cédula')),
          DataColumn(label: Text('Nivel')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Visitas')),
          DataColumn(label: Text('WA')),
          DataColumn(label: Text('Reseñas')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: doctores.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          bool isActive = data['activo'] ?? true;
          bool isPro = data['tipo_perfil'] == 'pro';
          String uid = doc.id;

          String iniciales =
              (data['nombre']?[0] ?? '') + (data['apellidos']?[0] ?? '');

          return DataRow(
            cells: [
              DataCell(
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DoctorDashboardScreen(adminViewUid: uid),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.teal,
                        radius: 15,
                        child: Text(
                          iniciales.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Dr. ${data['nombre']} ${data['apellidos']}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(Text(data['especialidad'] ?? '---')),
              DataCell(Text(data['cedula'] ?? '---')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPro ? Colors.green : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPro)
                        const Icon(Icons.star, color: Colors.white, size: 12),
                      Text(
                        isPro ? ' DESTACADO' : 'BÁSICO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                Row(
                  children: [
                    Icon(
                      isActive ? Icons.circle : Icons.circle_outlined,
                      color: isActive ? Colors.green : Colors.red,
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isActive ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                Text(
                  '${data['visitas'] ?? 0}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${data['clics_wa'] ?? 0}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${data['reseñas_count'] ?? 0}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataCell(
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _toggleNivelDoctor(
                        uid,
                        data['tipo_perfil'] ?? 'basico',
                      ),
                      icon: Icon(
                        Icons.star,
                        color: isPro ? Colors.grey : Colors.amber,
                        size: 16,
                      ),
                      label: Text(
                        isPro ? 'Quitar Pro' : 'Destacar',
                        style: TextStyle(
                          color: isPro ? Colors.grey : Colors.blue.shade800,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: isActive
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isActive
                                ? Colors.red.shade200
                                : Colors.green.shade200,
                          ),
                        ),
                      ),
                      onPressed: () => _toggleEstadoDoctor(uid, isActive),
                      child: Text(
                        isActive ? 'Desactivar' : 'Activar',
                        style: TextStyle(
                          color: isActive ? Colors.red : Colors.green,
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
    );
  }

  Widget _buildPacientesTable(List<QueryDocumentSnapshot> pacientes) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: DataTable(
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Teléfono')),
          DataColumn(label: Text('Correo')),
        ],
        rows: pacientes.asMap().entries.map((entry) {
          int index = entry.key + 1;
          var data = entry.value.data() as Map<String, dynamic>;
          return DataRow(
            cells: [
              DataCell(
                Text(
                  index.toString(),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              DataCell(
                Text(
                  '${data['nombre']} ${data['apellidos']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  data['telefono'] ?? '---',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              DataCell(
                Text(
                  data['email'] ?? data['correo'] ?? '---',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          );
        }).toList(),
      ),
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
            child: Icon(Icons.person, color: Colors.white),
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
}
