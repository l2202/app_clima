import 'package:flutter/material.dart';

class coloresClima {
  final Color colorFondo;
  final Color colorFondoSecundario;
  final Color colorTarjeta;
  final Color colorTarjetaSecundaria;
  final Color colorBorde;
  final Color colorAcento;
  final Color colorAcentoSecundario;
  final Color colorTextoOscuro;
  final Color colorTextoSuave;
  final String nombreEstado;

  const coloresClima({
    required this.colorFondo,
    required this.colorFondoSecundario,
    required this.colorTarjeta,
    required this.colorTarjetaSecundaria,
    required this.colorBorde,
    required this.colorAcento,
    required this.colorAcentoSecundario,
    required this.colorTextoOscuro,
    required this.colorTextoSuave,
    required this.nombreEstado,
  });

  LinearGradient get degradadoFondo => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [colorFondo, colorFondoSecundario],
  );
}

class PaletaClima {
  // Lluvia: azul cielo y azul intenso
  static const coloresClima lluviaAzul = coloresClima(
    colorFondo: Color(0xFFD7ECFF),
    colorFondoSecundario: Color(0xFFEAF4FF),
    colorTarjeta: Color(0xFFFFFFFF),
    colorTarjetaSecundaria: Color(0xFFB8D9F5),
    colorBorde: Color(0xFF9DC6E8),
    colorAcento: Color(0xFF3986C9),
    colorAcentoSecundario: Color(0xFF648FD1),
    colorTextoOscuro: Color(0xFF29384B),
    colorTextoSuave: Color(0xFF596779),
    nombreEstado: 'Lluvia / Fresco',
  );

  // Calor: amarillo y coral
  static const coloresClima calorNaranja = coloresClima(
    colorFondo: Color(0xFFFFF1D6),
    colorFondoSecundario: Color(0xFFFFE5B8),
    colorTarjeta: Color(0xFFFFFFFF),
    colorTarjetaSecundaria: Color(0xFFFFD58C),
    colorBorde: Color(0xFFF3C77E),
    colorAcento: Color(0xFFFFB84D),
    colorAcentoSecundario: Color(0xFFFF8066),
    colorTextoOscuro: Color(0xFF493921),
    colorTextoSuave: Color(0xFF796348),
    nombreEstado: 'Soleado / Cálido',
  );

  // Frío: azul y morado
  static const coloresClima frioIndigo = coloresClima(
    colorFondo: Color(0xFFE5E9FF),
    colorFondoSecundario: Color(0xFFF0E9FF),
    colorTarjeta: Color(0xFFFFFFFF),
    colorTarjetaSecundaria: Color(0xFFD5D4F5),
    colorBorde: Color(0xFFB9B9E4),
    colorAcento: Color(0xFF648FD1),
    colorAcentoSecundario: Color(0xFF9879CC),
    colorTextoOscuro: Color(0xFF343653),
    colorTextoSuave: Color(0xFF646681),
    nombreEstado: 'Frío / Abrigo',
  );

  // Templado: verde y amarillo
  static const coloresClima templadoVerde = coloresClima(
    colorFondo: Color(0xFFE1F3E8),
    colorFondoSecundario: Color(0xFFF1F5D9),
    colorTarjeta: Color(0xFFFFFFFF),
    colorTarjetaSecundaria: Color(0xFFC5E5D1),
    colorBorde: Color(0xFFA5D0B6),
    colorAcento: Color(0xFF65B995),
    colorAcentoSecundario: Color(0xFFFFB84D),
    colorTextoOscuro: Color(0xFF29483B),
    colorTextoSuave: Color(0xFF5B7669),
    nombreEstado: 'Templado / Agradable',
  );

  // Inicial: combinación azul y crema
  static const coloresClima inicialGrisAzul = coloresClima(
    colorFondo: Color(0xFFFFF1D6),
    colorFondoSecundario: Color(0xFFD7ECFF),
    colorTarjeta: Color(0xFFFFFFFF),
    colorTarjetaSecundaria: Color(0xFFFFE5B8),
    colorBorde: Color(0xFFC6DCEF),
    colorAcento: Color(0xFF3986C9),
    colorAcentoSecundario: Color(0xFFFFB84D),
    colorTextoOscuro: Color(0xFF29384B),
    colorTextoSuave: Color(0xFF596779),
    nombreEstado: 'Listo',
  );

  static coloresClima obtenerColores({
    required double temperatura,
    required int codigoClima,
  }) {
    final hayLluvia =
        (codigoClima >= 51 && codigoClima <= 67) ||
        (codigoClima >= 80 && codigoClima <= 99);

    if (hayLluvia) {
      return lluviaAzul;
    }

    if (temperatura >= 26) {
      return calorNaranja;
    }

    if (temperatura <= 14) {
      return frioIndigo;
    }

    return templadoVerde;
  }
}
