import 'package:flutter/material.dart';

class SeccionEnlacesCruzados extends StatelessWidget {
  final String tituloSeccion;
  final List<String> columnasCiudades; // ['Durango', 'Gómez Palacio', 'Lerdo']
  final Map<String, List<String>>
  enlacesPorCiudad; // { 'Durango': ['Urgencias...', 'Clínicas...'] }
  final String ctaTitulo; // '¿Eres médico?'
  final String ctaSubtitulo; // 'Suscríbete al directorio...'
  final String ctaBotonTexto; // 'Suscríbete'
  final VoidCallback onCtaPressed;
  final Function(String ciudad, String categoria) onEnlacePressed;

  const SeccionEnlacesCruzados({
    Key? key,
    required this.tituloSeccion,
    required this.columnasCiudades,
    required this.enlacesPorCiudad,
    required this.ctaTitulo,
    required this.ctaSubtitulo,
    required this.ctaBotonTexto,
    required this.onCtaPressed,
    required this.onEnlacePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    bool esCelular = width < 950;

    return Container(
      width: double.infinity,
      color: const Color(0xFF1E3A8A), // Azul marino corporativo de fondo
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TÍTULO DE LA SECCIÓN
              Text(
                tituloSeccion,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // CONTENIDO EN FILA (O EN COLUMNA SI ES CELULAR)
              Flex(
                direction: esCelular ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: esCelular
                    ? CrossAxisAlignment.stretch
                    : CrossAxisAlignment.start,
                children: [
                  // COLUMNAS DE ENLACES (OCUPAN EL ESPACIO IZQUIERDO)
                  Expanded(
                    flex: esCelular ? 0 : 3,
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: columnasCiudades.map((ciudad) {
                        return Container(
                          width: esCelular ? double.infinity : 260,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Categorías en $ciudad',
                                style: const TextStyle(
                                  color: Colors.lightBlueAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 15),
                              ...?enlacesPorCiudad[ciudad]?.map((enlace) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: InkWell(
                                    onTap: () =>
                                        onEnlacePressed(ciudad, enlace),
                                    child: Text(
                                      enlace,
                                      style: TextStyle(
                                        color: Colors.grey.shade300,
                                        fontSize: 13.5,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  if (!esCelular) const SizedBox(width: 20),
                  if (esCelular) const SizedBox(height: 20),

                  // TARJETA LLAMADO A LA ACCIÓN (CTA DERECHO)
                  Expanded(
                    flex: esCelular ? 0 : 1,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7), // Azul brillante
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctaTitulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ctaSubtitulo,
                            style: TextStyle(
                              color: Colors.blue.shade100,
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: onCtaPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue.shade900,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                ctaBotonTexto,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
