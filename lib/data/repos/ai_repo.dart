// lib/data/repos/ai_repo.dart
import 'package:dio/dio.dart';
import '../models/nudge_spec.dart';
import '../network/api_client.dart';

abstract class AiRepo {
  Future<NudgeSpec> suggestFromChat(String userInput, String tz);
}

class AiRepoHttp implements AiRepo {
  final ApiClient _api;
  AiRepoHttp(this._api);

  @override
  Future<NudgeSpec> suggestFromChat(String userInput, String tz) async {
    try {
      final res = await _api.dio.post('/ai.suggest', data: {
        'text': userInput,
        'tz': tz,
      });
      final data = res.data as Map<String, dynamic>;
      final spec = NudgeSpec.fromJson(data);
      return spec;
    } on DioException catch (e) {
      throw e.error ?? 'AI suggest failed';
    } on FormatException catch (e) {
      throw 'Invalid AI JSON: ${e.message}';
    }
  }
}