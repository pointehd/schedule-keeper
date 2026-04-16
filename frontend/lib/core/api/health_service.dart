import 'package:dio/dio.dart';
import 'api_client.dart';

class HealthService {
  final ApiClient _client;

  HealthService(this._client);

  Future<bool> check() async {
    try {
      final data = await _client.get('/health');
      return data['status'] == 'ok';
    } on DioException {
      return false;
    }
  }
}
