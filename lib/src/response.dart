class Response {
  final Object? bodySource;
  final Map<String, String> headers;
  final int statusCode;

  Response(this.bodySource, this.statusCode, this.headers);

  Map<String, dynamic> get body {
    final body = bodySource;
    return body is Map<String, dynamic> ? body : throw ArgumentError("body: $bodySource is not Map");
  }

  @override
  String toString() => 'statusCode : $statusCode\nheaders: $headers\n body: $bodySource';
}
