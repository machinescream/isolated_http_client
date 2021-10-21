import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

abstract class RequestBundle {
  final String method;
  final String url;
  final Map<String, String> query;
  final Map<String, String> headers;

  RequestBundle(this.method, this.url, this.query, this.headers);

  FutureOr<http.BaseRequest> toRequest();

  @override
  String toString() {
    return '[$method] url: $url\nquery: $query\nheaders: $headers';
  }
}

class RequestBundleWithBody extends RequestBundle {
  final Object body;

  RequestBundleWithBody(
      String method, String url, Map<String, String> query, Map<String, String> headers,
      {required this.body})
      : super(method, url, query, headers);

  @override
  String toString() {
    return '[$method] url: $url\nquery: $query\nheaders: $headers\n body: $body';
  }

  @override
  http.Request toRequest() {
    final request = http.Request(method, Uri.parse(url));
    if (method != "GET") {
      final encodedBody = jsonEncode(body);
      request.body = encodedBody;
    }
    request.headers.addAll(headers);
    return request;
  }
}

class MultipartRequestBundle extends RequestBundle {
  final List<MultipartBundleFile> files;
  final Map<String, String> fields;

  MultipartRequestBundle(
      String method, String url, Map<String, String> query, Map<String, String> headers,
      {this.files = const [], this.fields = const {}})
      : super(method, url, query, headers);

  @override
  Future<http.BaseRequest> toRequest() async {
    final request = http.MultipartRequest(method, Uri.parse(url));
    request.headers.addAll(headers);
    request.fields.addAll(fields);
    for (final file in files) {
      final multipartFile = await file.toMultipartFile();
      request.files.add(multipartFile);
    }
    return request;
  }
}

abstract class MultipartBundleFile {
  MultipartBundleFile();

  factory MultipartBundleFile.fromPath(String field, String filePath,
      {String? filename, MediaType? contentType}) = _MultipartPathFile;

  factory MultipartBundleFile.fromBytes(String field, List<int> filePath,
      {String? filename, MediaType? contentType}) = _MultipartBytesFile;

  factory MultipartBundleFile.fromString(String field, String filePath,
      {String? filename, MediaType? contentType}) = _MultipartStringFile;

  FutureOr<http.MultipartFile> toMultipartFile();
}

class _MultipartPathFile extends MultipartBundleFile {
  final String field;
  final String filePath;
  final String? filename;
  final MediaType? contentType;

  _MultipartPathFile(this.field, this.filePath, {this.filename, this.contentType});

  @override
  Future<http.MultipartFile> toMultipartFile() async {
    return http.MultipartFile.fromPath(
      field,
      filePath,
      filename: filename,
      contentType: contentType,
    );
  }
}

class _MultipartBytesFile extends MultipartBundleFile {
  final String field;
  final List<int> value;
  final String? filename;
  final MediaType? contentType;

  _MultipartBytesFile(this.field, this.value, {this.filename, this.contentType});

  @override
  Future<http.MultipartFile> toMultipartFile() async {
    return http.MultipartFile.fromBytes(
      field,
      value,
      filename: filename,
      contentType: contentType,
    );
  }
}

class _MultipartStringFile extends MultipartBundleFile {
  final String field;
  final String value;
  final String? filename;
  final MediaType? contentType;

  _MultipartStringFile(this.field, this.value, {this.filename, this.contentType});

  @override
  Future<http.MultipartFile> toMultipartFile() async {
    return http.MultipartFile.fromString(
      field,
      value,
      filename: filename,
      contentType: contentType,
    );
  }
}
