// lib/data/repos/nudges_repo.dart
import 'package:dio/dio.dart';
import '../models/nudge_spec.dart';
import '../network/api_client.dart';

abstract class NudgesRepo {
  Future<void> createFromSpec(NudgeSpec spec);
}

class NudgesRepoHttp implements NudgesRepo {
  final ApiClient _api;
  NudgesRepoHttp(this._api);

  @override
  Future<void> createFromSpec(NudgeSpec spec) async {
    try {
      await _api.dio.post('/nudges.create', data: spec.toJson());
    } on DioException catch (e) {
      throw e.error ?? 'Failed to create nudge';
    }
  }
}