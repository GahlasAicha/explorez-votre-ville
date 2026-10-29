import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/LieuProvider.dart';
import '../providers/ThemeProvider.dart';
import '../utils/icon_mapping.dart';

class BareeCategory extends StatelessWidget {
  const BareeCategory({super.key});
   // Liste des catégories disponibles
  final List<String> categories = const [
    'Tout',
    'Monument',
    'Nature',
    'Restaurant',
    'Musée',
    'Café',
    'Bar',
    'Hôtel',
    'Shopping',
    'Transport',
  ];

  @override
  Widget build(BuildContext context) {
    // Récupération des providers
    final lieuProvider = Provider.of<LieuProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Recuperation des couleurs
    final primaryColor = Theme.of(context).primaryColor;
    final selectedCategory = lieuProvider.selectedCategory ?? 'Tout';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics:
            const BouncingScrollPhysics(), // Scroll rebondissant sur l'écran
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (BuildContext context, int index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          final iconData = getCategoryIcon(category);
          // Utilise AnimatedContainer pour des transitions douces lors de la sélection
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(right: 12.0),
            //  style de decoration  de la baree
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected
                  ? null
                  : (isDark ? Colors.grey[800] : Colors.white),
              borderRadius: BorderRadius.circular(30.0),
              boxShadow: isSelected
                  ? [
                      BoxShadow( // ombre colorée pour l'etat actif
                        color: primaryColor.withOpacity(0.4),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ]
                  : [
                      BoxShadow( // ombre subtile pour l'etat inactif
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            // zone de clic
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30.0),
                onTap: () {
                  // Mettre à jour la catégorie sélectionnée
                  lieuProvider.setCategory(category);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      // icone de categorie
                      Icon(
                        iconData,
                        size: 20,
                        // Couleur blanche si sélectionné, couleur primaire du thème sinon
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : primaryColor),
                      ),
                      const SizedBox(width: 8),
                      // nom de categorie
                      Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
