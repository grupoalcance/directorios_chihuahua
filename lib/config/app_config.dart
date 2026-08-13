import 'package:flutter/material.dart';

class AppConfig {
  // 1. Nombres e Identidad Global
  static const String appName = 'Médicos Sinaloa';
  static const String appDomain = 'medicossinaloa.com';

  // 2. Colores Corporativos
  static const Color primaryColor = Colors.blue;
  static const Color secondaryColor = Color(0xFF0061E0);

  // 3. Rutas y CRM
  static const String logoPath = 'assets/images/logo-sinaloa.png';
  static const String crmUrl = 'https://medicossinaloa.com/asesores/';

  // 4. Menú de Ciudades (Principales municipios de Sinaloa)
  static const List<String> ciudadesActivas = [
    'Culiacán',
    'Mazatlán',
    'Los Mochis',
    'Guasave',
    'Guamúchil',
    'Navolato',
    'Escuinapa',
    'El Fuerte',
  ];
}
