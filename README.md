# app_clima

Aplicación Flutter que consulta el estado del clima a través de la API de [Open-Meteo](https://open-meteo.com/) y lo convierte en recomendaciones prácticas de **bienestar en el estudio y el trabajo**: el **Predictor de Humor y Energía por Clima**.

## Funcionalidades actuales

- Búsqueda de ciudades por nombre (Open-Meteo Geocoding API).
- Clima por ubicación actual del dispositivo (paquete `geolocator`).
- Datos actuales: temperatura, sensación térmica, humedad relativa, precipitación, presión en superficie, velocidad del viento y código de clima.
- Probabilidad de precipitación por hora.
- Pronóstico de 5 días (código de clima, temperatura máxima y mínima).

## Concepto: Predictor de Humor y Energía por Clima

> Bienestar en el Estudio / Trabajo

La app combina **presión atmosférica, temperatura, humedad y luz/nubosidad** para estimar el nivel esperado de **fatiga mental, somnolencia o claridad** a lo largo del día, y propone micro-ajustes concretos en la rutina.

**Ejemplo de recomendación:**

> "Entre 14:00 y 16:00 sube la temperatura y la humedad: riesgo de bajón de energía. Haz primero las tareas pesadas en la mañana y deja las tareas ligeras para la tarde."

### Por qué es distinto

Conecta la meteorología con el ritmo real de trabajo o estudio de una persona, en lugar de limitarse a mostrar datos del clima. Además incorpora el **índice UV** para advertir cuándo conviene salir, y cuándo usar protección solar.

### Variables consideradas

| Variable | Uso en el predictor |
| --- | --- |
| Presión atmosférica | Descensos marcados se asocian a cansancio, dolor de cabeza y menor concentración. |
| Temperatura | El calor aumenta la somnolencia y reduce el rendimiento cognitivo. |
| Humedad | Combinada con calor, intensifica la sensación de pesadez y fatiga. |
| Luz / nubosidad | Poca luz puede bajar el ánimo y la claridad mental; mucha luz favorece el estado de alerta. |
| Índice UV | Advierte sobre exposición solar y recomienda protección o evitar ciertas horas al aire libre. |

### Salidas previstas

- Franjas horarias de **alta claridad** y de **riesgo de bajón de energía**.
- Sugerencias de organización: tareas pesadas vs. ligeras según la franja.
- Alertas de **UV** con recomendación de protección (protector solar, sombra, gafas) y horas más seguras para salir.

> **Estado:** la base de datos meteorológicos ya está integrada. El cálculo del predictor, la nubosidad por hora y el índice UV están en desarrollo.

## Tecnologías

- [Flutter](https://flutter.dev/) / Dart (SDK `^3.13.1`)
- [`http`](https://pub.dev/packages/http) para las peticiones a la API
- [`geolocator`](https://pub.dev/packages/geolocator) para la ubicación del dispositivo
- [Open-Meteo](https://open-meteo.com/): Geocoding API y Forecast API (gratuita, sin clave)

## Estructura del proyecto

```
lib/
├── main.dart                         # Punto de entrada
├── screens/
│   └── pantalla_principal.dart       # Interfaz principal
└── services/
    └── clima_service.dart            # Acceso a Open-Meteo (por ciudad y por coordenadas)
```

## Ejecución

Requisitos: Flutter SDK instalado y un dispositivo o emulador (con permisos de internet y ubicación).

```bash
flutter pub get
flutter run
```

## Fuente de datos

Los datos meteorológicos son proporcionados por [Open-Meteo](https://open-meteo.com/) bajo su licencia de uso abierto.
