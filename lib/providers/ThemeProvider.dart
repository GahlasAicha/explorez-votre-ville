import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String themeKey = 'darkMode'; // Clé pour les préférences pour sauvegarder le mode sombre
  bool _isDarkMode; // c l'etat actuel : mode sombre est true
  static const Color accentOrange = Color(0xFFFFCC80); // Couleur utilisé en mode sombre
  static const Color accentTurquoise = Color(0xFF4DB6AC); // couleur utilisé en mode light
  static const Color deepTeal = Color(0xFF00A389); // couleur principal de l'app
  // Constructeur
  ThemeProvider(this._isDarkMode);

  bool get isDarkMode => _isDarkMode;
  ThemeData get currentTheme => _isDarkMode
      ? ThemeData.dark().copyWith(
          primaryColor: deepTeal,
          colorScheme: const ColorScheme.dark(
            primary: deepTeal, // Couleur principale pour les boutons barre d'application et de recherche
            secondary: accentOrange, // Orange comme accent  pour FAB
            surface: Color(0xFF212121), // Couleur de fond de l'interface
            onPrimary: Colors.white, // Couleur du texte
            onSecondary: Colors.black, // Couleur du texte
          ),
           appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E)),
        )
      : ThemeData.light().copyWith(
          primaryColor: deepTeal,
          colorScheme: const ColorScheme.light(
            primary: deepTeal, // Couleur principale pour les boutons
            secondary: accentTurquoise, // Vert Turquoise comme accent
            surface: Colors.white,
            onPrimary: Colors.white, // Couleur du texte sur le fond deepTeal
            onSecondary: Colors.black, // Couleur du texte sur le fond accentTurquoise
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: deepTeal,
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
            iconTheme: IconThemeData(color: Colors.white), // Couleur des icônes de l'AppBar
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: accentTurquoise, // FAB en Turquoise
            foregroundColor: Colors.white,
          ),
        );
  // Méthode pour changer le mode de thème
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
     // persistance : sauvegarder le mode sombre dans les préférences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(themeKey, _isDarkMode);
    // notifie l'interface utilisateur
    notifyListeners();
  }
}
