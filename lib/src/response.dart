import 'dart:typed_data';

class Response {
  final Object? bodySource;
  final Map<String, String> headers;
  final int statusCode;

  Response(this.bodySource, this.statusCode, this.headers);

  Map<String, dynamic> get body {
    final body = bodySource;
    return body is Map<String, dynamic> ? body : throw ArgumentError("body: $bodySource is not Map");
  }

  List<dynamic> get bodyAsList {
    final body = bodySource;
    return body is List ? body : throw ArgumentError("body: $bodySource is not List");
  }

  Uint8List get bodyAsBytes {
    final body = bodySource;
    return body is Uint8List ? body : throw ArgumentError("body: $bodySource is not Uint8List");
  }

  @override
  String toString() => 'statusCode : $statusCode\nheaders: $headers\n body: $bodySource';
}
