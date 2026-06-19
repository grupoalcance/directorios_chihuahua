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
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Médicos Laguna',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 1. ¿Quiénes somos?
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.blue),
            title: const Text('¿Quiénes somos?'),
            onTap: () => Navigator.pop(
              context,
            ), // <-- CORREGIDO (Era onTap, no onPressed)
          ),

          // 2. Desplegable Ciudad
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

          // 3. Desplegable Especialidad
          ExpansionTile(
            leading: const Icon(
              Icons.medical_services_outlined,
              color: Colors.blue,
            ),
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
            onTap: () => Navigator.pop(context),
          ),

          // 5. Farmacias
          ListTile(
            leading: const Icon(Icons.local_pharmacy, color: Colors.blue),
            title: const Text('Farmacias'),
            onTap: () => Navigator.pop(context),
          ),

          // 6. Enfermería
          ListTile(
            leading: const Icon(Icons.people_outline, color: Colors.blue),
            title: const Text('Enfermería'),
            onTap: () => Navigator.pop(context),
          ),

          // 7. Urgencias 24/hrs
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            title: const Text(
              'Urgencias 24/hrs',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () => Navigator.pop(context),
          ),

          // 8. Contacto
          ListTile(
            leading: const Icon(Icons.email_outlined, color: Colors.blue),
            title: const Text('Contacto'),
            onTap: () => Navigator.pop(context),
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
              child: const Text(
                'Suscribirse al directorio',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mini-widget CORREGIDO
  Widget _buildSubItem(BuildContext context, String titulo) {
    return ListTile(
      title: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Text(
          titulo,
          style: const TextStyle(fontSize: 14),
        ), // <-- CORREGIDO
      ),
      onTap: () {
        // <-- CORREGIDO
        print('Celular eligió: $titulo');
        Navigator.pop(context);
      },
    );
  }
}
