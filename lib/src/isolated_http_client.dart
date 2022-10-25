import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:isolated_http_client/isolated_http_client.dart';
import 'package:isolated_http_client/src/tokens_storage.dart';

abstract class HttpClient {
  Future<void> init();

  // Future<void> tusUpload({
  //   required String url,
  //   required XFile file,
  //   required Map<String, dynamic>? requestBody,
  //   Map<String, String>? headers,
  //   void Function(double progress)? onProgress,
  //   void Function()? onComplete,
  // });

  Cancelable<Response> get({
    required String host,
    String path,
    Map<String, String>? query,
    Map<String, String>? headers,
    bool fakeIsolate = false,
  });

  Cancelable<Response> head({
    required String host,
    String path,
    Map<String, String>? query,
    Map<String, String>? headers,
    bool fakeIsolate = false,
  });

  Cancelable<Response> post({
    required String host,
    String path,
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool fakeIsolate = false,
  });

  Cancelable<Response> put({
    required String host,
    String path,
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool fakeIsolate = false,
  });

  Cancelable<Response> delete({
    required String host,
    String path,
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool fakeIsolate = false,
  });

  Cancelable<Response> patch({
    required String host,
    String path,
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool fakeIsolate = false,
  });

  Cancelable<Response> request({
    required RequestBundle bundle,
    bool fakeIsolate = false,
  });
}

class IsolatedHttpClient implements HttpClient {
  final Duration timeout;
  final bool log;
  final _tokenStorage = TokensStorage();

  // final _supportClient = http.Client();

  IsolatedHttpClient(this.timeout, {this.log = false});

  @override
  Future<void> init() => _tokenStorage.init();

  @override
  Cancelable<Response> get({
    required String host,
    String path = '',
    Map<String, String>? query,
    Map<String, String>? headers,
    bool fakeIsolate = false,
  }) =>
      _send(
        method: HttpMethod.get,
        host: host,
        path: path,
        query: query,
        headers: headers,
        fakeIsolate: fakeIsolate,
      );

  @override
  Cancelable<Response> head({
    required String host,
    String path = '',
    Map<String, String>? query,
    Map<String, String>? headers,
    bool fakeIsolate = false,
  }) =>
      _send(
        method: HttpMethod.head,
        host: host,
        path: path,
        query: query,
        headers: headers,
        fakeIsolate: fakeIsolate,
      );

  @override
  Cancelable<Response> post({
    required String host,
    String path = '',
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool fakeIsolate = false,
  }) =>
      _send(
        method: HttpMethod.post,
        host: host,
        path: path,
        query: query,
        headers: headers,
        body: body,
        fakeIsolate: fakeIsolate,
      );

  @override
  Cancelable<Response> put({
    required String host,
    String path = '',
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool fakeIsolate = false,
  }) =>
      _send(
        method: HttpMethod.put,
        host: host,
        path: path,
        query: query,
        headers: headers,
        body: body,
        fakeIsolate: fakeIsolate,
      );

  @override
  Cancelable<Response> delete({
    required String host,
    String path = '',
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool fakeIsolate = false,
  }) =>
      _send(
        method: HttpMethod.delete,
        host: host,
        path: path,
        query: query,
        headers: headers,
        body: body,
        fakeIsolate: fakeIsolate,
      );

  @override
  Cancelable<Response> patch({
    required String host,
    String path = '',
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool fakeIsolate = false,
  }) =>
      _send(
        method: HttpMethod.patch,
        host: host,
        path: path,
        query: query,
        headers: headers,
        body: body,
        fakeIsolate: fakeIsolate,
      );

  Map<String, String> get additionalHeaders {
    final token = _tokenStorage.token;
    return {
      if (token != null) HttpHeaders.authorizationHeader: bearer(token),
      HttpHeaders.contentTypeHeader: ContentType.json.toString(),
    };
  }

  Completer<void>? _refresh;

