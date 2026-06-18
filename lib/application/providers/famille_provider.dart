// Provider Riverpod exposant le catalogue des familles bibliques chargé depuis le JSON local.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/local/famille_repository_impl.dart';
import '../../domain/models/famille.dart';

part 'famille_provider.g.dart';

@riverpod
Future<List<Famille>> familles(Ref ref) async {
  return FamilleRepositoryImpl().chargerFamilles();
}
