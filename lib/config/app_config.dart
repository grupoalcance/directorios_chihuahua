import 'package:flutter/material.dart';

class AppConfig {
  // 1. Nombres e Identidad Global
  static const String appName = 'Médicos Chihuahua';
  static const String appDomain = 'medicoschihuahua.com'; // O medicoscuu.com según tu dominio

  // 2. Colores Corporativos (Puedes cambiar el azul si usas otro tono para Chihuahua)
  static const Color primaryColor = Colors.blue;
  static const Color secondaryColor = Color(0xFF0061E0);

  // 3. Rutas y CRM
  static const String logoPath = 'assets/images/logo-chihuahua.png';
  static const String crmUrl = 'https://medicoschihuahua.com/asesores/';

  // 4. Menú de Ciudades (Principales municipios de Chihuahua)
  static const List<String> ciudadesActivas = [
    'Chihuahua',
    'Ciudad Juárez',
    'Delicias',
    'Cuauhtémoc',
    'Hidalgo del Parral',
    'Nuevo Casas Grandes',
    'Camargo',
    'Jiménez',
  ];
}