import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:isolated_http_client/isolated_http_client.dart';
import 'package:isolated_http_client/src/tokens_storage.dart';

abstract class HttpClient {
  Future<void> init();

  Future<void> clearTokens();

  bool get fakeIsolate;

  bool get authorized;

  Cancelable<Response> get({
    required String host,
    String? path,
    Map<String, String>? query,
    Map<String, String>? headers,
  });

  Cancelable<Response> head({
    required String host,
    String? path,
    Map<String, String>? query,
    Map<String, String>? headers,
  });

  Cancelable<Response> post({
    required String host,
    String? path,
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  });

  Cancelable<Response> put({
    required String host,
    String? path,
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  });

  Cancelable<Response> delete({
    required String host,
    String? path,
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  });

  Cancelable<Response> patch({
    required String host,
    String? path,
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  });

  Cancelable<Response> filePost({
    required String host,
    String? path,
    Map<String, String>? query,
    Map<String, String>? headers,
    required http.MultipartFile file,
  });
}

class HttpClientIsolated implements HttpClient {
  final Duration timeout;
  final bool log;
  final TokensStorage _tokenStorage;
  final Future<Response> Function()? onRefresh;

  @override
  final bool fakeIsolate;

  HttpClientIsolated({
    this.log = false,
    this.fakeIsolate = false,
    this.timeout = const Duration(minutes: 10),
    this.onRefresh,
  }) : _tokenStorage = TokensStorage();

  HttpClientIsolated.test({
    this.log = false,
    this.fakeIsolate = false,
    this.timeout = const Duration(minutes: 10),
    this.onRefresh,
  }) : _tokenStorage = TokensStorage.test();

  @override
  Future<void> init() => _tokenStorage.init();

  @override
  Cancelable<Response> get({
    required String host,
    String? path,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) =>
      _send(
        method: HttpMethod.get,
        host: host,
        path: path,
        query: query,
        headers: headers,
      );

  @override
  Cancelable<Response> head({
    required String host,
    String? path,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) =>
      _send(
        method: HttpMethod.head,
        host: host,
        path: path,
        query: query,
        headers: headers,
      );

  @override
  Cancelable<Response> post({
    required String host,
    String? path,
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) =>
      _send(
        method: HttpMethod.post,
        host: host,
        path: path,
        query: query,
        headers: headers,
        body: body,
      );

  @override
  Cancelable<Response> put({
    required String host,
    String? path,
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) =>
      _send(
        method: HttpMethod.put,
        host: host,
        path: path,
        query: query,
        headers: headers,
        body: body,
      );

  @override
  Cancelable<Response> delete({
    required String host,
    String? path,
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) =>
      _send(
        method: HttpMethod.delete,
        host: host,
        path: path,
        query: query,
        headers: headers,
        body: body,
      );

  @override
  Cancelable<Response> patch({
    required String host,
    String? path,
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) =>
      _send(
        method: HttpMethod.patch,
        host: host,
        path: path,
        query: query,
        headers: headers,
        body: body,
      );
  @override
  Cancelable<Response> filePost({
    required String host,
    String? path,
    Map<String, String>? query,
    Map<String, String>? headers,
    required http.MultipartFile file,
  }) =>
      _send(
        method: HttpMethod.post,
        host: host,
        path: path,
        query: query,
        headers: headers,
        file: file,
      );

  Map<String, String> get additionalHeaders {
    final token = _tokenStorage.token;
    return {
      if (token != null) HttpHeaders.authorizationHeader: bearer(token),
      HttpHeaders.contentTypeHeader: ContentType.json.toString(),
    };
  }

  Future<Response>? _refresh;

  Cancelable<Response> _send({
    required String method,
    required String host,
    String? path,
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    http.MultipartFile? file,
  }) {
    Cancelable<Response> constructRequest() {
      final queryString = query != null ? makeQuery(query) : "";
      final pathChecked = path ?? "";
      final fullPath = '$host$pathChecked$queryString';
      final allHeaders = additionalHeaders..addAll(headers ?? {});
      late RequestBundle bundle;
      if (file != null) {
        bundle = MultipartPathFile(method, fullPath, query, allHeaders, file: file);
      } else {
        bundle = RequestBundleWithBody(method, fullPath, query, allHeaders, body: body);
      }
      return request(bundle: bundle);
    }

    if (_refresh != null) {
      return Cancelable<void>.fromFuture(_refresh!).thenNext((value) {
        return constructRequest();
      });
    }
    return constructRequest();
  }

  void _rememberTokens(Response response){
    if(response.bodySource != null && response.statusCode == HttpStatus.ok){
      final body = response.body;
      _tokenStorage.save(
        body[TokensStorageKeys.token] as String?,
        body[TokensStorageKeys.refreshToken] as String?,
      );
    }
  }

  Cancelable<Response> request({required RequestBundle bundle}) => Executor()
          .execute(
        arg1: bundle,
        arg2: timeout,
        arg3: log,
        fun3: _request,
        fake: fakeIsolate,
      )
          .thenNext(
        (value) async {
          if (value.statusCode == HttpStatus.unauthorized) {
            if (onRefresh != null && _refresh == null) {
              _refresh = onRefresh!.call();
            }
            if (_refresh != null) {
              return Cancelable.fromFuture(_refresh!).thenNext(
                (value) {
                  _rememberTokens(value);
                  _refresh = null;
                  return request(bundle: bundle);
                },
              );
            }
          }
          _rememberTokens(value);
          return checkedResponse(value, bundle);
        },
      );

  static Future<Response> _request(
    RequestBundle bundle,
    Duration timeout,
    bool log,
    TypeSendPort sendPort,
  ) async {
    try {
      if (log) {
        print('Request:');
        print(bundle);
      }
      final request = await bundle.toRequest();
      final streamedResponse = await request.send().timeout(timeout);
      final httpResponse = await http.Response.fromStream(streamedResponse);
      dynamic body;
      if (httpResponse.body.isNotEmpty) {
        try {
          body = jsonDecode(httpResponse.body);
        } on FormatException {
          body = httpResponse.bodyBytes;
        }
      }
      final isolatedResponse = Response(body, httpResponse.statusCode, httpResponse.headers);
      if (log) {
        print('Response:');
        print(isolatedResponse);
      }
      return isolatedResponse;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> clearTokens() => _tokenStorage.clear();

  @override
  bool get authorized => _tokenStorage.token != null;
}
