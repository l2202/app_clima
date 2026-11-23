import 'package:flutter/material.dart';
import 'package:app_clima/theme/tema.dart';

class BienestarClima extends StatefulWidget {
  final Future<Map<String, dynamic>> consulta;

  const BienestarClima({super.key, required this.consulta});

  @override
  State<BienestarClima> createState() => _BienestarClimaState();
}

class _BienestarClimaState extends State<BienestarClima> {
  String emocion = '';

  double numero(dynamic valor, double defecto) {
    if (valor is num) {
      return valor.toDouble();
    }
    return defecto;
  }

  String mensajeEmocion() {
    if (emocion == 'Feliz') {
      return '¡Qué bonito que hoy te sientas bien! '
          'Aprovecha esa energía para disfrutar tus actividades, '
          'compartir momentos especiales y seguir haciendo lo que te gusta.';
    }

    if (emocion == 'Tranquilo') {
      return 'Disfruta este momento de tranquilidad. '
          'No todos los días tienen que estar llenos de actividades. '
          'También es importante descansar y disfrutar las pequeñas cosas.';
    }

    if (emocion == 'Cansado') {
      return '¡Has hecho mucho y mereces descansar! '
          'No tienes que hacerlo todo hoy. '
          'Avanza a tu propio ritmo y recuerda que descansar '
          'también es una forma de cuidarte.';
    }

    if (emocion == 'Triste') {
      return 'Está bien tener días difíciles. '
          'No tienes que sentirte feliz todo el tiempo. '
          'Date un momento para ti, haz algo que disfrutes '
          'o habla con alguien de confianza. '
          'Mañana puede traer nuevas oportunidades.';
    }

    if (emocion == 'Estresado') {
      return 'No tienes que resolver todo al mismo tiempo. '
          'Organiza tus pendientes poco a poco, '
          'toma una pausa y recuerda que cada pequeño avance cuenta.';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: widget.consulta,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox();
        }

        final clima = snapshot.data!['clima'] as Map<String, dynamic>;

        final actual = clima['current'] as Map<String, dynamic>;

        final temperatura = numero(actual['temperature_2m'], 20);

        final sensacion = numero(actual['apparent_temperature'], temperatura);

        final humedad = numero(actual['relative_humidity_2m'], 50);

        final presion = numero(actual['surface_pressure'], 1013);

        final viento = numero(actual['wind_speed_10m'], 0);

        final nubosidad = numero(actual['cloud_cover'], 0);

        final uv = numero(actual['uv_index'], 0);

        final codigo = numero(actual['weather_code'], 0).toInt();

        final colores = PaletaClima.obtenerColores(temperatura, codigo);

        final mensajes = <String>[];

        // CONSEJOS SEGÚN LA TEMPERATURA

        if (sensacion >= 33) {
          mensajes.add(
            'El calor intenso puede generar incomodidad '
            'y dificultar algunas actividades. '
            'Busca un lugar fresco, toma agua y descansa '
            'cuando lo necesites.',
          );

          mensajes.add(
            'Si tienes que estudiar o trabajar, '
            'procura hacerlo en un espacio ventilado. '
            'El calor excesivo puede afectar tu comodidad '
            'y concentración.',
          );
        } else if (sensacion >= 28) {
          mensajes.add(
            'El ambiente está caluroso. '
            'Si notas cansancio, realiza pequeñas pausas '
            'y mantente hidratado.',
          );

          mensajes.add(
            'Un espacio fresco y ventilado puede ayudarte '
            'a sentirte más cómodo mientras estudias '
            'o realizas tus actividades.',
          );
        } else if (sensacion <= 10) {
          mensajes.add(
            'Las temperaturas bajas pueden causar incomodidad. '
            'Abrígate y procura mantener una temperatura '
            'agradable en tu espacio.',
          );

          mensajes.add(
            'Si vas a estudiar o trabajar, '
            'prepara un lugar cálido y cómodo '
            'para evitar distracciones por el frío.',
          );
        } else if (sensacion <= 17) {
          mensajes.add(
            'El ambiente está fresco. '
            'Puedes aprovechar para realizar tus actividades '
            'en un lugar cómodo y bien iluminado.',
          );
        } else {
          mensajes.add(
            'La temperatura es moderada. '
            'Puede ser un buen momento para realizar '
            'tus actividades en un ambiente agradable.',
          );
        }

        // CONSEJOS SEGÚN LA HUMEDAD

        if (humedad >= 80 && sensacion >= 25) {
          mensajes.add(
            'La combinación de calor y humedad puede '
            'hacer que el ambiente se sienta pesado. '
            'Si notas fatiga, toma descansos '
            'y busca mejorar la ventilación.',
          );

          mensajes.add(
            'Algunas investigaciones han encontrado '
            'relaciones entre humedad elevada, somnolencia '
            'y concentración. Recuerda que no todas '
            'las personas reaccionan igual.',
          );
        } else if (humedad >= 70) {
          mensajes.add(
            'La humedad es elevada. '
            'Si el ambiente se siente incómodo, '
            'procura mantener tu espacio ventilado.',
          );
        } else if (humedad <= 30) {
          mensajes.add(
            'El ambiente tiene poca humedad. '
            'Mantente hidratado y procura sentirte '
            'cómodo durante tus actividades.',
          );
        }

        // CONSEJOS SEGÚN LA NUBOSIDAD

        if (nubosidad >= 80) {
          mensajes.add(
            'El cielo está muy nublado. '
            'La exposición a la luz natural puede '
            'relacionarse con el estado de alerta '
            'y los ritmos de sueño.',
          );

          mensajes.add(
            'Si notas somnolencia durante el día, '
            'procura estudiar o trabajar en un lugar '
            'con buena iluminación.',
          );
        } else if (nubosidad <= 20) {
          mensajes.add(
            'El cielo está despejado. '
            'Puedes aprovechar la luz natural '
            'para realizar una pausa al aire libre, '
            'siempre considerando la protección solar.',
          );
        } else {
          mensajes.add(
            'Hay nubosidad moderada. '
            'Procura mantener una buena iluminación '
            'en tu espacio de estudio o trabajo.',
          );
        }

        // CONSEJOS SEGÚN EL VIENTO

        if (viento >= 40) {
          mensajes.add(
            'El viento es fuerte. '
            'Si necesitas concentrarte en una actividad, '
            'considera permanecer en un espacio protegido.',
          );
        } else if (viento >= 25) {
          mensajes.add(
            'El viento puede modificar la sensación térmica. '
            'Procura mantenerte cómodo durante tus actividades.',
          );
        }

        // CONSEJOS SEGÚN LA PRESIÓN

        if (presion < 1005) {
          mensajes.add(
            'La presión atmosférica es relativamente baja. '
            'Aunque el clima puede relacionarse con el bienestar, '
            'este valor por sí solo no permite predecir '
            'tu estado de ánimo.',
          );
        } else if (presion > 1020) {
          mensajes.add(
            'La presión atmosférica es relativamente alta. '
            'Recuerda que el descanso, la alimentación '
            'y otros factores también influyen en cómo te sientes.',
          );
        }

        // CONSEJOS SEGÚN EL ÍNDICE UV

        if (uv >= 8) {
          mensajes.add(
            'La radiación UV es muy alta. '
            'Si deseas realizar una actividad al aire libre, '
            'busca sombra y utiliza protección solar.',
          );
        } else if (uv >= 6) {
          mensajes.add(
            'El índice UV es alto. '
            'Si planeas salir a despejarte, '
            'protege tu piel y evita la exposición prolongada.',
          );
        }

        // CONSEJOS SEGÚN LA LLUVIA

        if (codigo >= 95) {
          mensajes.add(
            'Hay condiciones de tormenta. '
            'Considera realizar actividades dentro de casa '
            'y prioriza tu seguridad.',
          );
        } else if ((codigo >= 51 && codigo <= 67) ||
            (codigo >= 80 && codigo <= 82)) {
          mensajes.add(
            'El día está lluvioso. '
            'Algunas personas encuentran la lluvia relajante '
            'y otras prefieren el sol. '
            'El clima no determina cómo te sientes.',
          );

          mensajes.add(
            'Si prefieres permanecer en casa, '
            'puedes aprovechar para leer, estudiar '
            'o realizar una actividad que disfrutes.',
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
                      Icons.psychology_rounded,
                      color: colores.colorAcento,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Clima y bienestar',
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
                'Descubre cómo las condiciones del clima '
                'pueden relacionarse con tu energía, '
                'concentración y estado de ánimo.',
                style: TextStyle(fontSize: 13, color: colores.colorTextoSuave),
              ),

              const SizedBox(height: 20),

              Text(
                'Bienestar y concentración',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colores.colorTextoOscuro,
                ),
              ),

              const SizedBox(height: 10),

              for (final mensaje in mensajes)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colores.colorTarjetaSecundaria,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colores.colorBorde),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.tips_and_updates_rounded,
                        color: colores.colorAcento,
                        size: 21,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          mensaje,
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
/*
              const SizedBox(height: 14),

              Divider(color: colores.colorBorde),

              const SizedBox(height: 12),

              Text(
                '¿Cómo te sientes hoy?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colores.colorTextoOscuro,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Selecciona la emoción que mejor '
                'describe cómo te sientes.',
                style: TextStyle(fontSize: 12, color: colores.colorTextoSuave),
              ),

              const SizedBox(height: 14),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Emocion(
                    emoji: '😊',
                    nombre: 'Feliz',
                    seleccionada: emocion == 'Feliz',
                    colores: colores,
                    alPresionar: () {
                      setState(() {
                        emocion = 'Feliz';
                      });
                    },
                  ),
                  _Emocion(
                    emoji: '😌',
                    nombre: 'Tranquilo',
                    seleccionada: emocion == 'Tranquilo',
                    colores: colores,
                    alPresionar: () {
                      setState(() {
                        emocion = 'Tranquilo';
                      });
                    },
                  ),
                  _Emocion(
                    emoji: '😴',
                    nombre: 'Cansado',
                    seleccionada: emocion == 'Cansado',
                    colores: colores,
                    alPresionar: () {
                      setState(() {
                        emocion = 'Cansado';
                      });
                    },
                  ),
                  _Emocion(
                    emoji: '😔',
                    nombre: 'Triste',
                    seleccionada: emocion == 'Triste',
                    colores: colores,
                    alPresionar: () {
                      setState(() {
                        emocion = 'Triste';
                      });
                    },
                  ),
                  _Emocion(
                    emoji: '😣',
                    nombre: 'Estresado',
                    seleccionada: emocion == 'Estresado',
                    colores: colores,
                    alPresionar: () {
                      setState(() {
                        emocion = 'Estresado';
                      });
                    },
                  ),
                ],
              ),

              if (emocion.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 15),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colores.colorTarjetaSecundaria,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colores.colorBorde),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: colores.colorAcento,
                        size: 23,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          mensajeEmocion(),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: colores.colorTextoOscuro,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 18),

              const SizedBox(height: 6),

              Text(
                'Referencia: Denissen et al. (2008), '
                'The Effects of Weather on Daily Mood.',
                style: TextStyle(fontSize: 11, color: colores.colorTextoSuave),
              ),*/
            ],
          ),
        );
      },
    );
  }
}

/*class _Emocion extends StatelessWidget {
  final String emoji;
  final String nombre;
  final bool seleccionada;
  final ColoresClima colores;
  final VoidCallback alPresionar;

  const _Emocion({
    required this.emoji,
    required this.nombre,
    required this.seleccionada,
    required this.colores,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alPresionar,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionada
              ? colores.colorFondoSecundario
              : colores.colorTarjetaSecundaria,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionada ? colores.colorAcento : colores.colorBorde,
            width: seleccionada ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 25)),
            const SizedBox(height: 5),
            Text(
              nombre,
              style: TextStyle(
                fontSize: 11,
                color: colores.colorTextoOscuro,
                fontWeight: seleccionada ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/
