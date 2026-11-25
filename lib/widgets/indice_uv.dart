import 'package:flutter/material.dart';

class NivelUv {
  final String etiqueta;
  final Color color;
  final String consejo;

  const NivelUv(this.etiqueta, this.color, this.consejo);
}

NivelUv nivelUv(double uv) {
  if (uv < 3) {
    return const NivelUv(
      'Bajo',
      Colors.green,
      'No necesitas protección especial.',
    );
  }
  if (uv < 6) {
    return const NivelUv(
      'Moderado',
      Colors.amber,
      'Usa protector solar y gafas si estarás mucho tiempo afuera.',
    );
  }
  if (uv < 8) {
    return const NivelUv(
      'Alto',
      Colors.orange,
      'Usa protector FPS 30+, sombrero y gafas; busca sombra al mediodía.',
    );
  }
  if (uv < 11) {
    return const NivelUv(
      'Muy alto',
      Colors.red,
      'Protector FPS 50+, sombrero y gafas; evita el sol directo en las horas centrales.',
    );
  }
  return const NivelUv(
    'Extremo',
    Colors.purple,
    'Evita el sol directo; si sales, protección total y sombra.',
  );
}
