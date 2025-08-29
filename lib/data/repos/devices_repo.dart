import '../network/api_client.dart';

abstract class DevicesRepo {
  Future<void> register(String token, String platform); // 'ios' | 'android' | 'web'
}

class DevicesRepoHttp implements DevicesRepo {
  final ApiClient _api;
  DevicesRepoHttp(this._api);

  @override
  Future<void> register(String token, String platform) async {
    await _api.dio.post('/devices-register', data: {
      'token': token,
      'platform': platform,
    });
  }
}
