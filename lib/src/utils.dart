String bearer(String token) => 'bearer $token';

String makeQuery(Map<String, String> queryParameters) {
  final result = StringBuffer('?');
  var separator = '';
  void writeParameter(String key, String value) {
    result.write(separator);
    separator = '&';
    result.write(key);
    if (value.isNotEmpty) {
      result.write('=');
      result.write(value);
    }
  }
  queryParameters.forEach((key, value) {
    writeParameter(key, value);
  });
  return result.toString();
}
