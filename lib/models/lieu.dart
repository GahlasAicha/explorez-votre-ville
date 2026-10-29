class Lieu {
  final int id;
  final int villeId;
  final String title;
  final String? imagePath;
  final String categorie;
  final String description;
  final double latitude;
  final double longitude;
  final bool isFavorite;
  final int rating;
  final String address;

  Lieu({
    required this.id,
    required this.villeId,
    required this.title,
    this.imagePath,
    required this.categorie,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.isFavorite = false,
    this.rating = 0,
    this.address = '',
  });

  Lieu copyWith({
    int? id,
    int? villeId,
    String? title,
    String? imagePath,
    String? categorie,
    String? description,
    double? latitude,
    double? longitude,
    bool? isFavorite,
    int? rating,
    String? address,
  }) {
    return Lieu(
      id: id ?? this.id,
      villeId: villeId ?? this.villeId,
      title: title ?? this.title,
      imagePath: imagePath ?? this.imagePath,
      categorie: categorie ?? this.categorie,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,

      address: address ?? this.address,

    );
  }
 // convertit un objet Lieu en une Map pour la persistance dans la base de données
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'ville_id': villeId,
      'title': title,
      'image_path': imagePath,
      'categorie': categorie,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'is_favorite': isFavorite ? 1 : 0,
      'rating': rating,
      'adresse': address,
    };
    if (id != 0) {
      map['id'] = id;
    }
    return map;
  }
 // Reconstruit un objet Lieu à partir d'une Map de données
  factory Lieu.fromMap(Map<String, Object?> json) {
    return Lieu(
      id: json['id'] as int,
      villeId: json['ville_id'] as int,
      title: json['title'] as String,
      imagePath: json['image_path'] as String?,
      categorie: json['categorie'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isFavorite: json['is_favorite'] == 1,
      rating: (json['rating'] as num).toInt(),
      address: json['adresse'] as String? ?? '',
    );
  }
}
