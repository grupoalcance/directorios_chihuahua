import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

// 🔑 IMPORTACIÓN DINÁMICA DE CONFIGURACIÓN REGIONAL
import '../config/app_config.dart';

class TextosLegalesScreen extends StatelessWidget {
  const TextosLegalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Definimos un estilo de texto reutilizable para el cuerpo
    const TextStyle bodyTextStyle = TextStyle(
      height: 1.6,
      color: Colors.black87,
      fontSize: 14.5,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            // Agregamos un poco más de padding vertical para web
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Términos, Condiciones y Aviso de Privacidad',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1F36),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Última actualización: Mayo 2026',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),

                // --- TÉRMINOS Y CONDICIONES ---
                const Text(
                  '1. TÉRMINOS Y CONDICIONES DE USO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  // 🌎 USO DE VARIABLES DINÁMICAS (appName y appDomain)
                  'Bienvenido a ${AppConfig.appDomain}. Al registrarte y utilizar nuestra plataforma, aceptas los siguientes términos:\n\n'
                  '• Naturaleza de la Plataforma: ${AppConfig.appDomain} funciona exclusivamente como un directorio web y herramienta de contacto. No somos proveedores de servicios de salud, diagnósticos ni tratamientos médicos.\n\n'
                  '• Responsabilidad: El vínculo médico-paciente que se genere a través de esta plataforma es responsabilidad exclusiva de ambas partes. La plataforma no se hace responsable por negligencias, diagnósticos erróneos o conflictos derivados de la consulta.\n\n'
                  '• Veracidad de la Información: Los médicos registrados aseguran que la información proporcionada (cédula profesional, especialidad, ubicación) es verídica y comprobable. La plataforma se reserva el derecho de suspender perfiles que proporcionen información falsa.\n\n'
                  '• Uso Adecuado: Los usuarios se comprometen a utilizar la plataforma con respeto, sin usar lenguaje ofensivo ni intentar vulnerar la seguridad del sitio.',
                  style: bodyTextStyle,
                ),
                const SizedBox(height: 40),

                // --- AVISO DE PRIVACIDAD ---
                const Text(
                  '2. AVISO DE PRIVACIDAD',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'En cumplimiento con la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (México), te informamos lo siguiente:\n\n'
                  '• Datos que recabamos: Nombres, apellidos, correo electrónico, teléfono y, en el caso de los médicos, información profesional (cédula, especialidad, dirección del consultorio).\n\n'
                  '• Finalidad de los datos: Tus datos se utilizan exclusivamente para crear tu cuenta, permitir el contacto entre pacientes y especialistas, y mejorar tu experiencia en la plataforma. No vendemos ni compartimos tu información con terceros con fines de lucro.\n\n'
                  '• Seguridad: Utilizamos servicios en la nube de alta seguridad (Google Firebase) para proteger tu información contra accesos no autorizados.\n\n'
                  '• Derechos ARCO: Tienes derecho a Acceder, Rectificar, Cancelar u Oponerte al uso de tus datos personales. Puedes solicitar la eliminación de tu cuenta en cualquier momento contactando a nuestro equipo de soporte.',
                  style: bodyTextStyle,
                ),
                // Espaciado final para que no pegue al borde inferior
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
