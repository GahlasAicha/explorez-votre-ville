import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import '../models/lieu.dart';
import '../models/ville.dart';
import '../utils/GeocodingService.dart';
import '../db/dbHelper.dart';
import '../utils/WeatherService.dart';
import '../models/Weather.dart';
import '../utils/LieuApiService.dart'; // API pour trouver des lieux d'intérêt ( Google Places)

// --- Constantes SharedPreferences ---
const String _kvilleActuelle = 'villeActuelle';
const String _kfavoriteCities = 'favoriteCities';
const String _kCurrentLat = 'currentLat';
const String _kCurrentLon = 'currentLon';


class LieuProvider with ChangeNotifier {
  // --- Services & Helpers ---
  final DBHelper _dbHelper = DBHelper();
  final GeocodingService _geocodingService = GeocodingService();
  final WeatherService _weatherService = WeatherService();
  final LieuApiService _lieuApiService = LieuApiService();

  List<Lieu> _lieux = [];
  String? _villeActuelle;
  List<String> _favoriteCities = [];

  LatLng? _villecentreeCoords;
  List<Ville> villesTrouves = []; // liste des villes trouvées
  String? _errorMessage;
  int? _villeActuelleId; // id interne de la ville actuelle

  Weather? _weather;
  bool _isWeatherLoading = false;
  bool _isSearching = false; // Nouvelle variable d'état
  String? _selectedCategory;
  String _searchLieuQuery = ''; // Requête de recherche locale de lieu



  // getters pour les données
  String? get villeActuelle => _villeActuelle;
  List<String> get favoriteCities => _favoriteCities;
  LatLng? get villecentreeCoords => _villecentreeCoords;
  List<Ville> get villesTrouvees => villesTrouves;
  String? get errorMessage => _errorMessage;
  Weather? get weather => _weather;
  bool get isWeatherLoading => _isWeatherLoading;
  bool get isSearching => _isSearching;
  String? get selectedCategory => _selectedCategory;
  int? get villeActuelleId => _villeActuelleId;
  String get searchLieuQuery =>
      _searchLieuQuery;

