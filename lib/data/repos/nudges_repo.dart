import '../models/nudge_spec.dart';
import '../network/api_client.dart';

abstract class NudgesRepo {
  Future<String> createFromSpec(NudgeSpec spec); // returns new id
}

class NudgesRepoHttp implements NudgesRepo {
  final ApiClient _api;
  NudgesRepoHttp(this._api);

  @override
Future<String> createFromSpec(NudgeSpec spec) async {
  // Simulate latency
  await Future.delayed(const Duration(milliseconds: 150));

  // Generate a fake ID (or persist locally and return the real one)
  final id = DateTime.now().millisecondsSinceEpoch.toString();

  // OPTIONAL: if you have local storage wired, persist the spec here.
  // e.g.:
  // await SimpleNudgesStorage.addNudgeWithCategoryReturningId(
  //   spec,
  //   NudgeCategory.personal,
  // );

  return id;
}

  }


