import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import 'cache_service.dart';

class DioService {
  late final Dio _dio;
  final CacheService _cacheService;

  DioService(this._cacheService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (ApiConstants.apiKey.isNotEmpty)
            ApiConstants.apiKeyHeader: ApiConstants.apiKey,
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Ajouter le token d'authentification si disponible
          final token = await _cacheService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (kDebugMode) {
            debugPrint(
              'REQUEST[${options.method}] => PATH: ${options.baseUrl}${options.path}',
            );
            if (options.queryParameters.isNotEmpty) {
              debugPrint('QUERY: ${options.queryParameters}');
            }
            if (options.data != null) {
              debugPrint('BODY: ${options.data}');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              'RESPONSE[${response.statusCode}] => PATH: '
              '${response.requestOptions.baseUrl}${response.requestOptions.path}',
            );
            if (response.data != null) {
              _logBody('RESPONSE BODY', response.data);
            }
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            final request = error.requestOptions;
            debugPrint(
              'ERROR[${error.response?.statusCode}] => PATH: '
              '${request.baseUrl}${request.path}',
            );
            debugPrint('MESSAGE: ${error.message}');
            if (error.response?.data != null) {
              _logBody('ERROR BODY', error.response?.data);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } catch (e) {
      rethrow;
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } catch (e) {
      rethrow;
    }
  }

  void _logBody(String label, dynamic body) {
    if (body == null) return;

    if (body is Map<String, dynamic> && body['data'] is List) {
      final count = (body['data'] as List).length;
      debugPrint('$label SUMMARY: data.length=$count');
    }

    final text = body.toString();
    const chunkSize = 700;

    for (var i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      debugPrint('$label [${(i ~/ chunkSize) + 1}]: ${text.substring(i, end)}');
    }
  }
}