  // Vérifie si une ville est dans les favoris
  bool isVilleFavori(String ville) {
    return _favoriteCities.contains(ville);
  }
  // --- Initialisation du Provider ---
  LieuProvider() {
    _loadData();
  }
  // methode qui charge les données du provider
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    //  Chargement des listes de favoris
    _favoriteCities = prefs.getStringList(_kfavoriteCities) ?? [];
    //  DÉTERMINATION DE LA VILLE ACTUELLE
    String? villeCandidate = prefs.getString(_kvilleActuelle);
    if (villeCandidate == null && _favoriteCities.isNotEmpty) {
      //  Si aucune ville n'est sauvegardée, prendre le premier favori.
      villeCandidate = _favoriteCities.first;
    }
    _villeActuelle = villeCandidate;
    if (_villeActuelle == null) {
      notifyListeners();
      return;
    }
    // DÉTERMINATION DES COORDONNÉES
    LatLng? coordsToUse;
    //  Tenter de charger les COORDONNÉES sauvegardées de la ville ACTUELLE
    final double? savedLat = prefs.getDouble(_kCurrentLat);
    final double? savedLon = prefs.getDouble(_kCurrentLon);
    if (savedLat != null && savedLon != null) {
      // Si les coordonnées sont en cache, on les utilise
      coordsToUse = LatLng(savedLat, savedLon);
    }
    //  Si les coordonnées ne sont pas en cache, les récupérer via Géocodage
    if (coordsToUse == null) {
      final LatLng? fetchedCoords = await _geocodingService
          .getCoordinatesSimple(_villeActuelle!);
      if (fetchedCoords != null) {
        coordsToUse = fetchedCoords;
        await prefs.setDouble(_kCurrentLat, fetchedCoords.latitude);
        await prefs.setDouble(_kCurrentLon, fetchedCoords.longitude);
      }
    }
    //Finalisation de l'état
    _villecentreeCoords = coordsToUse;
    //  Mise à jour de la liste de favoris si nécessaire (seulement si "Orléans" a été ajoutée)
    if (!_favoriteCities.contains(_villeActuelle!)) {
      _favoriteCities.add(_villeActuelle!);
      await prefs.setStringList(_kfavoriteCities, _favoriteCities);
    }
    //  Chargement des lieux et météo
    await _fetchLieuxFromDB();
    if (_villecentreeCoords != null) {
      await _fetchWeather();
    }
    notifyListeners();
  }
  // Récupère les lieux pour la ville actuelle
  Future<void> _fetchLieuxFromDB({bool forceRefresh = false}) async {
    if (_villeActuelle == null || _villeActuelleId == null) {
      _lieux = [];
      notifyListeners();
      return;
    }
    final int currentVilleId = _villeActuelleId!;
    try {
      // On charge d'abord ce qu'on a en local
      List<Lieu> lieuxLocaux = await _dbHelper.getLieuxByVilleId(
        currentVilleId,
      );
      _lieux = lieuxLocaux;

      // FETCH API (Si la liste locale est vide OU si un rafraîchissement est demandé)
      if ((this._lieux.isEmpty || forceRefresh) &&
          _villecentreeCoords != null) {
        print(
          forceRefresh
              ? 'Rafraîchissement forcé via Google Places API...'
              : 'Aucun lieu local. Recherche via Google Places API...',
        );
        List<LieuExterne> lieuxAPI = [];
        // Liste des requêtes pour couvrir plus de catégories
        final queries = [
          'tourist attractions in $_villeActuelle',
          'restaurants in $_villeActuelle',
          'parks in $_villeActuelle',
          'cafes in $_villeActuelle',
          'bars in $_villeActuelle',
          'hotels in $_villeActuelle',
          'museums in $_villeActuelle',
          'shopping in $_villeActuelle',
        ];

        try {
          // On boucle sur les différentes catégories pour enrichir la base
          for (final query in queries) {
            print('Recherche Google Places pour: $query');
            final results = await _lieuApiService.searchLieux(
              location: _villecentreeCoords!,
              query: query,
            );
            lieuxAPI.addAll(results);
          }
        } catch (e) {
          print("Erreur Google Places API: $e");
          _errorMessage = "Erreur de connexion Google Places";
        }

        // INSERTION ET MISE A JOUR
        if (lieuxAPI.isNotEmpty) {
          int addedCount = 0;
          for (var lieuExterne in lieuxAPI) {
            // Vérification doublon simple par nom
            bool exists = this._lieux.any((l) => l.title == lieuExterne.name);
            if (!exists) {
              final nouveauLieu = Lieu(
                id: 0,
                title: lieuExterne.name,
                description:
                    'Lieu trouvé via Google Places. Catégorie: ${lieuExterne.category}',
                latitude: lieuExterne.coords.latitude,
                longitude: lieuExterne.coords.longitude,
                categorie: lieuExterne.category,
                rating: 4,
                isFavorite: false,
                imagePath: lieuExterne.imagePath,
                villeId: currentVilleId,
                address: lieuExterne.address,
              );

              final newId = await _dbHelper.insertLieu(nouveauLieu);
              this._lieux.add(nouveauLieu.copyWith(id: newId));
              addedCount++;
            }
          }
          print('$addedCount nouveaux lieux Google Places ajoutés.');
          if (forceRefresh && addedCount == 0 && lieuxAPI.isNotEmpty) {
            print('Aucun nouveau lieu : ils existent déjà tous.');
          }
        } else if (forceRefresh) {
          _errorMessage = "Aucun résultat trouvé via Google Places.";
        }
      }
    } catch (e) {
      print('Erreur fatale lors de _fetchLieuxFromDB : $e');
      _errorMessage = "Erreur lors du chargement des lieux.";
    } finally {
      notifyListeners();
    }
  }

  // Méthode publique pour forcer le rafraîchissement
  Future<void> refreshLieux() async {
    _isSearching = true; // Pour afficher le loader si utilisé dans l'UI
    notifyListeners();
    await _fetchLieuxFromDB(forceRefresh: true);
    _isSearching = false;
    notifyListeners();
  }

  // Méthode pour ajouter un lieu
  Future<void> addLieu(Lieu lieu) async {
    final newId = await _dbHelper.insertLieu(lieu);
    final newLieu = lieu.copyWith(id: newId);
    _lieux.add(newLieu);
    notifyListeners();
  }

  // Méthode pour mettre à jour un lieu
  Future<void> updateLieu(Lieu lieumisajour) async {
    await _dbHelper.updateLieu(lieumisajour);
    final index = _lieux.indexWhere((lieu) => lieu.id == lieumisajour.id);
    if (index >= 0) {
      _lieux[index] = lieumisajour;
      notifyListeners();
    }
  }

  // Méthode pour supprimer un lieu
  Future<void> deleteLieu(int id) async {
    _dbHelper.deleteLieu(id);
    _lieux.removeWhere((lieu) => lieu.id == id);
    notifyListeners();
  }

  // methode pour mettre un lieu en favori
  Future<void> toggleLieuFavorite(int id) async {
    final lieu = _lieux.firstWhere((l) => l.id == id);
    final lieumisajour = lieu.copyWith(isFavorite: !lieu.isFavorite);
    await _dbHelper.updateLieu(lieumisajour);

    final index = _lieux.indexWhere((l) => l.id == id);
    if (index >= 0) {
      _lieux[index] = lieumisajour;
      notifyListeners();
    }
  }
  // méthode pour chercher une ville
  Future<void> chercherVille(String query) async {
    print('DEBUG: chercherVille called with query: "$query"');
    if (query.trim().isEmpty) {
      _errorMessage = 'Veuillez saisir une ville';
      villesTrouves = [];
      notifyListeners();
      return;
    }
    _errorMessage = null;
    villesTrouves = [];
    _errorMessage = null;
    villesTrouves = [];
    _isSearching = true; // Début chargement
    notifyListeners();
    try {
      // recuperation des villes via le servicede geocod  ge
      villesTrouves = await _geocodingService.getCoordinates(query);
      if (villesTrouves.isEmpty) {
        _errorMessage = 'Aucun résultat trouvé pour la recherche : $query';
        notifyListeners();
        return;
      }
      if (villesTrouves.length == 1) {
        await saveSelectedVille(villesTrouves.first);
        villesTrouves = [];
      }
      // Si > 1, la liste des résultats reste affichée pour que l'utilisateur choisisse
    } catch (e) {
      // Gère l'exception levée par GeocodingService
      _errorMessage = 'Erreur: ${e.toString().split(':')[1].trim()}';
      villesTrouves = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }
  // méthode pour chercher une ville par ses coordonnées
  Future<void> chercherVilleParCoords(double latitude, double longitude) async {
    _errorMessage = null;
    villesTrouves = [];
    _isSearching = true;
    notifyListeners();
    try {
      //recuperl'objt ville a partir des coordonnées
      final Ville? selectedVille = await _geocodingService
          .getVilleFromCoordinates(LatLng(latitude, longitude));

      if (selectedVille != null) {
        //sauvegarder la ville dans la db
        await saveSelectedVille(selectedVille);
      } else {
        _errorMessage = 'Aucune ville trouvée à cette position.';
      }
    } catch (e) {
      print('Création manuelle de la ville suite à erreur API : $e');
      final fallbackVille = Ville(
        id: null,
        exId: 'gps_${latitude}_$longitude',
        nom: 'Ma Position',
        lat: latitude,
        lon: longitude,
        lastSeen: DateTime.now().millisecondsSinceEpoch,
        details: {},
      );

      await saveSelectedVille(fallbackVille);

      _errorMessage = null;
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }
  // methode pour inser une ville dans la db ou reperer son id si elle existe
  Future<int?> VilleisinDB(Ville selectedVille) async {
    Ville? villeExistante = await _dbHelper.getVilleByExId(selectedVille.exId);
    if (villeExistante != null) {
      return villeExistante.id;
    } else {
      final newId = await _dbHelper.insertVille(selectedVille);
      return newId;
    }
  }
  // Méthode pour sauvegarder la ville actuelle et mettre a jour l'etat
  Future<void> saveSelectedVille(Ville selectedVille) async {
    print('DEBUG: _saveSelectedVille called with: ${selectedVille.nom}');
    //gere la base de données
    final villeId = await VilleisinDB(selectedVille);
    _villeActuelleId = villeId;
    //on met a jour l'etat
    _villeActuelle = selectedVille.nom;
    _villecentreeCoords = selectedVille.coords;
    villesTrouves = [];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kvilleActuelle, _villeActuelle!);

    if (!_favoriteCities.contains(_villeActuelle)) {
      _favoriteCities.add(_villeActuelle!);
      await prefs.setStringList(_kfavoriteCities, _favoriteCities);
    }
    await _fetchWeather();
    await _fetchLieuxFromDB();


  }
  // Méthode pour ajouter ou supprimer une ville favorite
  Future<void> toggleFavoriteCity(String ville) async {
    ville = ville.trim();
    if (_favoriteCities.contains(ville)) {
      _favoriteCities.remove(ville);
    } else {
      _favoriteCities.add(ville);
    }
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(_kfavoriteCities, _favoriteCities);
  }


  // Méthode pour récupérer la météo
  Future<void> _fetchWeather() async {
    if (_villecentreeCoords == null) {
      return;
    }
    print('Tentative de récupération météo pour: ${_villecentreeCoords!.latitude}',);
    _isWeatherLoading = true;
    _weather = null;
    try {
      //
      final weather = await _weatherService.fetchWeather(_villecentreeCoords!);
      // on récupère la météo par rappport aux coordonnées de la ville
      print('Récupération météo réussie : $weather');
      _weather = weather;
      _errorMessage = null;
    } catch (e) {
      print('Erreur lors de la récupération de la météo : $e');
      _errorMessage = 'Erreur lors de la récupération de la météo : $e';
      _weather = null;
    } finally {
      _isWeatherLoading = false;
      notifyListeners();
    }
  }
  // Méthode pour mettre à jour la catégorie sélectionnée
  void setCategory(String? category) {
    if (category == null || category == 'Tout') {
      _selectedCategory = null;
    } else if (_selectedCategory == category) {
      _selectedCategory = null;
    } else {
      _selectedCategory = category;
    }
    notifyListeners();
  }

  // Methode pour mettre à jour la requête de recherche de lieu
  void setPlaceSearchQuery(String query) {
    _searchLieuQuery = query;
    notifyListeners();
  }
  // Méthode pour obtenir la liste des lieux filtrée
  List<Lieu> get lieux {
    List<Lieu> ListFiltree;
    // onn filtre par categorie
    if (_selectedCategory == null || _selectedCategory == 'Tout') {
      ListFiltree = [..._lieux];
    } else {
      ListFiltree = _lieux
          .where((lieu) => lieu.categorie == _selectedCategory)
          .toList();
    }
    // on filtre par nom
    if (_searchLieuQuery.trim().isNotEmpty) {
      final queryLower = _searchLieuQuery.toLowerCase().trim();
      ListFiltree = ListFiltree.where((lieu) {
        return lieu.title.toLowerCase().contains(queryLower);
      }).toList();
    }
    // on trie les lieux par les favoris en premier
    ListFiltree.sort((a, b) {
      final int bInt = b.isFavorite ? 1 : 0;
      final int aInt = a.isFavorite ? 1 : 0;
      final favoriteComparison = bInt.compareTo(aInt);

      if (favoriteComparison != 0) {
        return favoriteComparison; // Retourne -1 (a avant b) ou 1 (b avant a)
      }
      //si les deux sont favoris ou les deux ne le sont pas, on trie par titre
      return a.title.compareTo(b.title);
    });

    return ListFiltree;
  }
 // Méthode pour calculer la moyenne des notes et mettre à jour le lieu
  Future<void> calculerMoyenneNotes(int lieuId, List<int> ratings) async {
    if (ratings.isEmpty) return;
    // Calcul de la moyenne arithmétique et arrondi à l'entier
    double sum = 0;
    for (var r in ratings) {
      sum += r;
    }
    final moyenne = (sum / ratings.length).round();
    // Mise à jour du lieu avec la nouvelle moyenne
    final index = _lieux.indexWhere((l) => l.id == lieuId);
    if (index != -1) {
      final updatedLieu = _lieux[index].copyWith(rating: moyenne);
      _lieux[index] = updatedLieu;
      notifyListeners();

      await _dbHelper.updateLieu(updatedLieu);
    }
  }

  // Méthode de réinitialisation complète de l'application
  Future<void> resetAppData() async {
    await _dbHelper.clearDatabase();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Réinitialiser les préférences
    //  Réinitialiser l'état local
    _villeActuelle = null;
    _villeActuelleId = null;
    _lieux = [];
    _favoriteCities = [];
    _villecentreeCoords = null;
    villesTrouves = [];
    _errorMessage = null;
    _weather = null;
    _isSearching = false;
    _searchLieuQuery = '';

    notifyListeners();
  }

  void clearSearchResults() {
    villesTrouves = [];
    _errorMessage = null;
    notifyListeners();
  }
}
