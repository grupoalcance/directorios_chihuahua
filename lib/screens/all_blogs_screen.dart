import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'blog_detail_screen.dart';
import '../widgets/custom_app_bar.dart';

class AllBlogsScreen extends StatelessWidget {
  const AllBlogsScreen({super.key});

  // --- REUTILIZAMOS LA FUNCIÓN PARA DESCARGAR TODOS LOS BLOGS ---
  Future<List<Map<String, dynamic>>> _fetchAllBlogs() async {
    List<Map<String, dynamic>> allBlogs = [];

    try {
      QuerySnapshot doctores = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('rol', isEqualTo: 'medico')
          .where('tipo_perfil', isEqualTo: 'pro')
          .get();

      for (var doc in doctores.docs) {
        String doctorName = "Dr(a). ${doc['nombre']} ${doc['apellidos']}"
            .trim();

        QuerySnapshot blogsSnapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(doc.id)
            .collection('mis_blogs')
            .get();

        for (var blogDoc in blogsSnapshot.docs) {
          var blogData = blogDoc.data() as Map<String, dynamic>;
          blogData['doctorName'] = doctorName;
          blogData['doctorData'] = doc.data() as Map<String, dynamic>;
          blogData['doctorData']['uid'] = doc.id;
          allBlogs.add(blogData);
        }
      }

      allBlogs.sort((a, b) {
        Timestamp timeA = a['fecha'] ?? Timestamp.now();
        Timestamp timeB = b['fecha'] ?? Timestamp.now();
        return timeB.compareTo(timeA);
      });
    } catch (e) {
      debugPrint("🚨 ERROR AL DESCARGAR BLOGS: $e");
    }

    return allBlogs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Blog de Salud',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Artículos, consejos y noticias médicas escritas por nuestros especialistas destacados.',
                  style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                ),
                const SizedBox(height: 40),

                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchAllBlogs(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(50.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(50.0),
                          child: Text(
                            'Aún no hay artículos publicados.\n¡Vuelve pronto!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                        ),
                      );
                    }

                    List<Map<String, dynamic>> globalBlogs = snapshot.data!;

                    // Hacemos una cuadrícula responsiva (Grid)
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        // Si la pantalla es grande caben 3 columnas, si es mediana 2, si es celular 1
                        int crossAxisCount = constraints.maxWidth > 900
                            ? 3
                            : constraints.maxWidth > 600
                            ? 2
                            : 1;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 25,
                                mainAxisSpacing: 25,
                                childAspectRatio:
                                    0.85, // Proporción de la tarjeta
                              ),
                          itemCount: globalBlogs.length,
                          itemBuilder: (context, index) {
                            return _buildBlogCard(
                              context,
                              globalBlogs[index],
                              globalBlogs,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlogCard(
    BuildContext context,
    Map<String, dynamic> post,
    List<Map<String, dynamic>> allBlogs,
  ) {
    String? imgData = post['img'];
    String doctorName = post['doctorName'] ?? 'Médico Especialista';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: (imgData != null && imgData.isNotEmpty)
                  ? (imgData.startsWith('http')
                        ? Image.network(
                            imgData,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.memory(
                            base64Decode(imgData),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ))
                  : Image.network(
                      'https://via.placeholder.com/400x300',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['title'] ?? 'Sin título',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Por $doctorName',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  post['desc'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlogDetailScreen(
                            blogPost: post,
                            doctorName: doctorName,
                            allBlogs: allBlogs,
                            doctorData: post['doctorData'],
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Leer más',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
