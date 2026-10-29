import 'package:flutter/material.dart';
import '../providers/ThemeProvider.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:lottie/lottie.dart';

class Accueilscreen extends StatefulWidget {
  const Accueilscreen({super.key});

  @override
  State<StatefulWidget> createState() => _Accueilscreen();
}

class _Accueilscreen extends State<Accueilscreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double>
  _fade; // aniamtion qui gere la progression de l'animation

  @override
  void initState() {
    super.initState();

    // Initialisation du contrôleur d'animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    // Création de l'animation
    _fade = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();
  }

  // nettoyage des ressources lors de la fin de l'animation
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Couleurs du thème pour le dégradé
    const Color primaryGradientStart = ThemeProvider.accentOrange;
    const Color primaryGradientEnd = ThemeProvider.accentTurquoise;

    return Scaffold(
      backgroundColor: Colors.cyan[300],
      body: SafeArea(
        // pour s'assurer que le contenu n'est pas masqué par la barre d'etat
        child: FadeTransition(
          opacity: _fade,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryGradientStart, primaryGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animation Lottie
                    SizedBox(
                      height: 250,
                      width: 250,
                      child: Lottie.asset(
                        'assets/lottie/acclocapp.json',
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Titre animé avec effet machine à écrire
                    AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          "Explorez Votre Ville",
                          textStyle: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          speed: const Duration(milliseconds: 100),
                        ),
                      ],
                      totalRepeatCount: 1,
                    ),

                    const SizedBox(height: 30),

                    // Bouton pour accéder à l'application principale
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGradientEnd,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/principale');
                      },
                      child: const Text(
                        'Commencer',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
