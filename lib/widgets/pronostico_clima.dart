import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

/// Recuadro con el pronóstico de los próximos 5 días.
///
/// En la parte superior se elige el día. Mientras ninguno esté fijado, los
/// días rotan solos cada [intervalo]. Al tocar un día se fija; al tocarlo de
/// nuevo se suelta y la rotación continúa.
///
/// Uso:
/// ```dart
/// PronosticoClima(consulta: ClimaService().buscarClima('Madrid'));
/// ```
class PronosticoClima extends StatelessWidget {
  final Future<Map<String, dynamic>> consulta;
  final Duration intervalo;

  const PronosticoClima({
    super.key,
    required this.consulta,
    this.intervalo = const Duration(seconds: 10),
  });

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
            return _Pronostico(
              // Reinicia selección y temporizador cuando cambia la consulta.
              key: ObjectKey(snapshot.data),
              clima: clima,
              intervalo: intervalo,
            );
          },
        ),
      ),
    );
  }
}

class _Pronostico extends StatefulWidget {
  final Map<String, dynamic> clima;
  final Duration intervalo;

  const _Pronostico({super.key, required this.clima, required this.intervalo});

  @override
  State<_Pronostico> createState() => _PronosticoState();
}

class _PronosticoState extends State<_Pronostico> {
  Timer? _timer;
  int _seleccionado = 0;
  bool _fijado = false;

  late final List<dynamic> _fechas = widget.clima['daily']['time'];

  int get _total => _fechas.length;

  @override
  void initState() {
    super.initState();
    _iniciarRotacion();
  }

  void _iniciarRotacion() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.intervalo, (_) {
      if (!mounted || _fijado) return;
      setState(() => _seleccionado = (_seleccionado + 1) % _total);
    });
  }

  void _tocarDia(int i) {
    setState(() {
      if (_fijado && _seleccionado == i) {
        // Soltar el día fijado: la rotación continúa.
        _fijado = false;
        _iniciarRotacion();
      } else {
        _seleccionado = i;
        _fijado = true;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  String _etiqueta(int i) {
    if (i == 0) return 'Hoy';
    final fecha = DateTime.parse(_fechas[i]);
    return '${_dias[fecha.weekday - 1]} ${fecha.day}';
  }

  /// Mayor probabilidad de precipitación por hora del día [i], si hay datos.
  num? _probLluvia(int i) {
    final hourly = widget.clima['hourly'] as Map<String, dynamic>?;
    if (hourly == null) return null;
    final horas = hourly['time'] as List<dynamic>;
    final probs = hourly['precipitation_probability'] as List<dynamic>;

    num? maximo;
    for (var h = 0; h < horas.length; h++) {
      final p = probs[h];
      if (p != null && (horas[h] as String).startsWith(_fechas[i])) {
        if (maximo == null || p > maximo) maximo = p;
      }
    }
    return maximo;
  }

  @override
  Widget build(BuildContext context) {
    final daily = widget.clima['daily'] as Map<String, dynamic>;
    final unidades = widget.clima['daily_units'] as Map<String, dynamic>;

    final codigo = daily['weather_code'][_seleccionado] as int;
    final max = daily['temperature_2m_max'][_seleccionado];
    final min = daily['temperature_2m_min'][_seleccionado];
    final unidad = unidades['temperature_2m_max'];
    final lluvia = _probLluvia(_seleccionado);
    final estado = _estadoDeCodigo(codigo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < _total; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ChoiceChip(
                    label: SizedBox(
                      width: double.infinity,
                      child: Text(
                        _etiqueta(i),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    labelPadding: EdgeInsets.zero,
                    showCheckmark: false,
                    selected: i == _seleccionado,
                    onSelected: (_) => _tocarDia(i),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(estado.icono, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                estado.texto,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (_fijado)
              const Tooltip(
                message: 'Día fijado: toca de nuevo para reanudar',
                child: Icon(Icons.push_pin, size: 18),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _Fila(Icons.arrow_upward, 'Máxima', '$max $unidad'),
        _Fila(Icons.arrow_downward, 'Mínima', '$min $unidad'),
        if (lluvia != null)
          _Fila(Icons.umbrella, 'Prob. de lluvia', '$lluvia %'),
      ],
    );
  }
}

class _Estado {
  final IconData icono;
  final String texto;
  const _Estado(this.icono, this.texto);
}

/// Traduce el código WMO de Open-Meteo a un icono y una descripción.
_Estado _estadoDeCodigo(int c) {
  if (c == 0) return const _Estado(Icons.wb_sunny, 'Despejado');
  if (c <= 3) return const _Estado(Icons.wb_cloudy, 'Parcialmente nublado');
  if (c == 45 || c == 48) return const _Estado(Icons.foggy, 'Niebla');
  if (c >= 51 && c <= 57) return const _Estado(Icons.grain, 'Llovizna');
  if (c >= 61 && c <= 67) return const _Estado(Icons.water_drop, 'Lluvia');
  if (c >= 71 && c <= 77) return const _Estado(Icons.ac_unit, 'Nieve');
  if (c >= 80 && c <= 82) return const _Estado(Icons.shower, 'Chubascos');
  if (c == 85 || c == 86) {
    return const _Estado(Icons.ac_unit, 'Chubascos de nieve');
  }
  if (c >= 95) return const _Estado(Icons.thunderstorm, 'Tormenta');
  return const _Estado(Icons.help_outline, 'Sin datos');
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
