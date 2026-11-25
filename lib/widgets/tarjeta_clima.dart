import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:app_clima/theme/tema.dart';
import 'package:app_clima/widgets/indice_uv.dart';

class TarjetaClima extends StatelessWidget {
  final Future<Map<String, dynamic>> consulta;

  const TarjetaClima({super.key, required this.consulta});

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
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _mensajeError(snapshot.error!),
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        return _Contenido(datos: snapshot.data!);
      },
    );
  }
}

class _Contenido extends StatelessWidget {
  final Map<String, dynamic> datos;

  const _Contenido({required this.datos});

  @override
  Widget build(BuildContext context) {
    final ubicacion = datos['ubicacion'] as Map<String, dynamic>;

    final clima = datos['clima'] as Map<String, dynamic>;

    final actual = clima['current'] as Map<String, dynamic>;

    final unidades = clima['current_units'] as Map<String, dynamic>;

    String valor(String campo) {
      final dato = actual[campo];
      final unidad = unidades[campo] ?? '';

      if (dato == null) {
        return 'No disponible';
      }

      return '$dato $unidad';
    }

    final pais = ubicacion['country'];

    final temperatura = (actual['temperature_2m'] as num).toDouble();

    final codigoClima = (actual['weather_code'] as num).toInt();

    final colores = PaletaClima.obtenerColores(temperatura, codigoClima);

    IconData iconoClima;

    if (codigoClima >= 95) {
      iconoClima = Icons.thunderstorm_rounded;
    } else if ((codigoClima >= 51 && codigoClima <= 67) ||
        (codigoClima >= 80 && codigoClima <= 82)) {
      iconoClima = Icons.water_drop_rounded;
    } else if ((codigoClima >= 71 && codigoClima <= 77) ||
        codigoClima == 85 ||
        codigoClima == 86) {
      iconoClima = Icons.ac_unit_rounded;
    } else if (codigoClima >= 45 && codigoClima <= 48) {
      iconoClima = Icons.foggy;
    } else if (codigoClima >= 1 && codigoClima <= 3) {
      iconoClima = Icons.cloud_rounded;
    } else {
      iconoClima = Icons.wb_sunny_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colores.colorTarjeta,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colores.colorBorde, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: colores.colorAcento.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // UBICACIÓN

          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: colores.colorAcento,
                size: 22,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${ubicacion['name']}',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: colores.colorTextoOscuro,
                  ),
                ),
              ),
            ],
          ),

          if (pais != null)
            Padding(
              padding: const EdgeInsets.only(left: 29, top: 3),
              child: Text(
                '$pais',
                style: TextStyle(fontSize: 14, color: colores.colorTextoSuave),
              ),
            ),

          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colores.colorTarjetaSecundaria,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colores.colorBorde),
            ),
            child: Column(
              children: [
                Icon(iconoClima, size: 75, color: colores.colorAcento),

                const SizedBox(height: 8),

                Text(
                  '${temperatura.toStringAsFixed(1)}°',
                  style: TextStyle(
                    fontSize: 47,
                    fontWeight: FontWeight.bold,
                    color: colores.colorTextoOscuro,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  colores.nombreEstado,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colores.colorAcento,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text(
            'Detalles del clima',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: colores.colorTextoOscuro,
            ),
          ),

          const SizedBox(height: 12),

          _Fila(
            Icons.thermostat_rounded,
            'Temperatura',
            valor('temperature_2m'),
            colores,
            const Color(0xFFFF9B54),
          ),

          _Fila(
            Icons.device_thermostat_rounded,
            'Sensación térmica',
            valor('apparent_temperature'),
            colores,
            const Color(0xFFB58BDD),
          ),

          _Fila(
            Icons.water_drop_rounded,
            'Humedad',
            valor('relative_humidity_2m'),
            colores,
            const Color(0xFF63B5E8),
          ),

          _Fila(
            Icons.speed_rounded,
            'Presión',
            valor('surface_pressure'),
            colores,
            const Color(0xFFEDAC63),
          ),

          _Fila(
            Icons.air_rounded,
            'Viento',
            valor('wind_speed_10m'),
            colores,
            const Color(0xFF65B995),
          ),

          if (actual['uv_index'] is num)
            _Fila(
              Icons.wb_sunny_rounded,
              'Índice UV',
              '${(actual['uv_index'] as num).toStringAsFixed(1)} · '
                  '${nivelUv((actual['uv_index'] as num).toDouble()).etiqueta}',
              colores,
              const Color(0xFFE9A34B),
            ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final ColoresClima colores;
  final Color colorIcono;

  const _Fila(
    this.icono,
    this.etiqueta,
    this.valor,
    this.colores,
    this.colorIcono,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colores.colorTarjetaSecundaria,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colores.colorBorde),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: colorIcono.withOpacity(0.13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icono, color: colorIcono, size: 23),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              etiqueta,
              style: TextStyle(color: colores.colorTextoSuave, fontSize: 14),
            ),
          ),

          const SizedBox(width: 8),

          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colores.colorTextoOscuro,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
