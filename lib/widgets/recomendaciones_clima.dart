import 'dart:async';
import 'dart:io';

import 'package:app_clima/widgets/indice_uv.dart';
import 'package:flutter/material.dart';

/// Recuadro con recomendaciones de actividades según el clima actual:
/// ejercicio, estudio, limpieza, paseo, etc.
///
/// Usa temperatura aparente, humedad, presión, viento, precipitación, código
/// de clima y probabilidad de lluvia del día. Las reglas están en
/// [evaluarActividades], por si quieres ajustar umbrales o agregar actividades.
///
/// Uso:
/// ```dart
/// RecomendacionesClima(consulta: ClimaService().buscarClima('Madrid'));
/// ```
class RecomendacionesClima extends StatelessWidget {
  final Future<Map<String, dynamic>> consulta;

  const RecomendacionesClima({super.key, required this.consulta});

  String _mensajeError(Object e) {
    if (e is SocketException) return 'No tienes conexión a Internet';
    if (e is HttpException) return 'Error con el servidor';
    if (e is TimeoutException) return 'La consulta tardó demasiado';
    return e.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>>(
          future: consulta,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Text(
                _mensajeError(snapshot.error!),
                style: const TextStyle(color: Colors.red, fontSize: 16),
              );
            }

            final clima = snapshot.data!['clima'] as Map<String, dynamic>;
            final actividades = evaluarActividades(clima);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actividades recomendadas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final a in actividades) _FilaActividad(actividad: a),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum Nivel { ideal, regular, evitar }

class Actividad {
  final String nombre;
  final IconData icono;
  final Nivel nivel;
  final String motivo;

