import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

/// Recuadro estático que muestra la información básica del clima actual.
///
/// Recibe la [consulta] (el resultado de `ClimaService`) y se encarga de
/// mostrar el estado de carga, el error o los datos.
///
/// Uso:
/// ```dart
/// TarjetaClima(consulta: ClimaService().buscarClima('Madrid'));
/// ```
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

            return _Contenido(datos: snapshot.data!);
          },
        ),
      ),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${ubicacion['name']}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (pais != null)
          Text('$pais', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        _Fila(Icons.thermostat, 'Temperatura', valor('temperature_2m')),
        _Fila(Icons.person, 'Sensación', valor('apparent_temperature')),
        _Fila(Icons.water_drop, 'Humedad', valor('relative_humidity_2m')),
        _Fila(Icons.speed, 'Presión', valor('surface_pressure')),
        _Fila(Icons.air, 'Viento', valor('wind_speed_10m')),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _Fila(this.icono, this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icono, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(etiqueta)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
