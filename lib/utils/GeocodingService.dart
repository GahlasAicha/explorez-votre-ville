import 'dart:convert';

import 'package:explorez_votre_ville/models/ville.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  static const String nominatimUrl =
      'https://nominatim.openstreetmap.org/search';

  // recherche les corrdonneees pour une requette de ville retorune liste d'objets ville
  Future<List<Ville>> getCoordinates(String query) async {
    final url = Uri.parse(
      '$nominatimUrl?q=$query&format=json&addressdetails=1',
    );
    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'explorez_votre_ville'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (results.isNotEmpty) {
          return results.map((jsonItem) {
            return Ville.fromNominatimJson(jsonItem as Map<String, dynamic>);
          }).toList();
        } else {
          throw Exception('Aucun résultat trouvé pour la recherche : $query');
        }
      } else {
        throw Exception(
          'Erreur lors de la récupération des coordonnées : ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Echec de la recherche  : ${e.toString()}');
    }
  }

  // le cas le plus simple des villes ( pas plusieurs nom de ville )
  Future<LatLng?> getCoordinatesSimple(String query) async {
    try {
      final results = await getCoordinates(query);
      if (results.isNotEmpty) {
        return results[0].coords;
      }
      return null;
    } catch (e) {
      return null;

    }
  }


  Future<Ville?> getVilleFromCoordinates(LatLng coords) async {
    // L'URL nominatim est 'https://nominatim.openstreetmap.org/search'
    // Pour reverse, on doit utiliser 'https://nominatim.openstreetmap.org/reverse'
    final baseUrl = nominatimUrl.replaceAll('/search', '');
    final url = Uri.parse(
      '$baseUrl/reverse?format=json&lat=${coords.latitude}&lon=${coords.longitude}&addressdetails=1',
    );
    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'explorez_votre_ville'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);

        // Vérifie si le résultat est valide (Nominatim retourne 'error' ou 'display_name' non trouvé)
        if (result.containsKey('error')) {

          throw Exception(result['error']);
        }

        // La méthode fromNominatimReverseJson doit être implémentée dans votre modèle Ville
        return Ville.fromNominatimReverseJson(result);
      } else {
        throw Exception(
          'Erreur lors de la récupération de la ville : ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(
        'Échec de la recherche par coordonnées : ${e.toString()}',
      );
    }
  }
}
