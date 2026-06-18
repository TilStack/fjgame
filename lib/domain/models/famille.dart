// Modèles de domaine pour une famille biblique : Descripteur, Personnage, Famille.

class Descripteur {
  final String id;
  final String familleId;
  final String texte;
  final String reference;

  const Descripteur({
    required this.id,
    required this.familleId,
    required this.texte,
    required this.reference,
  });

  Descripteur copyWith({
    String? id,
    String? familleId,
    String? texte,
    String? reference,
  }) {
    return Descripteur(
      id: id ?? this.id,
      familleId: familleId ?? this.familleId,
      texte: texte ?? this.texte,
      reference: reference ?? this.reference,
    );
  }

  factory Descripteur.fromJson(Map<String, dynamic> json) {
    return Descripteur(
      id: json['id'] as String,
      familleId: json['familleId'] as String,
      texte: json['texte'] as String,
      reference: json['reference'] as String,
    );
  }
}

class Personnage {
  final String id;
  final String familleId;
  final String nom;
  // descripteurIdentifiantId : id du Descripteur qui identifie CE personnage
  final String descripteurIdentifiantId;

  const Personnage({
    required this.id,
    required this.familleId,
    required this.nom,
    required this.descripteurIdentifiantId,
  });

  Personnage copyWith({
    String? id,
    String? familleId,
    String? nom,
    String? descripteurIdentifiantId,
  }) {
    return Personnage(
      id: id ?? this.id,
      familleId: familleId ?? this.familleId,
      nom: nom ?? this.nom,
      descripteurIdentifiantId:
          descripteurIdentifiantId ?? this.descripteurIdentifiantId,
    );
  }

  factory Personnage.fromJson(Map<String, dynamic> json) {
    return Personnage(
      id: json['id'] as String,
      familleId: json['familleId'] as String,
      nom: json['nom'] as String,
      descripteurIdentifiantId: json['descripteurIdentifiantId'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Personnage && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

class Famille {
  final String id;
  final String nom;
  final List<Descripteur> descripteurs;
  final List<Personnage> personnages;

  const Famille({
    required this.id,
    required this.nom,
    required this.descripteurs,
    required this.personnages,
  });

  Famille copyWith({
    String? id,
    String? nom,
    List<Descripteur>? descripteurs,
    List<Personnage>? personnages,
  }) {
    return Famille(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      descripteurs: descripteurs ?? this.descripteurs,
      personnages: personnages ?? this.personnages,
    );
  }

  Personnage personnageParId(String id) {
    return personnages.firstWhere((p) => p.id == id);
  }

  Descripteur descripteurParId(String id) {
    return descripteurs.firstWhere((d) => d.id == id);
  }

  // Retourne le Descripteur dont id == p.descripteurIdentifiantId
  Descripteur descripteurIdentifiantDe(Personnage p) {
    return descripteurParId(p.descripteurIdentifiantId);
  }

  // Retourne les 3 Descripteurs qui ne sont pas l'identifiant de p.
  // Ce sont les clés de recherche que le porteur de p peut demander aux autres.
  List<Descripteur> descriptionsClesDe(Personnage p) {
    return descripteurs
        .where((d) => d.id != p.descripteurIdentifiantId)
        .toList();
  }

  factory Famille.fromJson(Map<String, dynamic> json) {
    return Famille(
      id: json['id'] as String,
      nom: json['nom'] as String,
      descripteurs: (json['descripteurs'] as List)
          .map((d) => Descripteur.fromJson(d as Map<String, dynamic>))
          .toList(),
      personnages: (json['personnages'] as List)
          .map((p) => Personnage.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}
