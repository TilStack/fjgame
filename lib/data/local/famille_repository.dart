// Interface abstraite pour le chargement des familles bibliques depuis la source locale.

import '../../domain/models/famille.dart';

abstract class FamilleRepository {
  Future<List<Famille>> chargerFamilles();
}
