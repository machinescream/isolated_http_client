import 'dart:typed_data';

class Response {
  final Object? _body;
  final Map<String, String> headers;
  final int statusCode;

  Response(this._body, this.statusCode, this.headers);

  Map<String, dynamic> get body {
    final body = _body;
    return body is Map<String, dynamic> ? body : throw ArgumentError("body: $_body is not Map");
  }

  List<dynamic> get bodyAsList {
    final body = _body;
    return body is List ? body : throw ArgumentError("body: $_body is not List");
  }

  Uint8List get bodyAsBytes {
    final body = _body;
    return body is Uint8List ? body : throw ArgumentError("body: $_body is not Uint8List");
  }

  @override
  String toString() => 'statusCode : $statusCode\nheaders: $headers\n body: $_body';
}
