import 'package:flutter/material.dart';
import 'dart:convert';
import 'doctor_profile_screen.dart';
import '../widgets/custom_app_bar.dart'; // <-- IMPORTAMOS LA NUEVA BARRA

class BlogDetailScreen extends StatefulWidget {
  final Map<String, dynamic> blogPost;
  final String doctorName;
  final List<dynamic> allBlogs;
  final Map<String, dynamic> doctorData;

  const BlogDetailScreen({
    super.key,
    required this.blogPost,
    required this.doctorName,
    required this.allBlogs,
    required this.doctorData,
  });

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  @override
  Widget build(BuildContext context) {
    // String title = widget.blogPost['title'] ?? 'Sin título';
    String title = widget.blogPost['title'] ?? 'Sin título';
    String content = widget.blogPost['desc'] ?? 'Sin contenido';
    String? imgData = widget.blogPost['img'];

    List<dynamic> otrosBlogs = widget.allBlogs
        .where((blog) => blog != widget.blogPost)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(), // <-- LA LÍNEA MÁGICA
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Botón de regresar discreto
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back, size: 18, color: Colors.blue),
                      SizedBox(width: 5),
                      Text(
                        'Volver',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 1. Título Gigante
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1F36),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 25),

                // 2. Información del Autor (HACEMOS CLIC EN EL NOMBRE)
                InkWell(
                  onTap: () {
                    // Al hacer clic, abrimos el perfil del doctor
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DoctorProfileScreen(doctorData: widget.doctorData),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize
                          .min, // Para que no ocupe toda la pantalla
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.blue,
                          child: Icon(
                            Icons.medical_services,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Escrito por ${widget.doctorName}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 35),

                // 3. Imagen de Portada
                if (imgData != null && imgData.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: imgData.startsWith('http')
                        ? Image.network(
                            imgData,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.memory(
                            base64Decode(imgData),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                const SizedBox(height: 40),

                // 4. El Texto del Artículo
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 60),

                // 5. SECCIÓN DE ARTÍCULOS SUGERIDOS
                if (otrosBlogs.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 30),
                  Text(
                    'Más artículos de ${widget.doctorName}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 280,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: otrosBlogs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 20),
                      itemBuilder: (context, index) {
                        return _buildSuggestedBlogCard(
                          context,
                          otrosBlogs[index],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TARJETITA DE SUGERENCIAS ---
  Widget _buildSuggestedBlogCard(
    BuildContext context,
    Map<String, dynamic> post,
  ) {
    String? imgData = post['img'];

    return Container(
      width: 250,
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
            flex: 2,
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['title'] ?? 'Sin título',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlogDetailScreen(
                            blogPost: post,
                            doctorName: widget.doctorName,
                            allBlogs: widget.allBlogs,
                            doctorData: widget.doctorData, // Pasamos el dato
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
