import 'package:latlong2/latlong.dart';

class Weather {
  final double temperature;
  final double temperatureMin;
  final double temperatureMax;
  final double humidite;
  final double pression;
  final double vitesseVent;
  final double directionVent;
  final double pluie;
  final String description;
  final String icon;
  final int timezone;

  Weather({
    required this.temperature,
    required this.temperatureMin,
    required this.temperatureMax,
    required this.humidite,
    required this.pression,
    required this.vitesseVent,
    required this.directionVent,
    required this.pluie,
    required this.description,
    required this.icon,
    required this.timezone,
  });
  // Crée un objet Weather à partir du JSON retourné par une API météo
  factory Weather.fromJson(Map<String, dynamic> json) {
    // Les données principales sont sous la clé 'main'.
    final main = json['main'] as Map<String, dynamic>;
    // Les conditions sont souvent dans un tableau sous la clé 'weather'.
    final weatherArray = json['weather'] as List<dynamic>;
    final weather = weatherArray.isNotEmpty
        ? weatherArray[0] as Map<String, dynamic>
        : <String, dynamic>{};

    final wind = json['wind'] as Map<String, dynamic>;
    final rain = json['rain'] as Map<String, dynamic>?;
    final double pluieValue = rain != null
        ? (rain['1h'] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final double directionVentValue = (wind['deg'] as num?)?.toDouble() ?? 0.0;

    return Weather(
      temperature: (main['temp'] as num).toDouble(),
      temperatureMin: (main['temp_min'] as num).toDouble(),
      temperatureMax: (main['temp_max'] as num).toDouble(),
      humidite: (main['humidity'] as num).toDouble(),
      pression: (main['pressure'] as num).toDouble(),
      vitesseVent: (wind['speed'] as num).toDouble(),

      // Utilisation des valeurs sécurisées
      pluie: pluieValue,
      directionVent: directionVentValue,

      description: weather['description'] as String,
      icon: weather['icon'] as String,
      timezone: json['timezone'] as int? ?? 0,
    );
  }
}
