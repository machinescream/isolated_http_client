import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class Response {
  final http.Response _response;

  Response(this._response);

  static Future<Response> fromStream(http.StreamedResponse response) async {
    return Response(await http.Response.fromStream(response));
  }

  Map<String, String> get headers => _response.headers;

  int get statusCode => _response.statusCode;

  dynamic get _jsonBody {
    try {
      return jsonDecode(_response.body);
    } on FormatException {
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

  Uint8List get bodyAsBytes => _response.bodyBytes;

  @override
  String toString() {
    return 'statusCode : $statusCode\nheaders: $headers\nbody: $_jsonBody';
  }

  String log() {
    return 'headers: $headers\nstatusCode: $statusCode\nbody: $_jsonBody';
  }
}
