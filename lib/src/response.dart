class Response {
  final dynamic body;
  final Map<String, String> headers;
  final int statusCode;

  Response(this.body, this.statusCode, this.headers);

  @override
  String toString() {
    return 'statusCode : $statusCode\nheaders: $headers\n body: $body';
  }
}
