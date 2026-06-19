import 'package:flutter/material.dart';

class PhoneMenuDrawer extends StatelessWidget {
  const PhoneMenuDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Encabezado del menú lateral
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Alignment(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Médicos Laguna',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 1. ¿Quiénes somos?
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.blue),
            title: const Text('¿Quiénes somos?'),
            onPressed: () => Navigator.pop(context),
          ),

          // 2. Desplegable Ciudad para Celular (Usando ExpansionTile)
          ExpansionTile(
            leading: const Icon(Icons.location_city, color: Colors.blue),
            title: const Text('Ciudad'),
            children: [
              _buildSubItem(context, 'Torreón'),
              _buildSubItem(context, 'Gómez Palacio'),
              _buildSubItem(context, 'Lerdo'),
              _buildSubItem(context, 'San Pedro'),
              _buildSubItem(context, 'Fco. I. Madero'),
              _buildSubItem(context, 'Matamoros'),
            ],
          ),

          // 3. Desplegable Especialidad para Celular
          ExpansionTile(
            leading: const Icon(Icons.medical_services_outlined, color: Colors.blue),
            title: const Text('Especialidad'),
            children: [
              _buildSubItem(context, 'Cardiología'),
              _buildSubItem(context, 'Pediatría'),
              _buildSubItem(context, 'Ginecología'),
            ],
          ),

          // 4. Hospitales
          ListTile(
            leading: const Icon(Icons.local_hospital, color: Colors.blue),
            title: const Text('Hospitales'),
            onPressed: () => Navigator.pop(context),
          ),

          // 5. Farmacias
          ListTile(
            leading: const Icon(Icons.local_pharmacy, color: Colors.blue),
            title: const Text('Farmacias'),
            onPressed: () => Navigator.pop(context),
          ),

          // 6. Enfermería
          ListTile(
            leading: const Icon(Icons.people_outline, color: Colors.blue),
            title: const Text('Enfermería'),
            onPressed: () => Navigator.pop(context),
          ),

          // 7. Urgencias 24/hrs (Le ponemos icono rojo de alerta)
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            title: const Text('Urgencias 24/hrs', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(context),
          ),

          // 8. Contacto
          ListTile(
            leading: const Icon(Icons.email_outlined, color: Colors.blue),
            title: const Text('Contacto'),
            onPressed: () => Navigator.pop(context),
          ),

          const Divider(),

          // 9. Botón Destacado: Suscribirse
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Suscribirse al directorio', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // Mini-widget para no repetir código en las sub-opciones
  Widget _buildSubItem(BuildContext context, String titulo) {
    return ListTile(
      title: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        style: const TextStyle(fontSize: 14),
      ),
      title: Text(titulo),
      onPressed: () {
        print('Celular eligió: $titulo');
        Navigator.pop(context); // Cierra el menú lateral
      },
    );
  }
}