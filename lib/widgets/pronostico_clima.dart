import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:app_clima/theme/tema.dart';

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
    return FutureBuilder<Map<String, dynamic>>(
      future: consulta,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 150,
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

        final clima = snapshot.data!['clima'] as Map<String, dynamic>;

        return _Pronostico(
          key: ObjectKey(snapshot.data),
          clima: clima,
          intervalo: intervalo,
        );
      },
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

    if (_total <= 1) return;

    _timer = Timer.periodic(widget.intervalo, (_) {
      if (!mounted || _fijado) return;

      setState(() {
        _seleccionado = (_seleccionado + 1) % _total;
      });
    });
  }

  void _tocarDia(int i) {
    setState(() {
      if (_fijado && _seleccionado == i) {
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

  // Obtener la mayor probabilidad de lluvia del día
  num? _probLluvia(int i) {
    final hourly = widget.clima['hourly'] as Map<String, dynamic>?;

    if (hourly == null) return null;

    final horas = hourly['time'] as List<dynamic>;
    final probs = hourly['precipitation_probability'] as List<dynamic>;

    num? maximo;

    for (var h = 0; h < horas.length && h < probs.length; h++) {
      final p = probs[h];

      if (p != null && (horas[h] as String).startsWith(_fechas[i])) {
        if (maximo == null || (p as num) > maximo) {
          maximo = p as num;
        }
      }
    }

    return maximo;
  }

  @override
  Widget build(BuildContext context) {
    if (_total == 0) {
      return const Text('No hay pronóstico disponible');
    }

    final daily = widget.clima['daily'] as Map<String, dynamic>;

    final unidades = widget.clima['daily_units'] as Map<String, dynamic>;

    final codigo = (daily['weather_code'][_seleccionado] as num).toInt();

    final max = daily['temperature_2m_max'][_seleccionado];
    final min = daily['temperature_2m_min'][_seleccionado];

    final unidad = unidades['temperature_2m_max'];

    final temperatura = (max as num).toDouble();

    final colores = PaletaClima.obtenerColores(
      temperatura: temperatura,
      codigoClima: codigo,
    );

    final lluvia = _probLluvia(_seleccionado);
    final estado = _estadoDeCodigo(codigo);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: colores.degradadoFondo,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colores.colorBorde, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Icon(Icons.calendar_month, color: colores.colorAcento, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pronóstico de 5 días',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: colores.colorTextoOscuro,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Selecciona un día para consultar el clima',
            style: TextStyle(fontSize: 12, color: colores.colorTextoSuave),
          ),

          const SizedBox(height: 18),

          // Selector de días
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
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: i == _seleccionado
                                ? Colors.white
                                : colores.colorTextoOscuro,
                          ),
                        ),
                      ),
                      selected: i == _seleccionado,
                      onSelected: (_) => _tocarDia(i),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 7,
                      ),
                      labelPadding: EdgeInsets.zero,
                      backgroundColor: colores.colorTarjeta,
                      selectedColor: colores.colorAcento,
                      side: BorderSide(
                        color: i == _seleccionado
                            ? colores.colorAcento
                            : colores.colorBorde,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          // Tarjeta del día seleccionado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colores.colorTarjeta,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colores.colorBorde),
            ),
            child: Column(
              children: [
                // Estado del clima
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colores.colorTarjetaSecundaria,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        estado.icono,
                        size: 38,
                        color: colores.colorAcento,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _etiqueta(_seleccionado),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: colores.colorTextoOscuro,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            estado.texto,
                            style: TextStyle(
                              fontSize: 13,
                              color: colores.colorTextoSuave,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_fijado)
                      Icon(
                        Icons.push_pin,
                        color: colores.colorAcento,
                        size: 19,
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // Temperaturas máxima y mínima
                Row(
                  children: [
                    Expanded(
                      child: _Temperatura(
                        icono: Icons.arrow_upward,
                        titulo: 'Máxima',
                        valor: '$max$unidad',
                        colores: colores,
                      ),
                    ),

                    Container(width: 1, height: 65, color: colores.colorBorde),

                    Expanded(
                      child: _Temperatura(
                        icono: Icons.arrow_downward,
                        titulo: 'Mínima',
                        valor: '$min$unidad',
                        colores: colores,
                      ),
                    ),
                  ],
                ),

                // Probabilidad de lluvia
                if (lluvia != null) ...[
                  const SizedBox(height: 18),

                  Divider(color: colores.colorBorde),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(
                        Icons.water_drop,
                        color: colores.colorAcentoSecundario,
                        size: 28,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Probabilidad de lluvia',
                              style: TextStyle(
                                color: colores.colorTextoSuave,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 7),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: (lluvia / 100)
                                    .clamp(0.0, 1.0)
                                    .toDouble(),
                                minHeight: 8,
                                backgroundColor: colores.colorTarjetaSecundaria,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colores.colorAcentoSecundario,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 15),

                      Text(
                        '$lluvia%',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: colores.colorAcento,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Text(
                    'Probabilidad de lluvia no disponible',
                    style: TextStyle(
                      color: colores.colorTextoSuave,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Indicador de rotación
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _fijado ? Icons.push_pin : Icons.autorenew,
                size: 16,
                color: colores.colorAcento,
              ),
              const SizedBox(width: 6),
              Text(
                _fijado
                    ? 'Día seleccionado manualmente'
                    : 'Cambio automático cada 10 segundos',
                style: TextStyle(fontSize: 11, color: colores.colorTextoSuave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget de temperatura
class _Temperatura extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final coloresClima colores;

  const _Temperatura({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.colores,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icono, color: colores.colorAcento, size: 23),
        const SizedBox(height: 6),
        Text(
          titulo,
          style: TextStyle(fontSize: 12, color: colores.colorTextoSuave),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: colores.colorTextoOscuro,
          ),
        ),
      ],
    );
  }
}

// Estado del clima
class _Estado {
  final IconData icono;
  final String texto;

  const _Estado(this.icono, this.texto);
}

// Códigos meteorológicos WMO
_Estado _estadoDeCodigo(int c) {
  if (c == 0) {
    return const _Estado(Icons.wb_sunny, 'Despejado');
  }
  if (c <= 3) {
    return const _Estado(Icons.wb_cloudy, 'Parcialmente nublado');
  }
  if (c == 45 || c == 48) {
    return const _Estado(Icons.foggy, 'Niebla');
  }
  if (c >= 51 && c <= 57) {
    return const _Estado(Icons.grain, 'Llovizna');
  }
  if (c >= 61 && c <= 67) {
    return const _Estado(Icons.water_drop, 'Lluvia');
  }
  if (c >= 71 && c <= 77) {
    return const _Estado(Icons.ac_unit, 'Nieve');
  }
  if (c >= 80 && c <= 82) {
    return const _Estado(Icons.shower, 'Chubascos');
  }
  if (c == 85 || c == 86) {
    return const _Estado(Icons.ac_unit, 'Chubascos de nieve');
  }
  if (c >= 95) {
    return const _Estado(Icons.thunderstorm, 'Tormenta');
  }

  return const _Estado(Icons.help_outline, 'Sin datos');
}
