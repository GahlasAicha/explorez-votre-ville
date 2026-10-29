class Commentaire {
  final int id;
  final int lieuId;
  final String auteur;
  final String text;
  final int rating;

  Commentaire({
    required this.id,
    required this.lieuId,
    required this.auteur,
    required this.text,
    this.rating = 0,
  });
  // convertit une Map en objet Commentaire pour la persistance dans la base de données
  Map<String, dynamic> toMap() => {
    'id': id,
    'lieu_id': lieuId,
    'auteur': auteur,
    'text': text,
    'note': rating,
  };
  // Reconstruit un objet Commentaire à partir d'une Map de données
  factory Commentaire.fromMap(Map<String, Object?> json) {
    return Commentaire(
      id: json['id'] as int,
      lieuId: json['lieu_id'] as int,
      auteur: json['auteur'] as String,
      text: json['text'] as String,
      rating: (json['note'] as num).toInt(),
    );
  }
  //permet de créer une copie d'un objet Commentaire avec des modifications optionnelles
  Commentaire copyWith({
    int? id,
    int? lieuId,
    String? auteur,
    String? text,
    int? rating,
  }) {
    return Commentaire(
      id: id ?? this.id,
      lieuId: lieuId ?? this.lieuId,
      auteur: auteur ?? this.auteur,
      text: text ?? this.text,
      rating: rating ?? this.rating,
    );
  }
}
