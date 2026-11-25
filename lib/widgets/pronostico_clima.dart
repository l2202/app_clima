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
            height: 150,
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

  static const List<String> _dias = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  @override
  void initState() {
    super.initState();
    _iniciarRotacion();
  }

  void _iniciarRotacion() {
    _timer?.cancel();

    if (_total <= 1) {
      return;
    }

    _timer = Timer.periodic(widget.intervalo, (_) {
      if (!mounted || _fijado) {
        return;
      }

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

  String _etiqueta(int i) {
    if (i == 0) {
      return 'Hoy';
    }

    final fecha = DateTime.parse(_fechas[i].toString());

    return '${_dias[fecha.weekday - 1]} ${fecha.day}';
  }

  num? _probLluvia(int i) {
    final hourly = widget.clima['hourly'] as Map<String, dynamic>?;

    if (hourly == null) {
      return null;
    }

    final horas = hourly['time'] as List<dynamic>?;
    final probabilidades =
        hourly['precipitation_probability'] as List<dynamic>?;

    if (horas == null || probabilidades == null) {
      return null;
    }

    num? maximo;

    for (int h = 0; h < horas.length && h < probabilidades.length; h++) {
      final probabilidad = probabilidades[h];

      if (probabilidad is num &&
          horas[h].toString().startsWith(_fechas[i].toString())) {
        if (maximo == null || probabilidad > maximo) {
          maximo = probabilidad;
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

    final unidad = unidades['temperature_2m_max'] ?? '°C';

    final temperatura = (max as num).toDouble();

    final colores = PaletaClima.obtenerColores(temperatura, codigo);

    final lluvia = _probLluvia(_seleccionado);
    final estado = _estadoDeCodigo(codigo);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colores.colorAcento.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: colores.colorAcento,
                  size: 25,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  'Pronóstico de 5 días',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colores.colorTextoOscuro,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Selecciona un día para consultar el clima',
            style: TextStyle(fontSize: 13, color: colores.colorTextoSuave),
          ),

          const SizedBox(height: 18),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < _total; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(
                        _etiqueta(i),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: i == _seleccionado
                              ? Colors.white
                              : colores.colorTextoOscuro,
                        ),
                      ),
                      selected: i == _seleccionado,
                      onSelected: (_) => _tocarDia(i),
                      showCheckmark: false,
                      backgroundColor: colores.colorTarjetaSecundaria,
                      selectedColor: colores.colorAcento,
                      side: BorderSide(
                        color: i == _seleccionado
                            ? colores.colorAcento
                            : colores.colorBorde,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: colores.colorTarjetaSecundaria,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colores.colorBorde),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                        Icons.push_pin_rounded,
                        color: colores.colorAcento,
                        size: 19,
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _Temperatura(
                        icono: Icons.arrow_upward_rounded,
                        titulo: 'Máxima',
                        valor: '$max$unidad',
                        colores: colores,
                        colorIcono: const Color(0xFFFF9B54),
                      ),
                    ),

                    Container(width: 1, height: 65, color: colores.colorBorde),

                    Expanded(
                      child: _Temperatura(
                        icono: Icons.arrow_downward_rounded,
                        titulo: 'Mínima',
                        valor: '$min$unidad',
                        colores: colores,
                        colorIcono: const Color(0xFF63B5E8),
                      ),
                    ),
                  ],
                ),
                if (lluvia != null) ...[
                  const SizedBox(height: 18),

                  Divider(color: colores.colorBorde),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(
                        Icons.water_drop_rounded,
                        color: Color(0xFF63B5E8),
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

                            const SizedBox(height: 8),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: (lluvia / 100)
                                    .clamp(0.0, 1.0)
                                    .toDouble(),
                                minHeight: 8,
                                backgroundColor: Colors.white,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF63B5E8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      Text(
                        '$lluvia%',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3986C9),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 14),

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

          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _fijado ? Icons.push_pin_rounded : Icons.autorenew_rounded,
                size: 16,
                color: colores.colorAcento,
              ),

              const SizedBox(width: 6),

              Flexible(
                child: Text(
                  _fijado
                      ? 'Día seleccionado manualmente'
                      : 'Cambio automático cada ${widget.intervalo.inSeconds} segundos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: colores.colorTextoSuave,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Temperatura extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final ColoresClima colores;
  final Color colorIcono;

  const _Temperatura({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.colores,
    required this.colorIcono,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icono, color: colorIcono, size: 24),

        const SizedBox(height: 7),

        Text(
          titulo,
          style: TextStyle(fontSize: 12, color: colores.colorTextoSuave),
        ),

        const SizedBox(height: 5),

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

class _Estado {
  final IconData icono;
  final String texto;

  const _Estado(this.icono, this.texto);
}

_Estado _estadoDeCodigo(int codigo) {
  if (codigo == 0) {
    return const _Estado(Icons.wb_sunny_rounded, 'Despejado');
  }

  if (codigo >= 1 && codigo <= 3) {
    return const _Estado(Icons.cloud_rounded, 'Parcialmente nublado');
  }

  if (codigo == 45 || codigo == 48) {
    return const _Estado(Icons.foggy, 'Niebla');
  }

  if (codigo >= 51 && codigo <= 57) {
    return const _Estado(Icons.grain_rounded, 'Llovizna');
  }

  if (codigo >= 61 && codigo <= 67) {
    return const _Estado(Icons.water_drop_rounded, 'Lluvia');
  }

  if (codigo >= 71 && codigo <= 77) {
    return const _Estado(Icons.ac_unit_rounded, 'Nieve');
  }

  if (codigo >= 80 && codigo <= 82) {
    return const _Estado(Icons.water_drop_rounded, 'Chubascos');
  }

  if (codigo == 85 || codigo == 86) {
    return const _Estado(Icons.ac_unit_rounded, 'Chubascos de nieve');
  }

  if (codigo >= 95) {
    return const _Estado(Icons.thunderstorm_rounded, 'Tormenta');
  }

  return const _Estado(Icons.help_outline_rounded, 'Sin datos');
}
