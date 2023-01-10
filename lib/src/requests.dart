import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:isolated_http_client/src/http_method.dart';

abstract class RequestBundle {
  final String method;
  final String url;
  final Map<String, String>? query;
  final Map<String, String>? headers;

  RequestBundle(this.method, this.url, this.query, this.headers);

  FutureOr<http.BaseRequest> toRequest();

  @override
  String toString() => '[$method ] url: $url\nquery: $query\nheaders: $headers';
}

class RequestBundleWithBody extends RequestBundle {
  final Object? body;

  RequestBundleWithBody(
    String method,
    String url,
    Map<String, String>? query,
    Map<String, String>? headers, {
    required this.body,
  }) : super(method, url, query, headers);

  @override
  String toString() => '[$method] url: $url\nquery: $query\nheaders: $headers\n body: $body';

  @override
  http.Request toRequest() {
    final request = http.Request(method, Uri.parse(url));
    if (method != HttpMethod.get) {
      final encodedBody = jsonEncode(body);
      request.body = encodedBody;
    }
    if (headers != null) {
      request.headers.addAll(headers!);
    }
    return request;
  }
}

class MultipartPathFile extends RequestBundle {
  final http.MultipartFile file;

  MultipartPathFile(
    String method,
    String url,
    Map<String, String>? query,
    Map<String, String>? headers, {
    required this.file,
  }) : super(method, url, query, headers);

  @override
  Future<http.MultipartRequest> toRequest() async => http.MultipartRequest(method, Uri.parse(url))
    ..files.add(file)
    ..headers.addAll(headers ?? {});
}
