import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:app_clima/theme/tema.dart';

class TarjetaClima extends StatelessWidget {
  final Future<Map<String, dynamic>> consulta;

  const TarjetaClima({super.key, required this.consulta});

  String _mensajeError(Object e) {
    if (e is SocketException) return 'No tienes conexión a Internet';
    if (e is HttpException) return 'Error con el servidor';
    if (e is TimeoutException) return 'La consulta tardó demasiado';
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _mensajeError(snapshot.error!),
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          );
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

    String valor(String campo) => '${actual[campo]} ${unidades[campo]}';

    final pais = ubicacion['country'];

    // Obtener temperatura y código del clima
    final temperatura = (actual['temperature_2m'] as num).toDouble();
    final codigoClima = (actual['weather_code'] as num).toInt();

    // Obtener los colores correspondientes al clima
    final colores = PaletaClima.obtenerColores(
      temperatura: temperatura,
      codigoClima: codigoClima,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: colores.degradadoFondo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colores.colorBorde, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ubicación
            Text(
              '${ubicacion['name']}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colores.colorTextoOscuro,
              ),
            ),

            if (pais != null)
              Text(
                '$pais',
                style: TextStyle(fontSize: 14, color: colores.colorTextoSuave),
              ),

            const SizedBox(height: 8),

            Text(
              colores.nombreEstado,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colores.colorAcento,
              ),
            ),

            const SizedBox(height: 18),

            // Tarjeta de información
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: colores.colorTarjeta,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: colores.colorBorde),
              ),
              child: Column(
                children: [
                  _Fila(
                    Icons.thermostat,
                    'Temperatura',
                    valor('temperature_2m'),
                    colores,
                  ),
                  _Fila(
                    Icons.person,
                    'Sensación',
                    valor('apparent_temperature'),
                    colores,
                  ),
                  _Fila(
                    Icons.water_drop,
                    'Humedad',
                    valor('relative_humidity_2m'),
                    colores,
                  ),
                  _Fila(
                    Icons.speed,
                    'Presión',
                    valor('surface_pressure'),
                    colores,
                  ),
                  _Fila(Icons.air, 'Viento', valor('wind_speed_10m'), colores),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final coloresClima colores;

  const _Fila(this.icono, this.etiqueta, this.valor, this.colores);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icono, size: 22, color: colores.colorAcento),
          const SizedBox(width: 10),

          Expanded(
            child: Text(
              etiqueta,
              style: TextStyle(color: colores.colorTextoSuave, fontSize: 14),
            ),
          ),

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
