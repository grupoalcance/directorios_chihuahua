import 'package:flutter/material.dart';

class AppConfig {
  // 1. Nombres Globales
  static const String appName = 'Médicos Durango';

  // 2. Colores Corporativos (Ej. Verde azulado)
  static const Color primaryColor = Color(0xFF00796B);
  static const Color secondaryColor = Color(0xFF004D40);

  // 3. Rutas
  static const String logoPath =
      'assets/images/logo_durango.png'; // Asegúrate de meter tu logo en esta ruta
  static const String crmUrl =
      'https://tudominiodurango.com/asesores/'; // URL de tu CRM para Durango

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
