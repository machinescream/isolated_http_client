import 'dart:convert';
import 'dart:typed_data';

class Response {
  final Uint8List _bodyBytes;
  final String _body;
  final Map<String, String> headers;
  final int statusCode;

  Response(this._bodyBytes, this._body, this.statusCode, this.headers);

  dynamic get _jsonBody {
    try {
      return jsonDecode(_body);
    } on FormatException catch (e) {
      return <String, dynamic>{};
    }
  }

  Map<String, dynamic> get body => _jsonBody is Map<String, dynamic>
      ? _jsonBody as Map<String, dynamic>
      : throw ArgumentError("body: $_jsonBody is not Map");

  List<dynamic> get bodyAsList => _jsonBody is List
      ? _jsonBody as List<dynamic>
      : throw ArgumentError("body: $_jsonBody is not "
          "List");

  Uint8List get bodyAsBytes => _bodyBytes;

  @override
  String toString() {
    return 'statusCode : $statusCode\nheaders: $headers\nbody: $_jsonBody';
  }

  String log() {
    return 'headers: $headers\nstatusCode: $statusCode\nbody: $_jsonBody';
  }
}
