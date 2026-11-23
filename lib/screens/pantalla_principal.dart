import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:app_clima/services/clima_service.dart';
import 'package:app_clima/widgets/widgets.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController ciudadController = TextEditingController();
  final ClimaService servicio = ClimaService();

  // Consulta que muestra el recuadro. Por defecto: la ubicación actual.
  late Future<Map<String, dynamic>> consulta;

  String error = '';

  @override
  void initState() {
    super.initState();
    consulta = _consultarUbicacion();
  }

  Future<Map<String, dynamic>> _consultarUbicacion() async {
    bool activada = await Geolocator.isLocationServiceEnabled();

    if (!activada) {
      throw Exception('Activa la ubicación de tu dispositivo');
    }

    LocationPermission permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      throw Exception('No autorizaste el acceso a tu ubicación');
    }

    Position posicion = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return servicio.buscarClimaCoords(posicion.latitude, posicion.longitude);
  }

  void buscarClima() {
    String ciudad = ciudadController.text.trim();

    if (ciudad.isEmpty) {
      setState(() => error = 'Escribe el nombre de una ciudad');
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

  @override
  void dispose() {
    ciudadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clima App')),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextField(
                    controller: ciudadController,
                    onSubmitted: (_) => buscarClima(),

                    decoration: InputDecoration(
                      hintText: 'Buscar ciudad',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: buscarClima,
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                IconButton(
                  onPressed: buscarPorUbicacion,
                  icon: const Icon(Icons.location_on),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TarjetaClima(consulta: consulta),
                    const SizedBox(height: 12),
                    PronosticoClima(consulta: consulta),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
