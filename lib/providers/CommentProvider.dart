import 'package:flutter/material.dart';
import '../models/commentaire.dart';
import '../db/dbHelper.dart';

class CommentProvider with ChangeNotifier {
  List<Commentaire> _comments = [];

  List<Commentaire> get comments =>
      _comments; // Getter pour accéder aux commentaires

  // Charger les commentaires depuis la base de données
  Future<void> loadComments(int lieuId) async {
    // Filtrer les commentaires pour un lieu spécifique
    // on prend tous les commentaires et on filtre par lieuId
    _comments = await DBHelper().getCommentaires().then(
      (allComments) =>
          allComments.where((comment) => comment.lieuId == lieuId).toList(),
    );
    notifyListeners(); // Notifier les écouteurs que les données ont changé
  }

  // Ajouter un nouveau commentaire
  Future<void> addComment(Commentaire commentaire) async {
    DBHelper().debugPrintBase();

    final int idinserted = await DBHelper().insertCommentaire(commentaire);

    final newComment = commentaire.copyWith(
      rating: commentaire.rating,
      id: idinserted,
    );
    _comments.add(newComment); // Ajouter le commentaire à la liste

    notifyListeners(); // rafraischhit l'interface utilisateur avec les nouveaux commentaires
  }
}
