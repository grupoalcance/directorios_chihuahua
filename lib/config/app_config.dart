import 'package:flutter/material.dart';

class AppConfig {
  // 1. Nombres Globales
  static const String appName = 'Médicos Durango';

  // 2. Colores Corporativos
  static const Color primaryColor = Colors.blue;
  static const Color secondaryColor = Color(0xFF0061E0);

  // 3. Rutas
  static const String logoPath =
      'assets/images/logo-durango.png'; // Asegúrate de meter tu logo en esta ruta
  static const String crmUrl =
      'https://medicosdurango.com/asesores/'; // URL de tu CRM para Durango

  // 4. Menú de Ciudades (Municipios de Durango)
  static const List<String> ciudadesActivas = [
    'Victoria de Durango',
    'Gómez Palacio',
    'Lerdo',
    'Santiago Papasquiaro',
    'Guadalupe Victoria',
    'El Salto',
  ];
}
