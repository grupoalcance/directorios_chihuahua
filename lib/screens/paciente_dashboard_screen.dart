import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_app_bar.dart'; // <-- IMPORTAMOS LA NUEVA BARRA

class PacienteDashboardScreen extends StatefulWidget {
  const PacienteDashboardScreen({super.key});

  @override
  State<PacienteDashboardScreen> createState() =>
      _PacienteDashboardScreenState();
}

// Agregamos SingleTickerProviderStateMixin para poder usar Tabs
class _PacienteDashboardScreenState extends State<PacienteDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Controladores básicos
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _apellidosCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();

  bool _isLoading = true;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 Pestañas
    _loadPacienteData();
  }

  Future<void> _loadPacienteData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          userData = doc.data() as Map<String, dynamic>;
          _nombreCtrl.text = userData?['nombre'] ?? '';
          _apellidosCtrl.text = userData?['apellidos'] ?? '';
          _telefonoCtrl.text = userData?['telefono'] ?? '';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    Map<String, dynamic> datosActualizados = {
      'nombre': _nombreCtrl.text.trim(),
      'apellidos': _apellidosCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
    };

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .update(datosActualizados);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '¡Datos actualizados con éxito!',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(), // <-- LA LÍNEA MÁGICA
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- LA BARRA DE PESTAÑAS ---
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                    tabs: const [
                      Tab(icon: Icon(Icons.edit), text: 'Editar Perfil'),
                      Tab(icon: Icon(Icons.star), text: 'Mis Reseñas'),
                      Tab(icon: Icon(Icons.favorite), text: 'Favoritos'),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- EL CONTENIDO DE LAS PESTAÑAS ---
                  SizedBox(
                    height:
                        800, // Altura base para que el contenido scrollee bien
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEditProfileForm(), // Pestaña 1
                        _buildMisResenasTab(), // Pestaña 2
                        _buildFavoritosTab(), // Pestaña 3
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

  // ==========================================
  // PESTAÑA 1: EDITAR PERFIL
  // ==========================================
  Widget _buildEditProfileForm() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Personal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const Divider(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _textField('Nombre(s)', _nombreCtrl)),
                const SizedBox(width: 20),
                Expanded(child: _textField('Apellidos', _apellidosCtrl)),
              ],
            ),
            _textField(
              'Teléfono celular',
              _telefonoCtrl,
              iconWidget: const Icon(Icons.phone, color: Colors.blue),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Guardar cambios',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PESTAÑA 2: MIS RESEÑAS
  // ==========================================
  Widget _buildMisResenasTab() {
    final String myUid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      // ATENCIÓN: collectionGroup busca la carpeta 'resenas' en TODOS los doctores
      stream: FirebaseFirestore.instance
          .collectionGroup('resenas')
          .where('paciente_id', isEqualTo: myUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint("EL ERROR ES: ${snapshot.error}");

          return const Center(
            child: Text(
              'Error al cargar las reseñas. (Recuerda crear el índice en Firebase)',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyStateMessage(
            Icons.star_border,
            'Aún no has escrito ninguna reseña.\nVisita el perfil de un médico para calificarlo.',
          );
        }

        return ListView.separated(
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 15),
          itemBuilder: (context, index) {
            var resena =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            int estrellas = resena['calificacion'] ?? 5;
            String comentario = resena['comentario'] ?? '';

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.medical_services,
                        color: Colors.blueGrey,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Opinión enviada a un médico',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < estrellas ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(
                    comentario.isEmpty
                        ? 'Sin comentarios adicionales.'
                        : comentario,
                    style: TextStyle(
                      color: comentario.isEmpty ? Colors.grey : Colors.black87,
                      fontStyle: comentario.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // PESTAÑA 3: FAVORITOS
  // ==========================================
  Widget _buildFavoritosTab() {
    final String myUid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      // Buscamos en la carpeta 'favoritos' dentro del perfil del paciente
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(myUid)
          .collection('favoritos')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyStateMessage(
            Icons.favorite_border,
            'No tienes médicos favoritos guardados.\nDale clic al corazón en el perfil de un doctor para guardarlo aquí.',
          );
        }

        return ListView.separated(
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 15),
          itemBuilder: (context, index) {
            var favorito =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            String docId =
                snapshot.data!.docs[index].id; // El ID del doctor guardado

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: const Icon(Icons.person, color: Colors.blue),
              ),
              title: Text(
                favorito['nombre'] ?? 'Doctor',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(favorito['especialidad'] ?? 'Especialista'),
              trailing: IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () {
                  // Borrar de favoritos
                  FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(myUid)
                      .collection('favoritos')
                      .doc(docId)
                      .delete();
                },
              ),
            );
          },
        );
      },
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _emptyStateMessage(IconData icon, String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 50),
        Icon(icon, size: 60, color: Colors.grey.shade400),
        const SizedBox(height: 20),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      ],
    );
  }

  Widget _textField(
    String label,
    TextEditingController ctrl, {
    Widget? iconWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: iconWidget != null
              ? Padding(padding: const EdgeInsets.all(12.0), child: iconWidget)
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade50,
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
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              iniciales.toUpperCase(),
              style: TextStyle(
                color: Colors.blue.shade800,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 25),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_nombreCtrl.text} ${_apellidosCtrl.text}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Paciente',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
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
}