  const Actividad(this.nombre, this.icono, this.nivel, this.motivo);
}

double _num(Map<String, dynamic> m, String campo, double porDefecto) {
  final v = m[campo];
  return v is num ? v.toDouble() : porDefecto;
}

/// Mayor probabilidad de precipitación del día actual (null si no hay datos).
double? _probLluviaHoy(Map<String, dynamic> clima) {
  final hourly = clima['hourly'] as Map<String, dynamic>?;
  final actual = clima['current'] as Map<String, dynamic>;
  final ahora = actual['time'] as String?;
  if (hourly == null || ahora == null) return null;

  final dia = ahora.substring(0, 10);
  final horas = hourly['time'] as List<dynamic>;
  final probs = hourly['precipitation_probability'] as List<dynamic>;

  double? maximo;
  for (var i = 0; i < horas.length; i++) {
    final p = probs[i];
    if (p is num && (horas[i] as String).startsWith(dia)) {
      if (maximo == null || p > maximo) maximo = p.toDouble();
    }
  }
  return maximo;
}

/// Índice UV máximo de hoy y la hora (HH:MM) en que se espera, si hay datos.
({double maximo, String? hora}) _uvHoy(Map<String, dynamic> clima) {
  final actual = clima['current'] as Map<String, dynamic>;
  final ahora = actual['time'] as String?;
  final hourly = clima['hourly'] as Map<String, dynamic>?;

  double maximo = 0;
  String? hora;

  if (hourly != null && ahora != null && hourly['uv_index'] is List) {
    final dia = ahora.substring(0, 10);
    final horas = hourly['time'] as List<dynamic>;
    final uvs = hourly['uv_index'] as List<dynamic>;
    for (var i = 0; i < horas.length; i++) {
      final u = uvs[i];
      if (u is num && (horas[i] as String).startsWith(dia) && u > maximo) {
        maximo = u.toDouble();
        hora = (horas[i] as String).substring(11, 16);
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
  if (uvActual > maximo) maximo = uvActual;

  return (maximo: maximo, hora: hora);
}

/// Reglas que convierten el clima actual en una lista de actividades,
/// ordenadas de la más a la menos recomendable.
List<Actividad> evaluarActividades(Map<String, dynamic> clima) {
  final actual = clima['current'] as Map<String, dynamic>;

  final temp = _num(actual, 'apparent_temperature', _num(actual, 'temperature_2m', 20));
  final humedad = _num(actual, 'relative_humidity_2m', 50);
  final presion = _num(actual, 'surface_pressure', 1013);
  final viento = _num(actual, 'wind_speed_10m', 0);
  final precip = _num(actual, 'precipitation', 0);
  final codigo = _num(actual, 'weather_code', 0).toInt();
  final prob = _probLluviaHoy(clima) ?? 0;
  final uvActual = _num(actual, 'uv_index', 0);
  final uvDia = _uvHoy(clima);

  final tormenta = codigo >= 95;
  final lluvia = precip > 0 ||
      (codigo >= 51 && codigo != 45 && codigo != 48 && codigo < 95);
  final posibleLluvia = prob >= 50;

  // --- Ejercicio al aire libre ---
  Actividad ejercicioFuera() {
    const n = 'Ejercicio al aire libre';
    const i = Icons.directions_run;
    if (tormenta) return const Actividad(n, i, Nivel.evitar, 'Hay tormenta: es peligroso salir.');
    if (lluvia) return const Actividad(n, i, Nivel.evitar, 'Está lloviendo.');
    if (temp >= 33) return const Actividad(n, i, Nivel.evitar, 'Calor extremo: riesgo de golpe de calor.');
    if (temp <= 2) return const Actividad(n, i, Nivel.evitar, 'Demasiado frío para ejercitarse afuera.');
    if (viento >= 40) return const Actividad(n, i, Nivel.evitar, 'Viento muy fuerte.');
    if (temp >= 28) return const Actividad(n, i, Nivel.regular, 'Hace calor: hidrátate y busca sombra o las primeras horas del día.');
    if (temp <= 8) return const Actividad(n, i, Nivel.regular, 'Hace frío: abrígate y haz un buen calentamiento.');
    if (posibleLluvia) return const Actividad(n, i, Nivel.regular, 'Puede llover más tarde: sal pronto.');
    if (viento >= 25) return const Actividad(n, i, Nivel.regular, 'Viento moderado: puede dificultar correr o andar en bici.');
    if (humedad >= 80 && temp >= 24) return const Actividad(n, i, Nivel.regular, 'Mucha humedad: bajarás el ritmo.');
    if (uvActual >= 6) {
      return Actividad(n, i, Nivel.regular,
          'UV ${nivelUv(uvActual).etiqueta.toLowerCase()} (${uvActual.toStringAsFixed(1)}): usa protector y evita las horas centrales.');
    }
    if (uvActual >= 3) {
      return Actividad(n, i, Nivel.ideal,
          'Clima agradable. Usa protector solar (UV ${uvActual.toStringAsFixed(1)}).');
    }
    return const Actividad(n, i, Nivel.ideal, 'Temperatura agradable y sin lluvia.');
  }

  // --- Ejercicio en interiores ---
  Actividad ejercicioDentro() {
    const n = 'Ejercicio en interiores';
    const i = Icons.fitness_center;
    final fuera = ejercicioFuera().nivel;
    if (fuera == Nivel.evitar) {
      return const Actividad(n, i, Nivel.ideal, 'Buena alternativa a salir con este clima.');
    }
    if (fuera == Nivel.regular) {
      return const Actividad(n, i, Nivel.ideal, 'Opción cómoda cuando afuera no es lo ideal.');
    }
    return const Actividad(n, i, Nivel.regular, 'Se puede, pero el clima favorece salir.');
  }

  // --- Estudiar / trabajo concentrado ---
  Actividad estudiar() {
    const n = 'Estudiar / trabajo concentrado';
    const i = Icons.menu_book;
    final avisos = <String>[];
    if (temp >= 27) avisos.add('el calor aumenta la somnolencia');
    if (humedad >= 75 && temp >= 22) avisos.add('la humedad alta pesa');
    if (presion < 1005) avisos.add('la presión baja puede causar fatiga y dolor de cabeza');

    if (avisos.isNotEmpty) {
      final texto = avisos.join(', ');
      return Actividad(n, i, Nivel.regular,
          'Ojo: ${texto[0].toUpperCase()}${texto.substring(1)}. Haz lo más pesado temprano y toma pausas.');
    }
    if (temp >= 17 && temp <= 25) {
      return const Actividad(n, i, Nivel.ideal, 'Temperatura y presión favorables para concentrarse.');
    }
    if (temp < 12) {
      return const Actividad(n, i, Nivel.regular, 'Hace frío: abrígate para no perder foco.');
    }
    return const Actividad(n, i, Nivel.ideal, 'Condiciones estables para concentrarse.');
  }

  // --- Limpiar la casa ---
  Actividad limpiar() {
    const n = 'Limpiar la casa';
    const i = Icons.cleaning_services;
    if (lluvia || tormenta) {
      return const Actividad(n, i, Nivel.regular, 'Buen momento para limpieza interior; mantén las ventanas cerradas.');
    }
    if (viento >= 35) {
      return const Actividad(n, i, Nivel.regular, 'Mucho viento: entrará polvo si ventilas.');
    }
    if (humedad >= 85) {
      return const Actividad(n, i, Nivel.regular, 'Humedad alta: el aire no ayuda a secar ni a ventilar.');
    }
    return const Actividad(n, i, Nivel.ideal, 'Seco y sin lluvia: ventila bien mientras limpias.');
  }

  // --- Lavar y tender ropa ---
  Actividad ropa() {
    const n = 'Lavar y tender ropa';
    const i = Icons.local_laundry_service;
    if (tormenta || lluvia || prob >= 60) {
      return const Actividad(n, i, Nivel.evitar, 'Riesgo de lluvia: la ropa no se secará afuera.');
    }
    if (humedad >= 85) {
      return const Actividad(n, i, Nivel.evitar, 'Humedad muy alta: tardará mucho en secar.');
    }
    if (posibleLluvia || humedad >= 70 || temp < 12) {
      return const Actividad(n, i, Nivel.regular, 'Se secará lento; mejor tender en un lugar cubierto.');
    }
    return const Actividad(n, i, Nivel.ideal, 'Seco y con aire: la ropa secará rápido.');
  }

  // --- Paseo / salir ---
  Actividad paseo() {
    const n = 'Salir a pasear';
    const i = Icons.park;
    if (tormenta) return const Actividad(n, i, Nivel.evitar, 'Hay tormenta.');
    if (lluvia) return const Actividad(n, i, Nivel.evitar, 'Está lloviendo: lleva paraguas si es necesario.');
    if (temp >= 33 || temp <= 2) return const Actividad(n, i, Nivel.evitar, 'Temperatura extrema para estar afuera.');
    if (temp >= 29 || temp <= 8 || viento >= 30 || posibleLluvia) {
      return const Actividad(n, i, Nivel.regular, 'Se puede, pero ve preparado (abrigo, agua o paraguas).');
    }
    if (uvActual >= 6) {
      return Actividad(n, i, Nivel.regular,
          'UV ${nivelUv(uvActual).etiqueta.toLowerCase()} (${uvActual.toStringAsFixed(1)}): protégete y busca sombra.');
    }
    if (uvActual >= 3) {
      return Actividad(n, i, Nivel.ideal,
          'Clima agradable. Usa protector solar (UV ${uvActual.toStringAsFixed(1)}).');
    }
    return const Actividad(n, i, Nivel.ideal, 'Clima agradable para estar afuera.');
  }

  // --- Exposición al sol (índice UV) ---
  Actividad sol() {
    const n = 'Exposición al sol';
    const i = Icons.wb_sunny;
    final uv = uvDia.maximo;
    final nivel = nivelUv(uv);
    final pico = uvDia.hora != null ? ' Pico a las ${uvDia.hora}.' : '';
    final base = 'UV máx. hoy ${uv.toStringAsFixed(1)} (${nivel.etiqueta.toLowerCase()}). ${nivel.consejo}$pico';
    if (uv >= 8) return Actividad(n, i, Nivel.evitar, base);
    if (uv >= 3) return Actividad(n, i, Nivel.regular, base);
    return Actividad(n, i, Nivel.ideal, base);
  }

  final lista = [
    ejercicioFuera(),
    ejercicioDentro(),
    estudiar(),
    limpiar(),
    ropa(),
    paseo(),
    sol(),
  ];

  // Orden estable: ideal primero, evitar al final.
  final indexados = lista.asMap().entries.toList()
    ..sort((a, b) {
      final c = a.value.nivel.index.compareTo(b.value.nivel.index);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
  return [for (final e in indexados) e.value];
}

class _FilaActividad extends StatelessWidget {
  final Actividad actividad;

  const _FilaActividad({required this.actividad});

  @override
  Widget build(BuildContext context) {
    final (color, etiqueta) = switch (actividad.nivel) {
      Nivel.ideal => (Colors.green, 'Ideal'),
      Nivel.regular => (Colors.orange, 'Con cuidado'),
      Nivel.evitar => (Colors.red, 'Evitar'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(actividad.icono, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actividad.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  actividad.motivo,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            etiqueta,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
