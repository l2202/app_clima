import 'package:flutter/material.dart';
import 'package:app_clima/theme/tema.dart';

class RopaClima extends StatelessWidget {
  final Future<Map<String, dynamic>> consulta;

  const RopaClima({super.key, required this.consulta});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: consulta,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final clima = snapshot.data!['clima'];
        final actual = clima['current'];

        final temperatura = (actual['temperature_2m'] as num).toDouble();

        final sensacion =
            (actual['apparent_temperature'] as num?)?.toDouble() ?? temperatura;

        final viento = (actual['wind_speed_10m'] as num?)?.toDouble() ?? 0;

        final codigo = (actual['weather_code'] as num).toInt();

        final uv = (actual['uv_index'] as num?)?.toDouble();

        final colores = PaletaClima.obtenerColores(temperatura, codigo);

        final ropa = <Widget>[];
        final consejos = <String>[];

        if (sensacion >= 30) {
          ropa.add(
            _Prenda(
              Icons.checkroom_rounded,
              'Ropa ligera',
              const Color(0xFFE6A15D),
              colores,
            ),
          );

          ropa.add(
            _Prenda(
              Icons.wb_sunny_rounded,
              'Gorra o sombrero',
              const Color(0xFFE7B54E),
              colores,
            ),
          );

          consejos.add(
            'Hace bastante calor. Prefiere ropa fresca, '
            'ligera y transpirable.',
          );
        } else if (sensacion >= 23) {
          ropa.add(
            _Prenda(
              Icons.checkroom_rounded,
              'Playera cómoda',
              const Color(0xFF83A8DB),
              colores,
            ),
          );

          ropa.add(
            _Prenda(
              Icons.wb_sunny_outlined,
              'Gorra opcional',
              const Color(0xFFE7B54E),
              colores,
            ),
          );

          consejos.add(
            'La temperatura es agradable o cálida. '
            'Utiliza ropa cómoda y fresca.',
          );
        } else if (sensacion >= 16) {
          ropa.add(
            _Prenda(
              Icons.checkroom_rounded,
              'Suéter ligero',
              const Color(0xFFA58ED4),
              colores,
            ),
          );

          ropa.add(
            _Prenda(
              Icons.dry_cleaning_rounded,
              'Pantalón largo',
              const Color(0xFF7FA6D5),
              colores,
            ),
          );

          consejos.add(
            'El ambiente está fresco. '
            'Llevar una prenda ligera adicional puede ser útil.',
          );
        } else if (sensacion >= 10) {
          ropa.add(
            _Prenda(
              Icons.checkroom_rounded,
              'Chamarra',
              const Color(0xFF9C8CCB),
              colores,
            ),
          );

          ropa.add(
            _Prenda(
              Icons.dry_cleaning_rounded,
              'Pantalón largo',
              const Color(0xFF78A4D1),
              colores,
            ),
          );

          consejos.add(
            'Hace frío. Utiliza ropa abrigadora '
            'y considera vestirte en capas.',
          );
        } else {
          ropa.add(
            _Prenda(
              Icons.checkroom_rounded,
              'Abrigo grueso',
              const Color(0xFF8E85C9),
              colores,
            ),
          );

          ropa.add(
            _Prenda(
              Icons.ac_unit_rounded,
              'Bufanda y guantes',
              const Color(0xFF73B4CF),
              colores,
            ),
          );

          consejos.add(
            'La temperatura es muy baja. '
            'Abrígate bien y protege tus manos y cuello.',
          );
        }

        final lluvia =
            (codigo >= 51 && codigo <= 67) ||
            (codigo >= 80 && codigo <= 82) ||
            (codigo >= 95 && codigo <= 99);

        if (lluvia) {
          ropa.add(
            _Prenda(
              Icons.umbrella_rounded,
              'Paraguas',
              const Color(0xFF6BA5D8),
              colores,
            ),
          );

          ropa.add(
            _Prenda(
              Icons.water_drop_rounded,
              'Calzado cerrado',
              const Color(0xFF77B8C5),
              colores,
            ),
          );

          consejos.add(
            'Hay condiciones de lluvia. '
            'Lleva paraguas o impermeable '
            'y procura utilizar calzado adecuado.',
          );
        }

        if (viento >= 30) {
          ropa.add(
            _Prenda(
              Icons.air_rounded,
              'Rompevientos',
              const Color(0xFF85B6BF),
              colores,
            ),
          );

          consejos.add(
            'Hay bastante viento. '
            'Una chamarra rompevientos puede ayudarte '
            'a sentirte más cómodo.',
          );
        }

        if (uv != null && uv >= 3) {
          ropa.add(
            _Prenda(
              Icons.wb_sunny_rounded,
              'Protección solar',
              const Color(0xFFE8B04C),
              colores,
            ),
          );

          consejos.add(
            'El índice UV requiere protección. '
            'Utiliza protector solar, busca sombra '
            'y considera llevar lentes de sol.',
          );
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colores.colorTarjeta,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colores.colorBorde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colores.colorTarjetaSecundaria,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.checkroom_rounded,
                      color: colores.colorAcento,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '¿Qué me pongo hoy?',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: colores.colorTextoOscuro,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Recomendaciones para vestirte '
                'según las condiciones del clima.',
                style: TextStyle(fontSize: 13, color: colores.colorTextoSuave),
              ),

              const SizedBox(height: 18),

              Wrap(spacing: 10, runSpacing: 10, children: ropa),

              const SizedBox(height: 18),

              Text(
                'Consejos para salir',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colores.colorTextoOscuro,
                ),
              ),

              const SizedBox(height: 10),

              for (final consejo in consejos)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colores.colorTarjetaSecundaria,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.tips_and_updates_rounded,
                        color: colores.colorAcento,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          consejo,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: colores.colorTextoOscuro,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Prenda extends StatelessWidget {
  final IconData icono;
  final String nombre;
  final Color colorIcono;
  final ColoresClima colores;

  const _Prenda(this.icono, this.nombre, this.colorIcono, this.colores);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: colores.colorTarjetaSecundaria,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colores.colorBorde),
      ),
      child: Column(
        children: [
          Icon(icono, color: colorIcono, size: 34),
          const SizedBox(height: 9),
          Text(
            nombre,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colores.colorTextoOscuro,
            ),
          ),
        ],
      ),
    );
  }
}
