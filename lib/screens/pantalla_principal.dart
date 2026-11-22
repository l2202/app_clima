import 'dart:io';

import 'package:flutter/material.dart';
import 'package:app_clima/services/clima_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController ciudadController = TextEditingController();
  final ClimaService servicio = ClimaService();

  String datosClima = '';

  String error = '';

  bool cargando = false;

  Future<void> buscarClima() async {
    String ciudad = ciudadController.text.trim();

    if (ciudad.isEmpty) {
      setState(() {
        error = 'Escribe el nombre de una ciudad';
        datosClima = '';
      });
      return;
    }

    setState(() {
      cargando = true;
      error = '';
      datosClima = '';
    });

    try {
      final resultado = await servicio.buscarClima(ciudad);

      final ubicacion = resultado['ubicacion'];
      final clima = resultado['clima'];

      datosClima =
          "${ubicacion['name']}, ${ubicacion['country']}\n${clima.toString()}\n";
    } on SocketException {
      setState(() {
        error = 'No tienes conexion a Internet';
      });
    } on HttpException {
      setState(() {
        error = 'Error con el servidor';
      });
    } on Exception catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Error: ', '');
      });
    } catch (e) {
      setState(() {
        error = 'Ocurrio un error, vueleve a intentarlo';
      });
    } finally {
      setState(() {
        cargando = false;
      });
    }
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
            TextField(
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

            const SizedBox(height: 20),

            if (cargando) const CircularProgressIndicator(),

            if (error.isNotEmpty)
              Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),

            if (datosClima.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    datosClima,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
