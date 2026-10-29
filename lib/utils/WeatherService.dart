import 'dart:convert';
import '../secrets.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/Weather.dart';

class WeatherService {
  final String _apiKey = weatherApiKey;
  final String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Weather> fetchWeather(LatLng coords) async {
    final url = Uri.parse(
      '$_baseUrl?lat=${coords.latitude}&lon=${coords.longitude}&appid=$_apiKey&units=metric&lang=fr',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == null) {
        throw Exception(
          'La récupération météo a retourné un statut 200, mais le corps est vide.',
        );
      }
      print('Réponse brute de l\'API Météo : ${response.body}');
      try {
        // Tente le décodage et le cast en Map<String, dynamic>
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        return Weather.fromJson(jsonResponse);
      } catch (e) {
        // Gère les erreurs de décodage JSON ou de structure, si le JSON est mal formé
        print('Erreur de décodage JSON: $e');
        throw Exception('Erreur de format de données météo reçues.');
      }
    } else {
      print(
        'Erreur lors de la récupération de la météo : ${response.statusCode}',
      );
      print('Vorps,de reponse : ${response.body}');
      throw Exception(
        'Erreur lors de la récupération de la météo : ${response.statusCode}.Vorps,de reonse : ${response.body}',
      );
    }
  }
}
