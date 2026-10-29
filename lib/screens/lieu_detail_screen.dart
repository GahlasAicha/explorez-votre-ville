import 'package:explorez_votre_ville/models/commentaire.dart';
import 'package:explorez_votre_ville/widgets/CommentForm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/lieu.dart';
import '../providers/CommentProvider.dart';
import '../providers/LieuProvider.dart';
import '../providers/ThemeProvider.dart';
import '../utils/icon_mapping.dart';

class LieuDetailScreen extends StatefulWidget {
  static const routeName = '/lieudetails';

  final Lieu? lieuArgument;

  const LieuDetailScreen({super.key, this.lieuArgument});

  @override
  State<LieuDetailScreen> createState() => _LieuDetailScreenState();
}

class _LieuDetailScreenState extends State<LieuDetailScreen>
    with SingleTickerProviderStateMixin {
  late MapController _mapController;
  late AnimationController _controller;
  late Animation<double> _animation;

  late Lieu lieu;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Lieu) {
        lieu = args;
      } else if (widget.lieuArgument != null) {
        lieu = widget.lieuArgument!;
      } else {
        // Fallback or error handling
        lieu = Lieu(
          id: 0,
          villeId: 0,
          title: 'Erreur',
          categorie: 'unknown',
          description: 'Lieu introuvable',
          latitude: 0,
          longitude: 0,
          address: '',
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final commentProvider = Provider.of<CommentProvider>(
          context,
          listen: false,
        );
        await commentProvider.loadComments(lieu.id);

        if (!mounted) return;

        final comments = commentProvider.comments;
        if (comments.isNotEmpty) {
          final ratings = comments.map((c) => c.rating).toList();
          Provider.of<LieuProvider>(
            context,
            listen: false,
          ).calculerMoyenneNotes(lieu.id, ratings);
        }
      });
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(lieu.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/ajouterModifierLieu',
                arguments: lieu,
              );
            },
          ),
        ],
      ),

      body: Container(
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
        child: FadeTransition(
          opacity: _animation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    // Image du lieu
                    Hero(
                      tag: 'lieu_image_${lieu.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            (lieu.imagePath != null &&
                                lieu.imagePath!.startsWith('http'))
                            ? Image.network(
                                lieu.imagePath!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    width: double.infinity,
                                    color: Colors.grey.withOpacity(0.3),
                                    child: Icon(
                                      getCategoryIcon(lieu.categorie),
                                      size: 80,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                height: 200,
                                width: double.infinity,
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                child: Icon(
                                  getCategoryIcon(lieu.categorie),
                                  size: 80,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                      ),
                    ),
                    // Degrade en bas pour le titre
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withAlpha(200),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Titre du lieu, note et categorie
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre
                          Text(
                            lieu.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Note et categorie
                          Row(
                            children: [
                              // categorie
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white70,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  lieu.categorie,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // note
                              Consumer<LieuProvider>(
                                builder: (context, lieuProvider, _) {
                                  // On récupère le lieu à jour pour afficher la note correcte
                                  final currentLieu = lieuProvider.lieux
                                      .firstWhere(
                                        (l) => l.id == lieu.id,
                                        orElse: () => lieu,
                                      );

                                  return Row(
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < currentLieu.rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 20,
                                      );
                                    }),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Description du lieu
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (lieu.address.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 20,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lieu.address,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        lieu.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                // carte interactive
                SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(
                            lieu.latitude,
                            lieu.longitude,
                          ), // Fixed lat/lon names
                          initialZoom: 15.0,
                          minZoom: 3,
                          maxZoom: 18,
                          interactionOptions: const InteractionOptions(
                            flags:
                                InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'explorez_votre_ville',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 80.0,
                                height: 80.0,
                                point: LatLng(lieu.latitude, lieu.longitude),
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 40.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Column(
                          children: [
                            FloatingActionButton(
                              heroTag: 'zoom_in', // necessaire pour l'animation
                              mini: true,
                              onPressed: () {
                                // zoom +1 niveau au centre actuek de la carte
                                _mapController.move(
                                  _mapController.camera.center,
                                  _mapController.camera.zoom + 1,
                                );
                              },
                              child: const Icon(Icons.add),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton(
                              heroTag: 'zoom_out',
                              mini: true,
                              onPressed: () {
                                // zoom -1 niveau au centre actuek de la carte
                                _mapController.move(
                                  _mapController.camera.center,
                                  _mapController.camera.zoom - 1,
                                );
                              },
                              child: const Icon(Icons.remove),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Formulaire d'ajout de commentaire
                CommentForm(
                  lieuId: lieu.id,
                  onSubmit: (String text, double rating) async {
                    final provider = Provider.of<CommentProvider>(
                      context,
                      listen: false,
                    );
                    await provider.addComment(
                      Commentaire(
                        id: 0,
                        lieuId: lieu.id,
                        text: text,
                        rating: rating.toInt(),
                        auteur: 'Anonyme',
                      ),
                    );
                    // Recalcul moyenne
                    final comments = provider.comments;
                    final ratings = comments.map((c) => c.rating).toList();
                    Provider.of<LieuProvider>(
                      context,
                      listen: false,
                    ).calculerMoyenneNotes(lieu.id, ratings);
                  },
                ),

                // Espace pour les commentaires deja existants
                const SizedBox(height: 16),
                const Text(
                  'Commentaires',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Consumer<CommentProvider>( // Utilisation de Consumer
                  builder: (context, value, _) => value.comments.isEmpty  // seul ce bloc qui va etre reconstruit
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Aucun commentaire pour le moment.'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          // empeche la liste de se defiler elle meme
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: value.comments.length,
                          itemBuilder: (context, index) {
                            final comment = value.comments[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(comment.text),
                                subtitle: Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < comment.rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
