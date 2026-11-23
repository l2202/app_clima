import 'package:flutter/material.dart';

class ColoresClima {
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
  final LinearGradient degradadoFondo;

  ColoresClima({
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
    required this.degradadoFondo,
  });
}

class PaletaClima {
  // ==========================================
  // CLIMA CALUROSO
  // ==========================================

  static final ColoresClima calorNaranja = ColoresClima(
    colorFondo: const Color(0xFFFFF7E8),
    colorFondoSecundario: const Color(0xFFFFF0D5),

    colorTarjeta: const Color(0xFFFFFAF4),
    colorTarjetaSecundaria: const Color(0xFFFFF3E6),

    colorBorde: const Color(0xFFFFE5BD),
    colorAcento: const Color(0xFFE99A45),
    colorAcentoSecundario: const Color(0xFFFFC46B),

    colorTextoOscuro: const Color(0xFF29384B),
    colorTextoSuave: const Color(0xFF657080),

    nombreEstado: 'Caluroso',

    degradadoFondo: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF7E8), Color(0xFFFFF1DD), Color(0xFFFFF9F0)],
    ),
  );

  // ==========================================
  // CLIMA LLUVIOSO
  // ==========================================

  static final ColoresClima lluviaAzul = ColoresClima(
    colorFondo: const Color(0xFFF0F7FF),
    colorFondoSecundario: const Color(0xFFE5F0FF),

    colorTarjeta: const Color(0xFFF7FBFF),
    colorTarjetaSecundaria: const Color(0xFFEDF5FF),

    colorBorde: const Color(0xFFD9E8FA),
    colorAcento: const Color(0xFF6498D1),
    colorAcentoSecundario: const Color(0xFF91B9E8),

    colorTextoOscuro: const Color(0xFF29384B),
    colorTextoSuave: const Color(0xFF596779),

    nombreEstado: 'Lluvioso',

    degradadoFondo: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF0F7FF), Color(0xFFEAF3FF), Color(0xFFF7FAFF)],
    ),
  );

  // ==========================================
  // CLIMA FRÍO
  // ==========================================

  static final ColoresClima frioIndigo = ColoresClima(
    colorFondo: const Color(0xFFF3F1FF),
    colorFondoSecundario: const Color(0xFFECEBFF),

    colorTarjeta: const Color(0xFFFAF9FF),
    colorTarjetaSecundaria: const Color(0xFFF1EEFF),

    colorBorde: const Color(0xFFE1DDF8),
    colorAcento: const Color(0xFF8B83C9),
    colorAcentoSecundario: const Color(0xFFB1A7E3),

    colorTextoOscuro: const Color(0xFF29384B),
    colorTextoSuave: const Color(0xFF596779),

    nombreEstado: 'Frío',

    degradadoFondo: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF3F1FF), Color(0xFFEFEDFF), Color(0xFFFAF9FF)],
    ),
  );

  // ==========================================
  // CLIMA TEMPLADO
  // ==========================================

  static final ColoresClima templadoVerde = ColoresClima(
    colorFondo: const Color(0xFFFFF3ED),
    colorFondoSecundario: const Color(0xFFFFEAE0),

    colorTarjeta: const Color(0xFFFFF9F6),
    colorTarjetaSecundaria: const Color(0xFFFFF1EB),

    colorBorde: const Color(0xFFF6DDD1),
    colorAcento: const Color(0xFFE99579),
    colorAcentoSecundario: const Color(0xFFFFB58F),

    colorTextoOscuro: const Color(0xFF29384B),
    colorTextoSuave: const Color(0xFF596779),

    nombreEstado: 'Templado',

    degradadoFondo: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF3ED), Color(0xFFFFEDE5), Color(0xFFFFF9F5)],
    ),
  );

  // ==========================================
  // COLORES INICIALES
  // ==========================================

  static final ColoresClima inicialGrisAzul = ColoresClima(
    colorFondo: const Color(0xFFF3F7FC),
    colorFondoSecundario: const Color(0xFFEAF0F8),

    colorTarjeta: const Color(0xFFF9FBFF),
    colorTarjetaSecundaria: const Color(0xFFF0F5FC),

    colorBorde: const Color(0xFFE0E8F2),
    colorAcento: const Color(0xFF729BCB),
    colorAcentoSecundario: const Color(0xFFA3BCE0),

    colorTextoOscuro: const Color(0xFF29384B),
    colorTextoSuave: const Color(0xFF596779),

    nombreEstado: 'Clima actual',

    degradadoFondo: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF3F7FC), Color(0xFFEDF3FA)],
    ),
  );

  // ==========================================
  // OBTENER COLORES SEGÚN EL CLIMA
  // ==========================================

  static ColoresClima obtenerColores(double temperatura, int codigoClima) {
    // Lluvia, llovizna y tormentas
    if ((codigoClima >= 51 && codigoClima <= 67) ||
        (codigoClima >= 80 && codigoClima <= 99)) {
      return lluviaAzul;
    }

    // Nieve
    if (codigoClima >= 71 && codigoClima <= 77) {
      return frioIndigo;
    }

    // Calor
    if (temperatura >= 26) {
      return calorNaranja;
    }

    // Frío
    if (temperatura <= 14) {
      return frioIndigo;
    }

    // Clima templado
    return templadoVerde;
  }
}
