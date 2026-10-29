


import 'package:latlong2/latlong.dart';
import 'dart:convert';

class Ville {
  final int? id;
  final String exId; // id extern
  final String nom;
  final double lat;
  final double lon;
  final int lastSeen;
  final Map<String, dynamic>? details;


  Ville({required this.id, required this.exId, required this.nom, required this.lat, required this.lon, required this.lastSeen, required this.details});

  // Convertit l'objet Ville en Map pour la persistance.
  Map<String,dynamic> toMap() =>{
    'id': id,
    'ex_id' : exId,
    'nom' : nom,
    'latitude' : lat,
    'longitude' : lon,
    'lastSeen' : lastSeen,
    'details_json' : details != null ? jsonEncode(details) : null,
  };
  // // Reconstruit un objet Ville à partir d'une Map de données.
  factory Ville.fromMap(Map<String,dynamic> map){
    final String? detailsJson = map['details_json'] as String?;
    return Ville(
      id: map['id'] as int,
      exId: map['ex_id'] as String,
      nom: map['nom'] as String,
      lat: map['latitude'] as double,
      lon: map['longitude'] as double,
      lastSeen: map['lastSeen'] as int,
      details: detailsJson != null ? jsonDecode(detailsJson) as Map<String, dynamic> : null,
    );
  }
  // Crée un objet Ville à partir du résultat d'une recherche Nominatim
  factory Ville.fromNominatimJson(Map<String, dynamic> json) {
    final String display_name = json['display_name'] ?? 'Ville non trouvée';
    final double lat = double.parse(json['lat']);
    final double lon = double.parse(json['lon']);
    final int osmId = int.tryParse(json['osm_id'].toString()) ?? 0;
    final Map<String, dynamic>? addressDetails = json['address'] as Map<String, dynamic>?;
    final String nomCourt = addressDetails?['city'] ?? addressDetails?['town'] ?? json['name'] ?? json['address']?['county'] ?? json['display_name'].split(',').first;
    return Ville(
      id : null,
      exId : osmId.toString(),
      nom : nomCourt,
      lat : lat,
      lon : lon,
      lastSeen : DateTime.now().millisecondsSinceEpoch,
      details : addressDetails,
    );
  }
  // Crée un objet Ville à partir du résultat d'une recherche Nominatim reverse
  factory Ville.fromNominatimReverseJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>?;
    final nomVille = address?['city'] ?? address?['town'] ?? address?['village'] ?? json['display_name']?.split(',').first ?? 'Ville Inconnue';

    // Extraire les coordonnées
    final lat = double.parse(json['lat'].toString());
    final lon = double.parse(json['lon'].toString());

    // Créer et retourner l'objet Ville
    return Ville(
      id: null,
      exId: json['osm_id'].toString(), // Utilisation de l'ID OSM
      nom: nomVille,
      lat: lat,
      lon: lon,
      lastSeen: DateTime.now().millisecondsSinceEpoch,
      details: json, // Sauvegarder tout le JSON si nécessaire
    );
  }
  LatLng get coords => LatLng(lat, lon);
}




