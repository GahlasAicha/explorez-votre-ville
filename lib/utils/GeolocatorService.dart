import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class GeolocatorService {
  Future<void > checkLocationPermission() async {
    // Vérifier si les services de localisation sont activés
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Les services de localisation sont désactivés.');
    }
    // Verifier l'etat  ded la permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('La permission de localisation a été refusée.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw Exception('La permission de localisation a été refusée définitivement.');
    }
    return;
  }
  Future<LatLng> getCurrentLocation() async {
    await checkLocationPermission();
    try {
      Position position = await Geolocator.getCurrentPosition(
        // desiredAccuracy: LocationAccuracy.high,
        // timeLimit: const Duration(seconds: 10),
      );
      return LatLng(position.latitude, position.longitude);
    }on TimeoutException{
      throw Exception('Temps limite de récupération de la position dépassé.');
    }catch (e) {
      throw Exception('Erreur lors de la récupération de la position : $e');
    }
  }


}