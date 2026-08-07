import 'package:flutter/material.dart';

class AppConfig {
  // 1. Nombres e Identidad Global
  static const String appName = 'Médicos Durango';
  static const String appDomain = 'medicosdurango.com';

 // 2. Colores Corporativos
  static const Color primaryColor = Colors.blue;
  static const Color secondaryColor = Color(0xFF0061E0);

  // 3. Rutas y CRM
  static const String logoPath = 'assets/images/logo-durango.png';
  static const String crmUrl = 'https://medicosdurango.com/asesores/';

  // 4. Menú de Ciudades (Municipios de Durango)
  static const List<String> ciudadesActivas = [
    'Durango',
    'Victoria de Durango',
    'Gómez Palacio',
    'Lerdo',
    'Santiago Papasquiaro',
    'Guadalupe Victoria',
    'El Salto',
  ];
}
