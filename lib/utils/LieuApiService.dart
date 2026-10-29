// lib/utils/LieuApiService.dart

import 'dart:convert';
import '../secrets.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LieuExterne {
  final String placeId;
  final String name;
  final String category;
  final LatLng coords;
  final String address;
  final String imagePath;

  LieuExterne({
    required this.placeId,
    required this.name,
    required this.category,
    required this.coords,
    required this.address,
    this.imagePath = '',
  });
}

class LieuApiService {
  // Fonction principale pour rechercher des lieux via Google Places API
  Future<List<LieuExterne>> searchLieux({
    String? query, // Pour recherche par Nom ou Catégorie
    LatLng? location, // Pour centrer la recherche sur une ville
    String? type, // Pour affiner la recherche
  }) async {
    // Déterminez la requête à envoyer
    String finalQuery = query ?? (type ?? 'point of interest');
    if (finalQuery.isEmpty) return [];

    // URL de la nouvelle API Places
    final uri = Uri.parse('https://places.googleapis.com/v1/places:searchText');

    // Headers requis
    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': googleApiKey,
      'X-Goog-FieldMask':
          'places.id,places.displayName,places.primaryType,places.types,places.location,places.formattedAddress,places.photos',
    };

    // Construction du corps de la requête JSON
    final Map<String, dynamic> body = {
      'textQuery': finalQuery,
      'maxResultCount': 50, // Demander le maximum de résultats possible
    };

    // Ajout du biais de localisation si disponible
    if (location != null) {
      body['locationBias'] = {
        'circle': {
          'center': {
            'latitude': location.latitude,
            'longitude': location.longitude,
          },
          'radius': 10000.0, // 10km radius
        },
      };
    }

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['places'] != null) {
          return (data['places'] as List).map((result) {
            final loc = result['location'];
            final coords = LatLng(loc['latitude'], loc['longitude']);

            // Gestion de la catégorie
            String category = 'Autre';
            if (result['types'] != null &&
                (result['types'] as List).isNotEmpty) {
              // On regarde les types pour mapper
              final types = (result['types'] as List)
                  .map((e) => e.toString())
                  .toList();

              if (types.any(
                (t) => t.contains('restaurant') || t.contains('food'),
              )) {
                category = 'Restaurant';
              } else if (types.any((t) => t.contains('museum'))) {
                category = 'Musée';
              } else if (types.any(
                (t) => t.contains('park') || t.contains('nature'),
              )) {
                category = 'Nature';
              } else if (types.any(
                (t) => t.contains('bar') || t.contains('cafe'),
              )) {
                category = types.any((t) => t.contains('bar')) ? 'Bar' : 'Café';
              } else if (types.any(
                (t) => t.contains('lodging') || t.contains('hotel'),
              )) {
                category = 'Hôtel';
              } else if (types.any(
                (t) =>
                    t.contains('historical_landmark') ||
                    t.contains('tourist_attraction'),
              )) {
                category = 'Monument';
              }
            }

            // Gestion de la photo
            String imagePath = '';
            if (result['photos'] != null &&
                (result['photos'] as List).isNotEmpty) {
              final photoName = result['photos'][0]['name'];
              // Construction de l'URL de la photo
              imagePath =
                  'https://places.googleapis.com/v1/$photoName/media?key=$googleApiKey&maxHeightPx=400&maxWidthPx=400';
            }

            return LieuExterne(
              placeId: result['id'],
              name: result['displayName']['text'],
              category: category,
              coords: coords,
              address: result['formattedAddress'] ?? 'Adresse non disponible',
              imagePath: imagePath,
            );
          }).toList();
        } else {
          // Tableau vide si "places" est null
          return [];
        }
      } else {
        // Gestion des erreurs
        final data = json.decode(response.body);
        print('Erreur API Places V1: ${response.statusCode}');
        if (data['error'] != null) {
          print('Message: ${data['error']['message']}');
          print('Status: ${data['error']['status']}');
        }
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la recherche Places V1: $e');
      return [];
    }
  }
}
