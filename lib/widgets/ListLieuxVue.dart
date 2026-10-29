import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/LieuProvider.dart';
import '../models/lieu.dart';
import '../utils/icon_mapping.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Pour l'animation (Point 1.10)

class ListLieuxVue extends StatelessWidget {
  const ListLieuxVue({super.key});

  @override
  Widget build(BuildContext context) {
    // Utiliser Consumer pour écouter le LieuProvider
    return Consumer<LieuProvider>(
      builder: (context, lieuProvider, child) {
        final lieuxAffiches = lieuProvider.lieux; // Récupère la liste filtrée et triée

        if (lieuxAffiches.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_off_outlined,
                      size: 60,
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Aucun lieu trouvé',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lieuProvider.selectedCategory != null &&
                            lieuProvider.selectedCategory != 'Tout'
                        ? 'Essayez une autre catégorie que "${lieuProvider.selectedCategory}".'
                        : 'Explorez la carte ou lancez une recherche pour trouver des pépites !',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        // Animation d'apparition pour la liste
        return SizedBox(
          height: 280, // Hauteur fixe pour le défilement horizontal
          child: AnimationLimiter(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: lieuxAffiches.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                final lieu = lieuxAffiches[index];

                // Application de l'animation à chaque élément
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    horizontalOffset: 50.0,
                    child: FadeInAnimation(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/lieudetails',
                            arguments: lieu,
                          );
                        },
                        child: LieuCard(lieu: lieu),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// widget
class LieuCard extends StatelessWidget {
  final Lieu lieu;

  const LieuCard({super.key, required this.lieu});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. zone superieur
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    color: primaryColor.withOpacity(0.1),
                  ),
                  // animation de transition de l'image
                  child: Hero(
                    tag: 'lieu_image_${lieu.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child:
                          (lieu.imagePath != null &&
                              lieu.imagePath!.startsWith('http'))
                          ? Image.network(
                              lieu.imagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    getCategoryIcon(lieu.categorie),
                                    size: 48,
                                    color: primaryColor,
                                  ),
                                );
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryColor.withOpacity(0.1),
                                    primaryColor.withOpacity(0.2),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  getCategoryIcon(lieu.categorie),
                                  size: 48,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                // Bouton Favori flottant
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white.withOpacity(0.9),
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        Provider.of<LieuProvider>(
                          context,
                          listen: false,
                        ).toggleLieuFavorite(lieu.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(
                          12.0,
                        ),
                        child: Icon(
                          lieu.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: lieu.isFavorite
                              ? Colors.redAccent
                              : Colors.grey.shade400,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Zone inferieur  (Titre, Catégorie, Note)
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // titre
                      Text(
                        lieu.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // catégorie
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          lieu.categorie.toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Note
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lieu.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        " (120)", // Placeholder
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
