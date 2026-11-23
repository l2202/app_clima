import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app_clima/services/clima_service.dart';
import 'package:app_clima/widgets/widgets.dart';
import 'package:app_clima/theme/tema.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController ciudadController = TextEditingController();

  final ClimaService servicio = ClimaService();

  late Future<Map<String, dynamic>> consulta;

  String error = '';

  @override
  void initState() {
    super.initState();
    consulta = _consultarUbicacion();
  }

  Future<Map<String, dynamic>> _consultarUbicacion() async {
    try {
      bool servicioActivo = await Geolocator.isLocationServiceEnabled();

      if (!servicioActivo) {
        throw Exception('Activa la ubicación de tu dispositivo');
      }

      LocationPermission permiso = await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        throw Exception('No se permitió el acceso a la ubicación');
      }

      Position posicion = await Geolocator.getCurrentPosition();

      return await servicio.buscarClimaCoords(
        posicion.latitude,
        posicion.longitude,
      );
    } catch (e) {
      throw Exception('No se pudo obtener el clima: $e');
    }
  }

  void buscarClima() {
    String ciudad = ciudadController.text.trim();

    if (ciudad.isEmpty) {
      setState(() {
        error = 'Escribe el nombre de una ciudad';
      });
      return;
    }

    setState(() {
      error = '';
      consulta = servicio.buscarClima(ciudad);
    });
  }

  void buscarPorUbicacion() {
    setState(() {
      error = '';
      consulta = _consultarUbicacion();
    });
  }

  ColoresClima obtenerPaleta(Map<String, dynamic> datos) {
    // Ajusta estas claves si tu servicio utiliza otros nombres.
    double temperatura = 20;
    int codigoClima = 0;

    if (datos['temperatura'] != null) {
      temperatura = (datos['temperatura'] as num).toDouble();
    } else if (datos['current']?['temperature_2m'] != null) {
      temperatura = (datos['current']['temperature_2m'] as num).toDouble();
    }

    if (datos['codigoClima'] != null) {
      codigoClima = (datos['codigoClima'] as num).toInt();
    } else if (datos['current']?['weather_code'] != null) {
      codigoClima = (datos['current']['weather_code'] as num).toInt();
    }

    return PaletaClima.obtenerColores(temperatura, codigoClima);
  }

  @override
  void dispose() {
    ciudadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: consulta,
      builder: (context, snapshot) {
        ColoresClima colores = PaletaClima.inicialGrisAzul;

        if (snapshot.hasData) {
          colores = obtenerPaleta(snapshot.data!);
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            width: double.infinity,
            color: Colors.white,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clima de hoy',
                                style: TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.bold,
                                  color: colores.colorTextoOscuro,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Consulta el clima de tu ciudad',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colores.colorTextoSuave,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: colores.colorBorde),
                          ),
                          child: IconButton(
                            onPressed: buscarPorUbicacion,
                            icon: Icon(
                              Icons.my_location,
                              color: colores.colorAcento,
                            ),
                            tooltip: 'Usar mi ubicación',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Buscador
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ciudadController,
                            onSubmitted: (_) => buscarClima(),
                            decoration: InputDecoration(
                              hintText: 'Buscar ciudad...',
                              hintStyle: TextStyle(
                                color: colores.colorTextoSuave,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: colores.colorAcento,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: colores.colorBorde,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: colores.colorBorde,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: colores.colorAcento,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Container(
                          decoration: BoxDecoration(
                            color: colores.colorAcento,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            onPressed: buscarClima,
                            icon: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        error,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],

                    const SizedBox(height: 22),

                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(35),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (snapshot.hasError)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: 45,
                              color: colores.colorAcento,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No se pudo consultar el clima',
                              style: TextStyle(
                                color: colores.colorTextoOscuro,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Intenta buscar otra ciudad o revisar tu ubicación.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colores.colorTextoSuave),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: buscarPorUbicacion,
                              child: const Text('Intentar nuevamente'),
                            ),
                          ],
                        ),
                      )
                    else if (snapshot.hasData) ...[
                      TarjetaClima(consulta: consulta),

                      const SizedBox(height: 20),

                      RecomendacionesClima(consulta: consulta),

                      const SizedBox(height: 20),

                      PronosticoClima(consulta: consulta),
                      const SizedBox(height: 20),
                      BienestarClima(consulta: consulta),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
