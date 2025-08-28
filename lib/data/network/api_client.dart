// lib/data/network/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient({
    required String baseUrl,
    String? authToken,
  }) : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        )) {
    if (authToken != null && authToken.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $authToken';
    }
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) {
          final status = e.response?.statusCode;
          final msg = e.response?.data is Map && (e.response!.data['error'] != null)
              ? e.response!.data['error'].toString()
              : e.message;
          handler.next(DioException(
            requestOptions: e.requestOptions,
            error: 'HTTP $status: $msg',
            response: e.response,
            type: e.type,
          ));
        },
      ),
    );
  }
}