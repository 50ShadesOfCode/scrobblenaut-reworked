//                                                              //
// Scrobblenaut - A deadly simple Last.FM API Wrapper for Dart. //
//                  Copyright (c) 2020 Nebulino                 //
//                                                              //

import 'package:dio/dio.dart';
import 'package:scrobblenaut/scrobblenaut_exceptions.dart';
import 'package:scrobblenaut/src/helpers/post_response_helper.dart';
import 'package:scrobblenaut/src/helpers/utils.dart';

/// It helps creating a Http Connection to [LastFM] APIs,
/// for sending and receiving requests.
///
/// [LastFM]: https://last.fm/api
class SpaceShip {
  final Dio _dio;

  SpaceShip({required String baseUrl})
      : _dio = Dio(
          BaseOptions(
              baseUrl: baseUrl,
              headers: <String, dynamic>{
                'Content-type': 'application/x-www-form-urlencoded',
                'Accept-Charset': 'utf-8',
                'User-Agent': 'DartyFM'
              },
              //contentType: Headers.formUrlEncodedContentType,
              responseType: ResponseType.json),
        )..interceptors.add(InterceptorsWrapper(onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
            options.queryParameters
                .removeWhere((String key, dynamic value) => value == null);

            if (options.data == null) {
              return handler.next(options);
            }

            if (options.data is Map) {
              (options.data as Map<dynamic, dynamic>)
                  .removeWhere((dynamic key, dynamic value) => value == null);
            }

            return handler.next(options);
          }, onResponse:
              (Response<dynamic> response, ResponseInterceptorHandler handler) {
            if (isXml(response.data)) {
              final PostResponseHelper postResponse =
                  PostResponseHelper.parse(response.data as String);

              if (!postResponse.status) {
                throw LastFMException.generate(response.data);
              }
            } else {
              if (response.data['error'] != null) {
                throw LastFMException(
                    errorCode: response.data['error'].toString(),
                    description: response.data['message'].toString());
              }
            }

            return handler.next(response);
          }, onError: (DioError error, ErrorInterceptorHandler handler) {
            if (error.type == DioErrorType.response) {
              throw LastFMException.generate(error.response!.data);
            } else {
              return handler.next(error);
            }
          }));

  Future<dynamic> get({
    required Map<String, dynamic> parameters,
  }) async {
    parameters['format'] = 'json';
    return (await _dio.get('', queryParameters: parameters)).data;
  }

// Post request with JSON response exists?
  Future<dynamic> post({
    required Map<String, dynamic> parameters,
  }) async {
    return (await _dio.post('', data: parameters)).data;
  }
}
