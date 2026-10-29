import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:explorez_votre_ville/providers/ThemeProvider.dart';
import 'package:explorez_votre_ville/utils/GeocodingService.dart';
import '../models/lieu.dart';
import '../providers/LieuProvider.dart';
import '../providers/CommentProvider.dart';
import '../models/commentaire.dart';
import '../widgets/CommentForm.dart';
import '../providers/LocationProvider.dart';

class AjoutModifLieuScreen extends StatefulWidget {
  final Lieu? lieu; // null si ajout, non null si modification
  final bool isDialog; //  si affiché dans un AlertDialog ou page complete


  const AjoutModifLieuScreen({super.key, this.lieu, this.isDialog = false});

  @override
  State<AjoutModifLieuScreen> createState() => _AjoutModifLieuScreenState();
}

class _AjoutModifLieuScreenState extends State<AjoutModifLieuScreen> {
  // clé de formulaire pour la validation
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categorieController;
  late TextEditingController _adresseController;

  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  final GeocodingService _geocodingService = GeocodingService();
  bool _isGeocoding = false;
  bool _isInit = false;
  Lieu? _lieuToEdit;

  @override
  void initState() {
    super.initState();
    // Initialisation des contrôleurs de texte
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _categorieController = TextEditingController();
    _adresseController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //exceucuter une seule fois pour initialsation des données
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      // Récupération des données du lieu à modifier ou ajout (priporité a la route )
      if (args is Lieu) {
        _lieuToEdit = args;
      } else {
        _lieuToEdit = widget.lieu;
      }

      if (_lieuToEdit != null) {
        //modification des contrôleurs de texte avec les données du lieu
        _titleController.text = _lieuToEdit!.title;
        _descriptionController.text = _lieuToEdit!.description;
        _categorieController.text = _lieuToEdit!.categorie;
        _adresseController.text = _lieuToEdit!.address;
        _selectedLocation = LatLng(
          _lieuToEdit!.latitude,
          _lieuToEdit!.longitude,
        );
      } else {
        // ajout
        if (_selectedLocation == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final locationProvider = Provider.of<LocationProvider>(
              context,
              listen: false,
            );
            if (locationProvider.currentPosition != null) {
              setState(() {
                _selectedLocation = locationProvider.currentPosition;
              });
            }
          });
        }
      }
      _isInit = true;
    }
  }
   // Convertit l'adresse saisie en coordonnées LatLng et centre la carte
  Future<void> _updateMapFromAddress() async {
    final address = _adresseController.text.trim();
    if (address.isEmpty) return;

    setState(() => _isGeocoding = true);
    try {
      final coords = await _geocodingService.getCoordinatesSimple(address);
      if (coords != null) {
        setState(() {
          _selectedLocation = coords;
        });
        _mapController.move(coords, 15.0);
      } else {
        // Si l'adresse n'est pas trouvée, afficher un messages
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Adresse introuvable.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }
  // constructuion de l'interface utilisateur
  @override
  Widget build(BuildContext context) {
    final isEditing = _lieuToEdit != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
     // Contenu du formulaire
    final formContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeProvider.accentOrange.withOpacity(0.1),
            ThemeProvider.accentTurquoise.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      // permet le defilement si le contenu dépasse la taille de la page
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Titre du formulaire
              if (widget.isDialog)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    isEditing ? 'Modifier le lieu' : 'Ajouter un lieu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              // champs de saisie pour le titre
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Titre',
                  labelStyle: TextStyle(color: textColor),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              // champs de saisie pour la description
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: textColor),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              // champs de saisie pour la catégorie
              TextFormField(
                controller: _categorieController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  labelStyle: TextStyle(color: textColor),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une catégorie';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              // champs de saisie pour l'adresse
              TextFormField(
                controller: _adresseController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Adresse',
                  labelStyle: TextStyle(color: textColor),
                  suffixIcon: IconButton(
                    icon: _isGeocoding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.search,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                    onPressed: _updateMapFromAddress, // declenche le geocodage
                    tooltip: 'Trouver sur la carte',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une adresse';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              // carte
              SizedBox(
                height: 300,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    // initialisation de la carte avec la position du lieu
                    initialCenter:
                        _selectedLocation ?? const LatLng(48.8566, 2.3522),
                    initialZoom: 13.0,
                    // permet de selectionner un point sur la carte
                    onTap: (tapPosition, point) {
                      setState(() => _selectedLocation = point);
                    },
                  ),
                  children: [
                    // tuiles OpenStreetMap
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    // marqueur si une position est selectionné
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              // bouton pour sauvegarder ou ajouter le lieu
              ElevatedButton.icon(
                icon: Icon(isEditing ? Icons.save : Icons.add),
                onPressed: () => _sauvegarderLieu(isEditing),
                label: Text(
                  isEditing
                      ? 'Enregistrer les modifications'
                      : 'Ajouter le lieu',
                ),
              ),
              const SizedBox(height: 16.0),
              // section des commentaires visible uniquement si le lieu est modifié
              if (isEditing) _creeSectionCommentaires(),
            ],
          ),
        ),
      ),
    );
    if (widget.isDialog) {
      return formContent;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le lieu' : 'Ajouter un lieu'),
      ),
      body: formContent,
    );
  }
  // méthode pour sauvegarder  un lieu
  void _sauvegarderLieu(bool isEditing) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une position sur la carte'),
        ),
      );
      return;
    }
    final provider = Provider.of<LieuProvider>(context, listen: false);
    final nouveauLieu = Lieu(
      id: isEditing ? _lieuToEdit!.id : 0,
      villeId: isEditing ? _lieuToEdit!.villeId : provider.villeActuelleId ?? 0,
      title: _titleController.text.trim(),
      categorie: _categorieController.text.trim(),
      description: _descriptionController.text.trim(),
      address: _adresseController.text.trim(),
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      isFavorite: isEditing ? _lieuToEdit!.isFavorite : false,
      rating: isEditing ? _lieuToEdit!.rating : 0,
    );
    if (isEditing) {
      provider.updateLieu(nouveauLieu);
    } else {
      provider.addLieu(nouveauLieu);
    }
    Navigator.of(context).pop();
  }
  // section des commentaires
  Widget _creeSectionCommentaires() {
    return Consumer<CommentProvider>(
      builder: (context, provider, _) {
        provider.loadComments(_lieuToEdit!.id);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 16.0),
            const Text(
              'Commentaires',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            ...provider.comments.map(
              (commentaire) => ListTile(
                title: Text(commentaire.auteur),
                subtitle: Text(commentaire.text),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < commentaire.rating
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
            CommentForm(
              onSubmit: (text, rating) {
                final nouveauCommentaire = Commentaire(
                  id: 0,
                  lieuId: _lieuToEdit!.id,
                  auteur: 'Anonyme',
                  text: text,
                  rating: rating.toInt(),
                );
                provider.addComment(nouveauCommentaire);
              },
              lieuId: _lieuToEdit!.id,
            ),
          ],
        );
      },
    );
  }
}
