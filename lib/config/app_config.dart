// lib/config/app_config.dart
import 'package:flutter/material.dart';

class AppConfig {
  // 1. Nombres Globales
  static const String appName = 'Médicos Laguna';

  // 2. Colores Corporativos
  static const Color primaryColor = Colors.blue;
  static const Color secondaryColor = Color(0xFF0061E0);

  // 3. Rutas
  static const String logoPath = 'assets/images/logo.png';
  static const String crmUrl = 'https://medicoslaguna.com/asesores/';

  // 4. Menú de Ciudades
  static const List<String> ciudadesActivas = [
    'Torreón',
    'Gómez Palacio',
    'Lerdo',
    'San Pedro',
    'Fco. I. Madero',
    'Matamoros',
  ];
}
