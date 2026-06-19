import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder nos da las medidas de la pantalla en la variable 'constraints'
    return LayoutBuilder(
      builder: (context, constraints) {
        bool esCelular = constraints.maxWidth < 900;

        return AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.blue), // Color del botón ☰
          
          // Si es celular, Flutter pone automáticamente el botón ☰ a la izquierda si agregamos el Drawer en la pantalla principal
          title: const Text(
            'Médicos Laguna',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
          
          // Acciones de la derecha: Si es celular se ocultan (lista vacía), si es compu se muestran todas
          actions: esCelular ? [] : [
            // 1. ¿Quiénes somos?
            TextButton(onPressed: () {}, child: const Text('¿Quiénes somos?')),

            // 2. Desplegable: Ciudad
            _buildDropdownMenu(
              label: 'Ciudad',
              items: ['Torreón', 'Gómez Palacio', 'Lerdo', 'San Pedro', 'Fco. I. Madero', 'Matamoros'],
            ),

            // 3. Desplegable: Especialidad
            _buildDropdownMenu(
              label: 'Especialidad',
              items: ['Cardiología', 'Pediatría', 'Ginecología'], // Crecerá con tu DB
            ),

            // 4 a 7. Botones normales
            TextButton(onPressed: () {}, child: const Text('Hospitales')),
            TextButton(onPressed: () {}, child: const Text('Farmacias')),
            TextButton(onPressed: () {}, child: const Text('Enfermería')),
            TextButton(
              onPressed: () {}, 
              child: const Text('Urgencias 24/hrs', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            TextButton(onPressed: () {}, child: const Text('Contacto')),

            // 8. Botón destacado: Suscribirse
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Suscribirse', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  // Molde para hacer los menús desplegables de la computadora rápidos
  Widget _buildDropdownMenu({required String label, required List<String> items}) {
    return PopupMenuButton<String>(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: Colors.blue)),
            const Icon(Icons.arrow_drop_down, color: Colors.blue),
          ],
        ),
      ),
      onSelected: (value) => print('Compu filtró por: $value'),
      itemBuilder: (context) => items.map((item) => PopupMenuItem(value: item, child: Text(item))).toList(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}