import 'package:explorez_votre_ville/providers/LocationProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../models/lieu.dart';
import '../providers/LieuProvider.dart';
import '../providers/ThemeProvider.dart';
import '../widgets/WeatherInfoCard.dart' as weather;
import '../utils/icon_mapping.dart';
import '../widgets/FavoriteCitiesDrawer.dart';
import '../widgets/BareeCategory.dart';
import '../widgets/ListLieuxVue.dart';
import '../screens/ajout_modif_lieu_screen.dart';

class Principalescreen extends StatefulWidget {
  const Principalescreen({super.key});
  @override
  State<Principalescreen> createState() => _PrincipalescreenState();
}

class _PrincipalescreenState extends State<Principalescreen>
    with SingleTickerProviderStateMixin {
  bool _isShowingResults = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _placeSearchController = TextEditingController();
  final MapController _mapController = MapController();
  final FocusNode _searchFocusNode = FocusNode();

  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  final LatLng _defaultLocation = const LatLng(47.9032335, 1.9085203);
  final double _defaultZoom = 12.0;

  //List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    // animation courver elastique
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
    _fabController.forward();
    //execution de position actuel une fois apres le lencement de build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    _searchController.dispose();
    _placeSearchController.dispose();
    _mapController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lieuProvider = Provider.of<LieuProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // c dans le cas ou y'a beaucoup de villes au meme nom
    if (lieuProvider.villesTrouves.length > 1 && !_isShowingResults) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSearchResults(context, lieuProvider);
      });
    }


    final villeActuelle = lieuProvider.villeActuelle;
    if (villeActuelle == null) {
      return _buildOnboarding(
        context,
        _searchController,
        lieuProvider,
        themeProvider,
      );
    }

    final List<Lieu> LieuxVille = lieuProvider.lieux;
    final LatLng? currentPosition = locationProvider.currentPosition;
    final bool isLoading = locationProvider.isLoading;

    // // Sync local controller with provider state if needed (optional)
    // if (_placeSearchController.text != lieuProvider.searchLieuQuery) {
    //   // Only if we want bidirectional sync, but here onChanged drives provider.
    //   // However, if we clear provider, we might want to clear text.
    //   // For now let's rely on user input.
    // }

    LatLng center;
    if (currentPosition != null) {
      center = currentPosition;
    } else if (lieuProvider.villecentreeCoords != null) {
      center = lieuProvider.villecentreeCoords!;
    } else if (LieuxVille.isNotEmpty) {
      center = LatLng(LieuxVille.first.latitude, LieuxVille.first.longitude);
    } else {
      center = _defaultLocation;
    }

    // les icons des lieu
    List<Marker> lieuxMarkers = LieuxVille.map((lieu) {
      return Marker(
        width: 45.0,
        height: 45.0,
        point: LatLng(lieu.latitude, lieu.longitude),
        child: GestureDetector(
          onTap: () => _navigateToLieuDetails(lieu),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            // recuperer icone de categorie
            child: Icon(
              getCategoryIcon(lieu.categorie),
              color: Theme.of(context).primaryColor,
              size: 28.0,
            ),
          ),
        ),
      );
    }).toList();

    // markeur position actuel
    List<Marker> userMarker = [];
    if (currentPosition != null) {
      userMarker.add(
        Marker(
          point: currentPosition,
          child: const Icon(Icons.location_pin, color: Colors.red, size: 40.0),
        ),
      );
    }
    List<Marker> allMarkers = [...lieuxMarkers, ...userMarker];

    // Si la ville a changé (via favoris ou autre) et que l'utilisateur n'est pas en train d'écrire
    if (villeActuelle != null &&
        _searchController.text != villeActuelle &&
        !_searchFocusNode.hasFocus) {
      _searchController.value = _searchController.value.copyWith(
        text: villeActuelle,
        selection: TextSelection.collapsed(offset: villeActuelle.length),
      );
    }

    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    const Color primaryGradientStart = ThemeProvider.accentOrange;

    const Color primaryGradientEnd = ThemeProvider.accentTurquoise;


    // Déplacer la caméra si la ville change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.move(center, _defaultZoom);
      } catch (e) {
        // Ignorer si le map controller n'est pas encore prêt
      }
    });


    // la page
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Explorez votre ville :  $villeActuelle ',
          style: TextStyle(color: onPrimaryColor),
        ),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: onPrimaryColor),
        actions: [
          // bouton icon de ville favoris
          IconButton(
            icon: Icon(
              lieuProvider.isVilleFavori(villeActuelle)
                  ? Icons.star
                  : Icons.star_border,
              color: onPrimaryColor,
            ),
            onPressed: () =>
                _toggleSearchCityFavorite(lieuProvider, villeActuelle),
            tooltip: lieuProvider.isVilleFavori(villeActuelle)
                ? 'Retirer des favoris'
                : 'Ajouter aux favoris',
          ),
          // actualiser les lieu dans la ville
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser les lieux (Google Places)',
            onPressed: () {
              // Appel au refresh du provider
              lieuProvider.refreshLieux();
              // message informent
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recherche de nouveaux lieux...')),
              );
            },
          ),

          // icon pour changer le theme de l'application
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nights_stay,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Changer le thème',
          ),
        ],
      ),

      // menu latéral pour le ville en favoris
      drawer: FavoriteCitiesDrawer(
        onCityToggle: (ville) => _toggleSearchCityFavorite(lieuProvider, ville),
      ),


      // bouton pour ajouter lieu
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation, // l'animation pour le bouton
        child: FloatingActionButton(
          tooltip: 'Ajouter un lieu',
          onPressed: () => _navigateToAjoutModification(context, villeActuelle),
          backgroundColor: secondaryColor,
          child: Icon(Icons.add_location, color: onPrimaryColor),
        ),
      ),
      body: ListView(
        children: [
          // champ de saisie pour rechercher une ville
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                labelText: 'Rechercher une ville ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city, color: primaryColor),
                suffixIcon: isLoading || lieuProvider.isSearching
                    ? const Padding( // est en train de chercher ou bouton de localisation
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                )
                    : IconButton(
                  icon: Icon(Icons.my_location, color: primaryColor),

                  onPressed: () {
                    _getCurrentLocation();
                  },
                ),
              ),

              onSubmitted: (query) async {
                if (query.isNotEmpty && query != villeActuelle) {
                  // On désactive le mode "Suivi GPS" pour que la carte puisse bouger
                  Provider.of<LocationProvider>(
                    context,
                    listen: false,
                  ).clearLocation();

                  await lieuProvider.chercherVille(query);

                  // si BuildContext n'est pas dans l'arborescence des widgets alors retourner!
                  if (!context.mounted) return;
                  // si erreur dans lieuProvider
                  if (lieuProvider.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(lieuProvider.errorMessage!)),
                    );
                  } else if (lieuProvider.villeActuelle != null &&
                      _searchController.text != lieuProvider.villeActuelle) {
                    // remplacer avec lieu actuelle
                    final newVille = lieuProvider.villeActuelle!;
                    _searchController.value = _searchController.value.copyWith(
                      text: newVille,
                      // placer le curseur a la fin de nom
                      selection: TextSelection.collapsed(
                        offset: newVille.length,
                      ),
                    );
                  }
                  // retirer focus clavier
                  FocusScope.of(context).unfocus();
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryGradientStart, primaryGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),

            // partie affichage météo
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ville : $villeActuelle',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                weather.buildWeatherInfo(context, lieuProvider, villeActuelle),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // carte
          SizedBox(
            height: 350,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(

                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: _defaultZoom,
                      minZoom: 3,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'explorez_votre_ville',
                      ),
                      MarkerLayer(markers: allMarkers),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Place Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _placeSearchController,
              decoration: InputDecoration(
                hintText: 'Filtrer les lieux (ex: Louvre...)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _placeSearchController.text.isNotEmpty
                    ? IconButton(
                  // pour enlver les recherches
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _placeSearchController.clear();
                    lieuProvider.setPlaceSearchQuery('');

                    setState(() {});
                  },
                )
                    : null,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              onChanged: (value) {
                lieuProvider.setPlaceSearchQuery(value);
                setState(() {}); // update suffix icon
              },
            ),
          ),
          const BareeCategory(),

          const ListLieuxVue(),
        ],
      ),
    );
  }



  // fonction pour recuperer la position de l'utilisateur
  Future<void> _getCurrentLocation() async {
    // print('DEBUG: _getCurrentLocation STARTED');
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    final lieuProvider = Provider.of<LieuProvider>(context, listen: false);

    final isInitial =
        lieuProvider.villeActuelle == null ||
            lieuProvider.villeActuelle == 'chargement... ';

    await locationProvider.fetchCurrentLocation();

    // print(
    //   'DEBUG: LocationProvider fetched. Position: ${locationProvider.currentPosition}',
    // );

    if (locationProvider.currentPosition != null) {
      final position = locationProvider.currentPosition!;
      _searchController.clear();

      // verification de build dans l'arbre
      if (mounted) {
        // print(
        //   'DEBUG: Calling chercherVilleParCoords with ${position.latitude}, ${position.longitude}',
        // );
        await lieuProvider.chercherVilleParCoords(
          position.latitude,
          position.longitude,
        );
        // print(
        //   'DEBUG: chercherVilleParCoords FINISHED. VilleActuelle: ${lieuProvider.villeActuelle}',
        // );

        if (!mounted) return; // sinon on ne fait rien

        if (lieuProvider.errorMessage != null) {
          // print('DEBUG: Error found: ${lieuProvider.errorMessage}');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(lieuProvider.errorMessage!)));// message erreur
        } else if (lieuProvider.villeActuelle != null) {
          // print('DEBUG: Success. Updating text field.');
          final newVille = lieuProvider.villeActuelle!;
          _searchController.value = _searchController.value.copyWith(
            text: newVille,
            selection: TextSelection.collapsed(offset: newVille.length),
          );
          // rebuild de UI
          setState(() {});
        }
      }
    } else {
      // print('DEBUG: Position is NULL');
      if (isInitial) {
        // await lieuProvider.chercherVille('Orléans');
      } else {
        if (locationProvider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(locationProvider.errorMessage!)),
          );
        }
      }
    }
  }

  void _showSearchResults(BuildContext context, LieuProvider lieuProvider) {
    if (_isShowingResults) return;
    setState(() {
      _isShowingResults = true;
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selectionner une ville'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: lieuProvider.villesTrouves.length,
              itemBuilder: (BuildContext context, int index) {
                final ville = lieuProvider.villesTrouves[index];
                final String detail =
                    ville.details?['country'] ??
                        ville.details?['display_name']?.split(',').last.trim() ??
                        '';

                return ListTile(
                  leading: const Icon(Icons.location_city),
                  title: Text('${ville.nom} ($detail)'),
                  onTap: () {
                    lieuProvider.saveSelectedVille(ville);
                    lieuProvider.clearSearchResults();
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                // Annule la sélection et vide la liste de résultats
                lieuProvider.clearSearchResults();
                Navigator.of(context).pop();
                _isShowingResults = false;
              },
            ),
          ],
        );
      },
    ).then((_) {
      setState(() {
        _isShowingResults = false;
      });
    });
  }

  // Navigation vers la page d'ajout ou de modification d'un lieu
  void _navigateToAjoutModification(
      BuildContext context,
      String villeActuelle,
      ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: const SizedBox(
            height: 600,
            width: double.maxFinite,
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(20.0)),
              child: AjoutModifLieuScreen(isDialog: true),
            ),
          ),
        );
      },
    ).then((_) {
      // Refresh, as saving happens inside the dialog
      Provider.of<LieuProvider>(context, listen: false).refreshLieux();
    });
  }

  void _navigateToLieuDetails(Lieu lieu) {
    _showLieuDetails(context, lieu);
  }

  void _showLieuDetails(BuildContext context, Lieu lieu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  // touche
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        // image de lieu dans ScrollableSheet
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child:
                          (lieu.imagePath != null &&
                              lieu.imagePath!.startsWith('http'))
                              ? Image.network(
                            lieu.imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              getCategoryIcon(lieu.categorie),
                              size: 35,
                              color: Theme.of(context).primaryColor,
                            ),
                          )
                              : Icon(
                            getCategoryIcon(lieu.categorie),
                            size: 35,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // nom de lieu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lieu.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            // categorie
                            Text(
                              lieu.categorie.toUpperCase(),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                letterSpacing: 1.0,
                              ),
                            ),

                            // address de lieu
                            if (lieu.address.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      lieu.address,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // modification de lieu icon
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/ajouterModifierLieu',
                            arguments: lieu,
                          );
                        },
                      ),

                      // icon lieu favorie
                      IconButton(
                        icon: Icon(
                          lieu.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: lieu.isFavorite
                              ? Colors.redAccent
                              : Colors.grey,
                          size: 30,
                        ),
                        onPressed: () {
                          Provider.of<LieuProvider>(
                            context,
                            listen: false,
                          ).toggleLieuFavorite(lieu.id);
                          Navigator.pop(context,);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  // peutit detail
                  const Text(
                    "Détails",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lieu.description,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[300]
                          : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Fermer le modal et naviguer vers les détails
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/lieudetails',
                          arguments: lieu,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(Icons.info_outline),
                      label: const Text(
                        "Voir plus de détails",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }



  // fonction pour ajouter ou supprimer une ville favorite
  void _toggleSearchCityFavorite(LieuProvider lieuProvider, String ville) {
    if (ville.isEmpty) return;
    lieuProvider.toggleFavoriteCity(ville);
    final isFavorite = lieuProvider.isVilleFavori(ville);
    //final city = isFavorite ? 'Ajouter' : 'Supprimer';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite
              ? 'La ville $ville a été ajoutée aux villes favorites.'
              : 'La ville $ville a été supprimée des villes favorites.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }


  // page principal sans Data Base
  Widget _buildOnboarding(
      BuildContext context,
      TextEditingController controller,
      LieuProvider lieuProvider,
      ThemeProvider themeProvider,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenue !'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nights_stay,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_city,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 20),
              const Text(
                'Aucune ville sélectionnée',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pour commencer, veuillez rechercher une ville ou utiliser votre position.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              if (lieuProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    lieuProvider.errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Rechercher une ville...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: () => _getCurrentLocation(),
                  ),
                ),
                onSubmitted: (query) async {
                  if (query.isNotEmpty) {
                    Provider.of<LocationProvider>(
                      context,
                      listen: false,
                    ).clearLocation();
                    await lieuProvider.chercherVille(query);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
