// Implémentation locale : charge familles.json via rootBundle, valide l'intégrité,
// et met en cache le résultat pour ne charger qu'une seule fois.

import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/models/famille.dart';
import 'famille_repository.dart';

class FamilleRepositoryImpl implements FamilleRepository {
  List<Famille>? _cache;

  @override
  Future<List<Famille>> chargerFamilles() async {
    if (_cache != null) return _cache!;

    final jsonString =
        await rootBundle.loadString('assets/data/familles.json');
    final Map<String, dynamic> decoded =
        jsonDecode(jsonString) as Map<String, dynamic>;

    final familles = (decoded['familles'] as List)
        .map((f) => Famille.fromJson(f as Map<String, dynamic>))
        .toList();

    _validerIntegrite(familles);
    _cache = familles;
    return familles;
  }

  void _validerIntegrite(List<Famille> familles) {
    for (final famille in familles) {
      if (famille.descripteurs.length != 4) {
        throw FormatException(
            'Famille "${famille.id}" : attendu 4 descripteurs, '
            'trouvé ${famille.descripteurs.length}');
      }
      if (famille.personnages.length != 4) {
        throw FormatException(
            'Famille "${famille.id}" : attendu 4 personnages, '
            'trouvé ${famille.personnages.length}');
      }
      final descripteurIds = famille.descripteurs.map((d) => d.id).toSet();
      for (final p in famille.personnages) {
        if (!descripteurIds.contains(p.descripteurIdentifiantId)) {
          throw FormatException(
              'Personnage "${p.id}" : descripteurIdentifiantId '
              '"${p.descripteurIdentifiantId}" introuvable dans la famille "${famille.id}"');
        }
      }
    }
  }
}
