import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:app_clima/theme/tema.dart';
import 'package:app_clima/widgets/indice_uv.dart';

class RecomendacionesClima extends StatelessWidget {
  final Future<Map<String, dynamic>> consulta;

  const RecomendacionesClima({super.key, required this.consulta});

  String _mensajeError(Object e) {
    if (e is SocketException) {
      return 'No tienes conexión a Internet';
    }

    if (e is HttpException) {
      return 'Error con el servidor';
    }

    if (e is TimeoutException) {
      return 'La consulta tardó demasiado';
    }

    return e.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: consulta,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF3986C9)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _mensajeError(snapshot.error!),
                style: const TextStyle(color: Color(0xFFE45D5D), fontSize: 14),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final clima = snapshot.data!['clima'] as Map<String, dynamic>;

        final actividades = evaluarActividades(clima);

        final actual = clima['current'] as Map<String, dynamic>;

        final temperatura = _num(
          actual,
          'apparent_temperature',
          _num(actual, 'temperature_2m', 20),
        );

        final codigo = _num(actual, 'weather_code', 0).toInt();

        final colores = PaletaClima.obtenerColores(temperatura, codigo);

        return Card(
          color: colores.colorTarjeta,
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: colores.colorBorde, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colores.colorAcento.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.lightbulb,
                        color: colores.colorAcento,
                        size: 25,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'Actividades recomendadas',
                        style: TextStyle(
                          color: colores.colorTextoOscuro,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  'Descubre qué actividades puedes realizar hoy.',
                  style: TextStyle(
                    color: colores.colorTextoSuave,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 15),

                for (final actividad in actividades)
                  _FilaActividad(actividad: actividad, colores: colores),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// MODELOS
// ==========================================

enum Nivel { ideal, regular, evitar }

class Actividad {
  final String nombre;
  final IconData icono;
  final Nivel nivel;
  final String motivo;

  const Actividad(this.nombre, this.icono, this.nivel, this.motivo);
}

// ==========================================
// FUNCIONES AUXILIARES
// ==========================================

double _num(Map<String, dynamic> datos, String campo, double porDefecto) {
  final valor = datos[campo];

  if (valor is num) {
    return valor.toDouble();
  }

  return porDefecto;
}

double? _probLluviaHoy(Map<String, dynamic> clima) {
  final hourly = clima['hourly'] as Map<String, dynamic>?;

  final actual = clima['current'] as Map<String, dynamic>;

  final ahora = actual['time'] as String?;

  if (hourly == null || ahora == null) {
    return null;
  }

  final horas = hourly['time'] as List<dynamic>?;
  final probabilidades = hourly['precipitation_probability'] as List<dynamic>?;

  if (horas == null || probabilidades == null) {
    return null;
  }

  final dia = ahora.substring(0, 10);

  double? maximo;

  for (int i = 0; i < horas.length && i < probabilidades.length; i++) {
    final probabilidad = probabilidades[i];

    if (probabilidad is num && horas[i].toString().startsWith(dia)) {
      if (maximo == null || probabilidad > maximo) {
        maximo = probabilidad.toDouble();
      }
    }
  }

  return maximo;
}

// ==========================================
// ÍNDICE UV DEL DÍA
// ==========================================

({double maximo, String? hora}) _uvHoy(Map<String, dynamic> clima) {
  final actual = clima['current'] as Map<String, dynamic>;

  final ahora = actual['time'] as String?;

  final hourly = clima['hourly'] as Map<String, dynamic>?;

  double maximo = 0;
  String? hora;

  if (hourly != null &&
      ahora != null &&
      hourly['uv_index'] is List &&
      hourly['time'] is List) {
    final dia = ahora.substring(0, 10);

    final horas = hourly['time'] as List<dynamic>;
    final uvs = hourly['uv_index'] as List<dynamic>;

    for (int i = 0; i < horas.length && i < uvs.length; i++) {
      final uv = uvs[i];

      if (uv is num && horas[i].toString().startsWith(dia) && uv > maximo) {
        maximo = uv.toDouble();

        final fechaHora = horas[i].toString();

        if (fechaHora.length >= 16) {
          hora = fechaHora.substring(11, 16);
        }
      }
    }
  }

  if (hora == null) {
    final daily = clima['daily'] as Map<String, dynamic>?;

    final lista = daily?['uv_index_max'];

    if (lista is List && lista.isNotEmpty && lista.first is num) {
      maximo = (lista.first as num).toDouble();
    }
  }

  final uvActual = _num(actual, 'uv_index', 0);

  if (uvActual > maximo) {
    maximo = uvActual;
  }

  return (maximo: maximo, hora: hora);
}

// ==========================================
// EVALUAR ACTIVIDADES
// ==========================================

List<Actividad> evaluarActividades(Map<String, dynamic> clima) {
  final actual = clima['current'] as Map<String, dynamic>;

  final temp = _num(
    actual,
    'apparent_temperature',
    _num(actual, 'temperature_2m', 20),
  );

  final humedad = _num(actual, 'relative_humidity_2m', 50);

  final presion = _num(actual, 'surface_pressure', 1013);

  final viento = _num(actual, 'wind_speed_10m', 0);

  final precip = _num(actual, 'precipitation', 0);

  final codigo = _num(actual, 'weather_code', 0).toInt();

  final prob = _probLluviaHoy(clima) ?? 0;

  final uvActual = _num(actual, 'uv_index', 0);

  final uvDia = _uvHoy(clima);

  final tormenta = codigo >= 95;

  final lluvia =
      precip > 0 ||
      (codigo >= 51 && codigo <= 67) ||
      (codigo >= 80 && codigo <= 82);

  final posibleLluvia = prob >= 50;

  // ========================================
  // EJERCICIO AL AIRE LIBRE
  // ========================================

  Actividad ejercicioFuera() {
    const nombre = 'Ejercicio al aire libre';
    const icono = Icons.directions_run;

    if (tormenta) {
      return const Actividad(
        nombre,
        icono,
        Nivel.evitar,
        'Hay tormenta: es peligroso salir.',
      );
    }

    if (lluvia) {
      return const Actividad(nombre, icono, Nivel.evitar, 'Está lloviendo.');
    }

    if (temp >= 33) {
      return const Actividad(
        nombre,
        icono,
        Nivel.evitar,
        'Calor extremo: riesgo de golpe de calor.',
      );
    }

    if (temp <= 2) {
      return const Actividad(
        nombre,
        icono,
        Nivel.evitar,
        'Demasiado frío para ejercitarse afuera.',
      );
    }

    if (viento >= 40) {
      return const Actividad(nombre, icono, Nivel.evitar, 'Viento muy fuerte.');
    }

    if (temp >= 28) {
      return const Actividad(
        nombre,
        icono,
        Nivel.regular,
        'Hace calor: hidrátate y busca sombra.',
      );
    }

    if (temp <= 8) {
      return const Actividad(
        nombre,
        icono,
        Nivel.regular,
        'Hace frío: abrígate y calienta antes de comenzar.',
      );
    }

    if (posibleLluvia) {
      return const Actividad(
        nombre,
        icono,
        Nivel.regular,
        'Puede llover más tarde: revisa el pronóstico.',
      );
    }

    if (viento >= 25) {
      return const Actividad(
        nombre,
        icono,
        Nivel.regular,
        'El viento puede dificultar el ejercicio.',
      );
    }

    if (humedad >= 80 && temp >= 24) {
      return const Actividad(
        nombre,
        icono,
        Nivel.regular,
        'La humedad puede hacer más pesado el ejercicio.',
      );
    }

    if (uvActual >= 6) {
      return Actividad(
        nombre,
        icono,
        Nivel.regular,
        'UV ${nivelUv(uvActual).etiqueta.toLowerCase()} '
        '(${uvActual.toStringAsFixed(1)}): '
        'usa protector solar y evita las horas centrales.',
      );
    }

    if (uvActual >= 3) {
      return Actividad(
        nombre,
        icono,
        Nivel.ideal,
        'Clima agradable. Usa protector solar '
        '(UV ${uvActual.toStringAsFixed(1)}).',
      );
    }

    return const Actividad(
      nombre,
      icono,
      Nivel.ideal,
      'Temperatura agradable y sin lluvia.',
    );
  }

  // ========================================
  // EJERCICIO EN INTERIORES
  // ========================================

  Actividad ejercicioDentro() {
    const nombre = 'Ejercicio en interiores';
    const icono = Icons.fitness_center;

    final nivelFuera = ejercicioFuera().nivel;

    if (nivelFuera == Nivel.evitar) {
      return const Actividad(
        nombre,
        icono,
        Nivel.ideal,
        'Buena alternativa a salir con este clima.',
      );
    }

    if (nivelFuera == Nivel.regular) {
      return const Actividad(
        nombre,
        icono,
        Nivel.ideal,
        'Opción cómoda cuando afuera no es lo ideal.',
      );
    }

    return const Actividad(
      nombre,
      icono,
      Nivel.regular,
      'Puedes hacerlo, aunque el clima favorece salir.',
    );
  }

  // ========================================
  // ESTUDIAR O TRABAJAR
  // ========================================

  Actividad estudiar() {
    const nombre = 'Estudiar / trabajo concentrado';
    const icono = Icons.menu_book;

    final avisos = <String>[];

    if (temp >= 27) {
      avisos.add('el calor puede causar incomodidad');
    }

    if (humedad >= 75 && temp >= 22) {
      avisos.add('la humedad puede resultar molesta');
    }

    if (presion < 1005) {
      avisos.add('la presión atmosférica es baja');
    }

    if (avisos.isNotEmpty) {
      final texto = avisos.join(', ');

      return Actividad(
        nombre,
        icono,
        Nivel.regular,
        'Considera que $texto. '
        'Mantén un espacio cómodo y toma pausas.',
      );
    }

    if (temp >= 17 && temp <= 25) {
      return const Actividad(
        nombre,
        icono,
        Nivel.ideal,
        'Temperatura agradable para concentrarte.',
      );
    }

    if (temp < 12) {
      return const Actividad(
        nombre,
        icono,
        Nivel.regular,
        'Hace frío: abrígate para estudiar cómodamente.',
      );
    }

    return const Actividad(
      nombre,
      icono,
      Nivel.ideal,
      'Condiciones cómodas para concentrarte.',
    );
  }

  // ========================================
  // LIMPIAR LA CASA
  // ========================================

  Actividad limpiar() {
    const nombre = 'Limpiar la casa';
    const icono = Icons.cleaning_services;

    if (lluvia || tormenta) {
      return const Actividad(
        nombre,
        icono,
        Nivel.regular,
        'Buen momento para limpieza interior.',
      );
    }

    if (viento >= 35) {
      return const Actividad(
        nombre,
        icono,
        Nivel.regular,
        'Mucho viento: puede entrar polvo.',
      );
    }

    if (humedad >= 85) {
      return const Actividad(
        nombre,
        icono,
        Nivel.regular,
        'La humedad puede dificultar el secado.',
      );
    }

    return const Actividad(
      nombre,
      icono,
      Nivel.ideal,
      'Buen clima para limpiar y ventilar.',
    );
  }

  // ========================================
  // LAVAR Y TENDER ROPA
  // ========================================

  Actividad ropa() {
    const nombre = 'Lavar y tender ropa';
    const icono = Icons.local_laundry_service;

    if (tormenta || lluvia || prob >= 60) {
      return const Actividad(
        nombre,
        icono,
        Nivel.evitar,
        'Riesgo de lluvia: mejor tender bajo techo.',
      );
    }

    if (humedad >= 85) {
      return const Actividad(
        nombre,
        icono,
        Nivel.evitar,
        'Humedad alta: la ropa tardará en secar.',
      );
    }

    if (posibleLluvia || humedad >= 70 || temp < 12) {
      return const Actividad(
        nombre,
        icono,
        Nivel.regular,
        'La ropa podría secarse lentamente.',
      );
    }

    return const Actividad(
      nombre,
      icono,
      Nivel.ideal,
      'Buenas condiciones para secar la ropa.',
    );
  }

  // ========================================
  // SALIR A PASEAR
  // ========================================

  Actividad paseo() {
    const nombre = 'Salir a pasear';
    const icono = Icons.park;

    if (tormenta) {
      return const Actividad(
        nombre,
        icono,
        Nivel.evitar,
        'Hay tormenta: evita salir.',
      );
    }

    if (lluvia) {
      return const Actividad(
        nombre,
        icono,
        Nivel.evitar,
        'Está lloviendo: mejor espera.',
      );
    }

    if (temp >= 33 || temp <= 2) {
      return const Actividad(
        nombre,
        icono,
        Nivel.evitar,
        'Temperatura extrema para estar afuera.',
      );
    }

    if (temp >= 29 || temp <= 8 || viento >= 30 || posibleLluvia) {
      return const Actividad(
        nombre,
        icono,
        Nivel.regular,
        'Puedes salir, pero lleva agua, abrigo o paraguas.',
      );
    }

    if (uvActual >= 6) {
      return Actividad(
        nombre,
        icono,
        Nivel.regular,
        'UV ${nivelUv(uvActual).etiqueta.toLowerCase()} '
        '(${uvActual.toStringAsFixed(1)}): '
        'protégete y busca sombra.',
      );
    }

    if (uvActual >= 3) {
      return Actividad(
        nombre,
        icono,
        Nivel.ideal,
        'Clima agradable. Usa protector solar '
        '(UV ${uvActual.toStringAsFixed(1)}).',
      );
    }

    return const Actividad(
      nombre,
      icono,
      Nivel.ideal,
      'Clima agradable para estar afuera.',
    );
  }

  // ========================================
  // EXPOSICIÓN AL SOL
  // ========================================

  Actividad sol() {
    const nombre = 'Exposición al sol';
    const icono = Icons.wb_sunny;

    final uv = uvDia.maximo;
    final nivel = nivelUv(uv);

    final pico = uvDia.hora != null ? ' Pico a las ${uvDia.hora}.' : '';

    final texto =
        'UV máx. hoy ${uv.toStringAsFixed(1)} '
        '(${nivel.etiqueta.toLowerCase()}). '
        '${nivel.consejo}$pico';

    if (uv >= 8) {
      return Actividad(nombre, icono, Nivel.evitar, texto);
    }

    if (uv >= 3) {
      return Actividad(nombre, icono, Nivel.regular, texto);
    }

    return Actividad(nombre, icono, Nivel.ideal, texto);
  }

  // ========================================
  // LISTA DE ACTIVIDADES
  // ========================================

  final lista = [
    ejercicioFuera(),
    ejercicioDentro(),
    estudiar(),
    limpiar(),
    ropa(),
    paseo(),
    sol(),
  ];

  lista.sort((a, b) => a.nivel.index.compareTo(b.nivel.index));

  return lista;
}

// ==========================================
// DISEÑO DE CADA ACTIVIDAD
// ==========================================

class _FilaActividad extends StatelessWidget {
  final Actividad actividad;
  final ColoresClima colores;

  const _FilaActividad({required this.actividad, required this.colores});

  @override
  Widget build(BuildContext context) {
    Color color;
    String etiqueta;

    if (actividad.nivel == Nivel.ideal) {
      color = const Color(0xFF369B70);
      etiqueta = 'Ideal';
    } else if (actividad.nivel == Nivel.regular) {
      color = const Color(0xFFE99A35);
      etiqueta = 'Con cuidado';
    } else {
      color = const Color(0xFFE45D5D);
      etiqueta = 'Evitar';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colores.colorTarjetaSecundaria,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colores.colorBorde, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(actividad.icono, color: color, size: 25),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actividad.nombre,
                  style: TextStyle(
                    color: colores.colorTextoOscuro,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  actividad.motivo,
                  style: TextStyle(
                    color: colores.colorTextoSuave,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          Text(
            etiqueta,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
