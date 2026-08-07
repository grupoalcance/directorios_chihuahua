import 'package:flutter/material.dart';

class SeccionEnlacesCruzados extends StatelessWidget {
  final String tituloSeccion;
  final List<String> columnasCiudades;
  final Map<String, List<String>> enlacesPorCiudad;
  final String ctaTitulo;
  final String ctaSubtitulo;
  final String ctaBotonTexto;
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
      color: const Color(
        0xFF0F172A,
      ), // Azul marino muy oscuro para máximo contraste
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
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
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),

              // CONTENIDO RESPONSIVO
              Flex(
                direction: esCelular ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: esCelular
                    ? CrossAxisAlignment.stretch
                    : CrossAxisAlignment.start,
                children: [
                  // COLUMNAS DE ENLACES
                  Expanded(
                    flex: esCelular ? 0 : 3,
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: columnasCiudades.map((ciudad) {
                        return Container(
                          width: esCelular ? double.infinity : 260,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1E293B,
                            ), // Tarjetas con contraste oscuro
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Categorías en $ciudad',
                                style: const TextStyle(
                                  color: Color(
                                    0xFF38BDF8,
                                  ), // Cyan brillante legible
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...?enlacesPorCiudad[ciudad]?.map((enlace) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: InkWell(
                                    onTap: () =>
                                        onEnlacePressed(ciudad, enlace),
                                    child: Text(
                                      enlace,
                                      style: const TextStyle(
                                        color: Colors
                                            .white, // Texto en blanco nítido
                                        fontSize: 14,
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

                  if (!esCelular) const SizedBox(width: 24),
                  if (esCelular) const SizedBox(height: 24),

                  // TARJETA LLAMADO A LA ACCIÓN (CTA DERECHO)
                  Expanded(
                    flex: esCelular ? 0 : 1,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctaTitulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            ctaSubtitulo,
                            style: const TextStyle(
                              color: Color(0xFFE0F2FE),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: onCtaPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0369A1),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
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
                                  fontSize: 15,
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
