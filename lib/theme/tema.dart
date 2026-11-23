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
  // Lluvia: azul cielo, gris azulado y lavanda
  static const coloresClima lluviaAzul = coloresClima(
    colorFondo: Color(0xFFBFD9EB),
    colorFondoSecundario: Color(0xFFD8D9ED),
    colorTarjeta: Color(0xFFF9FCFF),
    colorTarjetaSecundaria: Color(0xFFE6F0F8),
    colorBorde: Color(0xFFABC7DF),
    colorAcento: Color(0xFF648FB5),
    colorAcentoSecundario: Color(0xFF9295C4),
    colorTextoOscuro: Color(0xFF34495E),
    colorTextoSuave: Color(0xFF718397),
    nombreEstado: 'Lluvia / Fresco',
  );

  // Calor: durazno, crema y amarillo cálido
  static const coloresClima calorNaranja = coloresClima(
    colorFondo: Color(0xFFFFD9B8),
    colorFondoSecundario: Color(0xFFFFE9C9),
    colorTarjeta: Color(0xFFFFFCF7),
    colorTarjetaSecundaria: Color(0xFFFFF0DE),
    colorBorde: Color(0xFFF3C69F),
    colorAcento: Color(0xFFE5A05B),
    colorAcentoSecundario: Color(0xFFF2C16B),
    colorTextoOscuro: Color(0xFF594638),
    colorTextoSuave: Color(0xFF92745F),
    nombreEstado: 'Soleado / Cálido',
  );

  // Frío: lavanda, azul pastel y blanco
  static const coloresClima frioIndigo = coloresClima(
    colorFondo: Color(0xFFD5DDF3),
    colorFondoSecundario: Color(0xFFE9DDF0),
    colorTarjeta: Color(0xFFFCFBFF),
    colorTarjetaSecundaria: Color(0xFFEDEAF8),
    colorBorde: Color(0xFFC5C5E5),
    colorAcento: Color(0xFF858BBF),
    colorAcentoSecundario: Color(0xFFB19ACB),
    colorTextoOscuro: Color(0xFF41445F),
    colorTextoSuave: Color(0xFF7C7D99),
    nombreEstado: 'Frío / Abrigo',
  );

  // Templado: verde salvia, menta y crema
  static const coloresClima templadoVerde = coloresClima(
    colorFondo: Color(0xFFCDE6D7),
    colorFondoSecundario: Color(0xFFE7EBD5),
    colorTarjeta: Color(0xFFFBFDF8),
    colorTarjetaSecundaria: Color(0xFFE9F2E5),
    colorBorde: Color(0xFFB5D4BC),
    colorAcento: Color(0xFF78A98A),
    colorAcentoSecundario: Color(0xFFA9C99C),
    colorTextoOscuro: Color(0xFF3D5746),
    colorTextoSuave: Color(0xFF788D7C),
    nombreEstado: 'Templado / Agradable',
  );

  // Inicial: azul cielo, crema y lavanda
  static const coloresClima inicialGrisAzul = coloresClima(
    colorFondo: Color(0xFFD3E5F4),
    colorFondoSecundario: Color(0xFFE9E3F2),
    colorTarjeta: Color(0xFFFCFDFF),
    colorTarjetaSecundaria: Color(0xFFEAF1F8),
    colorBorde: Color(0xFFC2D5E7),
    colorAcento: Color(0xFF789DBF),
    colorAcentoSecundario: Color(0xFFA99BC9),
    colorTextoOscuro: Color(0xFF3E5063),
    colorTextoSuave: Color(0xFF7B8999),
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
