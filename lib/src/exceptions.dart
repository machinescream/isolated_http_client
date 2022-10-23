import 'package:isolated_http_client/src/requests.dart';
import 'package:isolated_http_client/src/response.dart';

Response checkedResponse(Response response, RequestBundle requestBundle) {
  final statusCode = response.statusCode;
  if (statusCode >= 200 && statusCode < 300) return response;
  if (statusCode == 401) {
    throw HttpUnauthorizedException(response.body, requestBundle);
  }
  if (statusCode >= 400 && statusCode < 500) {
    throw HttpClientException(response.body, requestBundle);
  }
  if (statusCode >= 500 && statusCode < 600) {
    throw HttpServerException(response.body, requestBundle);
  }
  throw HttpUnknownException(response.body, requestBundle);
}

class HttpClientException implements Exception {
  final Map<String, dynamic>? message;
  final RequestBundle? requestBundle;

  HttpClientException(this.message, this.requestBundle);

  @override
  String toString() => 'HttpClientException: $message\n Request: $requestBundle';
}

class HttpUnauthorizedException implements Exception {
  final Map<String, dynamic>? message;
  final RequestBundle? requestBundle;

  HttpUnauthorizedException(this.message, this.requestBundle);

  @override
  String toString() => 'HttpUnauthorizedException: $message\n Request: $requestBundle';
}

class HttpServerException implements Exception {
  final Map<String, dynamic>? message;
  final RequestBundle? requestBundle;

  HttpServerException(this.message, this.requestBundle);

  @override
  String toString() => 'HttpServerException: $message\n Request: $requestBundle';
}

class HttpUnknownException implements Exception {
  final Map<String, dynamic>? message;
  final RequestBundle? requestBundle;

  HttpUnknownException(this.message, this.requestBundle);

  @override
  String toString() => 'HttpUnknownException: $message\n Request: $requestBundle';
}
