class Response {
  final Object _body;
  final Map<String, String> headers;
  final int statusCode;

  Response(this._body, this.statusCode, this.headers);

  Map<String, dynamic> get body =>
      _body is Map<String, dynamic> ? _body as Map<String, dynamic> : throw ArgumentError("body: $_body is not Map");

  List<dynamic> get bodyAsList => _body is List
      ? _body as List<dynamic>
      : throw ArgumentError("body: $_body is not "
          "List");

  @override
  String toString() {
    return 'statusCode : $statusCode\nheaders: $headers\n body: $_body';
  }

  String log() {
    return 'headers: $headers\nstatusCode: $statusCode\nbody: $_body';
  }
}
