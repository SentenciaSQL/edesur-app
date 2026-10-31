import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

/// Cliente HTTP preparado para sustituir los repositorios mock.
///
/// El prototipo no ejecuta solicitudes. [attachSession] deja el encabezado
/// listo para cuando exista un token emitido por los servicios de EDESUR.
class EdesurApiClient {
  EdesurApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.futureApiBaseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            headers: const {
              'Accept': 'application/json',
              'X-Client': 'edesur-movil-prototipo',
            },
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _sessionToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;
  String? _sessionToken;

  void attachSession(String? token) {
    _sessionToken = token;
  }
}
