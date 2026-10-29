import 'package:flutter/material.dart';
import '../utils/GeolocatorService.dart';
import 'package:latlong2/latlong.dart';


class LocationProvider with ChangeNotifier {
  // Instance du service pour les appels de géolocalisatio
  final GeolocatorService _geolocatorService = GeolocatorService();

  LatLng? _currentPosition;
  bool _isLoading = false ;
  String? _errorMessage;

  LatLng? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Méthode pour récupérer la position actuelle
  Future<void> fetchCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final LatLng position = await _geolocatorService.getCurrentLocation();

      _currentPosition = position ;
    } catch (e) {
      _errorMessage = 'Erreur lors de la récupération de la géolocalisation :${e.toString()} ';
    }
    _isLoading = false;
    notifyListeners();
  }
  void clearLocation() {
    _currentPosition = null;
    _errorMessage = null;
    notifyListeners();
  }
}