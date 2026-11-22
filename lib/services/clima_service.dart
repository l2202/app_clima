import 'dart:convert';

import 'package:http/http.dart' as http;

class ClimaService {
  
  Future<Map<String, dynamic>> buscarClima(String ciudad) async {
    final urlCiudad = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': ciudad,
    });

    final respuestaCiudad = await http
        .get(urlCiudad)
        .timeout(const Duration(seconds: 15));

    if (respuestaCiudad.statusCode != 200) {
      throw Exception('Error al buscar la ciudad');
    }

    final resultadoCiudad = jsonDecode(respuestaCiudad.body);

    if (resultadoCiudad['results'] == null ||
        resultadoCiudad['results'].isEmpty) {
      throw Exception('No se encontró la ciudad');
    }

    final ubicacion = resultadoCiudad['results'][0];

    double lat = ubicacion['latitude'];
    double long = ubicacion['longitude'];

    final urlClima = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': lat.toString(),
      'longitude': long.toString(),

      'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,surface_pressure,wind_speed_10m',

      'hourly': 'precipitation_probability',

      'daily': 'weather_code,temperature_2m_max,temperature_2m_min',

      'forecast_days': '5',

      'timezone': 'auto',
    });

    final respuestaClima = await http
        .get(urlClima)
        .timeout(const Duration(seconds: 15));

    if (respuestaClima.statusCode != 200) {
      throw Exception('Error al obtener los datos del clima');
    }

    final resultadoClima = jsonDecode(respuestaClima.body);

    print('Resultado del clima: $resultadoClima');
    return {'ubicacion': ubicacion, 'clima': resultadoClima};
  }



Future<Map<String, dynamic>> buscarClimaCoords(double lat, double long) async {

  final urlClima = Uri.https(
    'api.open-meteo.com',
    '/v1/forecast',
    {
      'latitude': lat.toString(),
      'longitude': long.toString(),
      'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,surface_pressure,wind_speed_10m',
      'hourly': 'precipitation_probability',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
      'forecast_days': '5',
      'timezone': 'auto',
    },
  );

  final respuesta = await http
      .get(urlClima)
      .timeout(const Duration(seconds: 15));

  if (respuesta.statusCode != 200) {
    throw Exception('Error al obtener los datos del clima');
  }

  final resultadoClima = jsonDecode(respuesta.body);

  return {
    'ubicacion': {
      'name': 'Mi ubicación',
      'country': 'Latitud: $lat, Longitud: $long',
    },
    'clima': resultadoClima,
  };
}

}
