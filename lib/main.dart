import 'dart:io';
import 'package:explorez_votre_ville/screens/ajout_modif_lieu_screen.dart';
import 'package:explorez_votre_ville/screens/principalscreen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/LieuProvider.dart';
import 'providers/LocationProvider.dart';
import 'providers/CommentProvider.dart';
import 'providers/ThemeProvider.dart';
import 'screens/acceuilscreen.dart';
import 'screens/lieu_detail_screen.dart';

// SQLite native (Android / iOS / Windows / Linux)
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// SQLite version web
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isAndroid || Platform.isIOS || Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final prefs = await SharedPreferences.getInstance();
  final initDarkMode = prefs.getBool(ThemeProvider.themeKey) ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LieuProvider()),
        ChangeNotifierProvider(create: (context) => LocationProvider()),
        ChangeNotifierProvider(create: (context) => CommentProvider()),
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(initDarkMode),
        ),
      ],
      child: const ExplorezVotreVilleApp(),
    ),
  );
}

class ExplorezVotreVilleApp extends StatelessWidget {
  const ExplorezVotreVilleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Explorez Votre Ville',
      theme: themeProvider.currentTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      darkTheme: themeProvider.currentTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const Accueilscreen(),
        '/principale': (context) => const Principalescreen(),
        '/lieudetails': (context) => const LieuDetailScreen(),
        '/ajouterModifierLieu': (context) => const AjoutModifLieuScreen(),
      },
    );
  }
}