  Cancelable<Response> _send({
    required String method,
    required String host,
    String path = '',
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool fakeIsolate = false,
  }) {
    Cancelable<Response> constructRequest() {
      final queryString = query != null ? makeQuery(query) : '';
      final fullPath = '$host$path$queryString';
      headers?.addAll(additionalHeaders);
      final bundle = RequestBundleWithBody(method, fullPath, query, headers, body: body);
      return request(bundle: bundle, fakeIsolate: fakeIsolate);
    }

    if (_refresh != null) {
      return Cancelable<void>.fromFuture(_refresh!.future).thenNext((value) {
        return constructRequest();
      });
    }
    return constructRequest();
  }

  @override
  Cancelable<Response> request({
    required RequestBundle bundle,
    bool fakeIsolate = false,
  }) {
    return Executor()
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
          if (_refresh != null) {
            return Cancelable.fromFuture(_refresh!.future)
                .thenNext((value) => request(bundle: bundle, fakeIsolate: fakeIsolate));
          } else {
            // await refresh
            // null refresh
            // continue
          }
        }
        final body = value.body;
        _tokenStorage.save(
          body[TokensStorageKeys.token] as String?,
          body[TokensStorageKeys.refreshToken] as String?,
        );
        return checkedResponse(value, bundle);
      },
    );
  }

  static Future<Response> _request(
    RequestBundle bundle,
    Duration timeout,
    bool log,
    TypeSendPort sendPort,
  ) async {
    try {
      final request = await bundle.toRequest();
      //TODO:...
      // if (log) {
      //   print('Request:');
      //   if (request is http.Request) {
      //     final bodyLine = request.body.isEmpty ? '' : ',\nbody: ${request.body}';
      //     print('url: [${request.method}] ${request.url},\nheaders: ${request.headers}$bodyLine');
      //   } else {
      //     print(
      //         'url: [${request.method}] ${request.url},\nheaders: ${request.headers},\nbody: <unknown>');
      //   }
      // }

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

  // @override
  // Future<void> tusUpload({
  //   required String url,
  //   required XFile file,
  //   required Map<String, dynamic>? requestBody,
  //   Map<String, String>? headers,
  //   void Function(double progress)? onProgress,
  //   void Function()? onComplete,
  // }) async {
  //   final maxChunkSize = 512 * 1024;
  //   var offset = await _getOffset(headers, url);
  //   final int totalBytes = await file.length();
  //
  //   Future<Uint8List> _getData() async {
  //     int start = offset;
  //     int end = offset + maxChunkSize;
  //     end = end > totalBytes ? totalBytes : end;
  //
  //     final result = BytesBuilder();
  //     await for (final chunk in file.openRead(start, end)) {
  //       result.add(chunk);
  //     }
  //
  //     final bytesRead = min(maxChunkSize, result.length);
  //     offset = offset + bytesRead;
  //
  //     return result.takeBytes();
  //   }
  //
  //   while (offset < totalBytes) {
  //     final uploadHeaders = (headers ?? {})
  //       ..addAll({
  //         "Tus-Resumable": "1.0.0",
  //         "Upload-Offset": "$offset",
  //         "Content-Type": "application/offset+octet-stream"
  //       });
  //
  //     await _supportClient.patch(
  //       url as Uri,
  //       headers: uploadHeaders,
  //       body: await _getData(),
  //     );
  //
  //     if (onProgress != null) {
  //       onProgress(offset / totalBytes * 100);
  //     }
  //
  //     if (offset == totalBytes) {
  //       onComplete?.call();
  //     }
  //   }
  // }

  // Future<int> _getOffset(Map<String, String>? headers, String uploadUrl) async {
  //   final offsetHeaders = (headers ?? {})..addAll({"Tus-Resumable": "1.0.0"});
  //   final response = await head(host: uploadUrl, headers: offsetHeaders);
  //   checkedResponse(
  //       response, RequestBundleWithBody('head', uploadUrl, {}, offsetHeaders, body: ""));
  //
  //   int? serverOffset = _parseOffset(response.headers["upload-offset"]);
  //   if (serverOffset == null) {
  //     throw HttpServerException(
  //         {"message": "missing upload offset in response for resuming upload"}, null);
  //   }
  //   return serverOffset;
  // }

  int? _parseOffset(String? offset) {
    if (offset == null || offset.isEmpty) {
      return null;
    }
    if (offset.contains(",")) {
      offset = offset.substring(0, offset.indexOf(","));
    }
    return int.tryParse(offset);
  }
}
