import 'package:explorez_votre_ville/models/commentaire.dart';
import 'package:explorez_votre_ville/models/ville.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/lieu.dart';

// Classe de gestion de la base de données SQLite
class DBHelper {
  static final DBHelper _instance = DBHelper._internal(); // instance unique
  DBHelper._internal(); // constructeur privé pour l'instance unique
  factory DBHelper() => _instance; // factory qui retourne l'instance unique
  // connexion a la base de donnees
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('explorez_votre_ville.db');
    return _database!;
  }

  // initialise la base de donnees
  Future<Database> _initDB(String filePath) async {
    final String path;
    if (kIsWeb) {
      path = filePath;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    } // chemin complet vers la base de donnees

    return await openDatabase(
      // ouvre  la base de donnees
      path,
      version: 4,
      onCreate:
      _createDB, // fonction appelee lors de la creation de la base de donnees
    );
  }

  // cree les tables dans la base de donnees
  Future _createDB(Database db, int version) async {
    await db.execute('''  
      CREATE TABLE villes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ex_id TEXT NOT NULL,
        nom TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        description TEXT ,
        lastSeen INTEGER NOT NULL,
        details_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE lieux (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ville_id INTEGER NOT NULL, 
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        categorie TEXT NOT NULL,
        image_path TEXT,
        is_favorite INTEGER NOT NULL,
        rating REAL NOT NULL,
        adresse TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        FOREIGN KEY (ville_id) REFERENCES villes (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE commentaires (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lieu_id INTEGER NOT NULL,
        auteur TEXT NOT NULL,
        text TEXT NOT NULL,
        note REAL NOT NULL,
        FOREIGN KEY (lieu_id) REFERENCES lieux (id) ON DELETE CASCADE
      )
    ''');
  }

  /* Methodes pour la tablle villes */
  // insertion d'une ville dans la base de donnees ou remplacement si elle existe
  Future<int> insertVille(Ville ville) async {
    final db = await database;
    final map = ville.toMap();
    if (map['id'] == 0) {
      map.remove('id');
    }
    return await db.insert(
      'villes',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Recupere toutes les villes de la base de donnees
  Future<List<Ville>> getVilles() async {
    final db = await database;
    // obtenir toutes les villes de la table 'villes'
    final List<Map<String, Object?>> result = await db.query('villes');
    return [
      for (var item in result) Ville.fromMap(item),
    ]; // liste des villes creees a partir des maps dans la base de donnees
  }

  // mise a jour d'une ville existante par son ID
  Future<int> updateVille(Ville ville) async {
    final db = await database;

    return await db.update(
      'villes',
      ville.toMap(),
      where: 'id = ?',
      whereArgs: [ville.id],
    );
  }

  // suppression d'une ville par son id
  Future<int> deleteVille(int id) async {
    final db = await database;

    return await db.delete('villes', where: 'id = ?', whereArgs: [id]);
  }

  // recuperer la ville par son id externe
  Future<Ville?> getVilleByExId(String exId) async {
    final db = await database;
    final List<Map<String, Object?>> result = await db.query(
      'villes',
      where: 'ex_id = ?',
      whereArgs: [exId],
    );
    if (result.isNotEmpty) {
      return Ville.fromMap(result.first);
    }
    return null;
  }

  /* Methodes pour la tablle lieux */

  // insertion d'un lieu dans la base de donnees ou remplacement si elle existe
  Future<int> insertLieu(Lieu lieu) async {
    final db = await database;
    final map = lieu.toMap();
    if (map['id'] == 0) {
      map.remove('id');
    }
    return await db.insert(
      'lieux',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Recupere tous les lieux de la base de donnees
  Future<List<Lieu>> getLieux() async {
    final db = await database;
    final List<Map<String, Object?>> result = await db.query('lieux');

    return [for (var item in result) Lieu.fromMap(item)];
  }

  // mise a jour d'un lieu existant par son ID
  Future<int> updateLieu(Lieu lieu) async {
    final db = await database;

    return await db.update(
      'lieux',
      lieu.toMap(),
      where: 'id = ?',
      whereArgs: [lieu.id],
    );
  }

  // suppression d'un lieu par son id
  Future<int> deleteLieu(int id) async {
    final db = await database;
    return await db.delete('lieux', where: 'id = ?', whereArgs: [id]);
  }

  // redcuperer les lieux d'une ville filtrés par l'ID
  Future<List<Lieu>> getLieuxByVilleId(int villeId) async {
    final db = await database;
    final List<Map<String, Object?>> result = await db.query(
      'lieux',
      where: 'ville_id = ?',
      whereArgs: [villeId],
    );
    return [for (var item in result) Lieu.fromMap(item)];
  }

  /* Methodes pour la tablle commentaires */

  // insertion d'un commentaire dans la base de donnees ou remplacement si elle existe
  Future<int> insertCommentaire(Commentaire commentaire) async {
    final db = await database;
    final map = commentaire.toMap();
    if (map['id'] == 0) {
      map.remove('id');
    }
    return await db.insert(
      'commentaires',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Recupere tous les commentaires de la base de donnees
  Future<List<Commentaire>> getCommentaires() async {
    final db = await database;
    final List<Map<String, Object?>> result = await db.query('commentaires');

    return [for (var item in result) Commentaire.fromMap(item)];
  }

  // mise a jour d'un commentaire existant par son ID
  Future<int> updateCommentaire(Commentaire commentaire) async {
    final db = await database;

    return await db.update(
      'commentaires',
      commentaire.toMap(),
      where: 'id = ?',
      whereArgs: [commentaire.id],
    );
  }

  Future<int> deleteCommentaire(int id) async {
    final db = await database;

    return await db.delete('commentaires', where: 'id = ?', whereArgs: [id]);
  }

  // methodes de debug pour la base de donnees
  //// Affiche le contenu de la table 'villes' dans la console
  void debugPrintBase() async {
    final db = await database;
    final List<Map<String, Object?>> result = await db.query('villes');
    debugPrint('Base de donnees ouverte');
    debugPrint(result.toString());
  }

  // Supprime entièrement le fichier de base de données (pour réinitialisation)
  Future<void> clearDatabase() async {
    final String path;
    if (kIsWeb) {
      path = 'explorez_votre_ville.db';
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, 'explorez_votre_ville.db');
    }
    await deleteDatabase(path);
    _database = null;
    debugPrint('Base de données supprimée');
  }
}
