class ServerException implements Exception {
  final String? message;
  ServerException([this.message]);

  @override
  String toString() => message ?? 'Server Exception';
}

class CacheException implements Exception {
  final String? message;
  CacheException([this.message]);

  @override
  String toString() => message ?? 'Cache Exception';
}

class ConnectionException implements Exception {
  final String? message;
  ConnectionException([this.message]);

  @override
  String toString() => message ?? 'Connection Exception';
}

class AuthenticationException implements Exception {
  final String? message;
  AuthenticationException([this.message]);

  @override
  String toString() => message ?? 'Authentication Exception';
}
