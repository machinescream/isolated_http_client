import 'package:shared_preferences/shared_preferences.dart';

abstract class TokensStorageKeys {
  static const String token = 'accessToken';
  static const String refreshToken = 'refreshToken';
}

abstract class TokensStorage {
  factory TokensStorage() = _TokensStorageImpl;
  factory TokensStorage.test() = _TokensStorageTest;

  String? get token;

  String? get refreshToken;

  Future<void> init();

  void save(String? token, String? refreshToken);

  Future<void> clear();
}

class _TokensStorageTest implements TokensStorage {

  String? _token;
  String? _refreshToken;

  @override
  String? get token => _token;

  @override
  String? get refreshToken => _refreshToken;

  @override
  Future<void> init() async {}

  @override
  void save(String? token, String? refreshToken) {
    if (token != null) {
      _token = token;
    }
    if (refreshToken != null) {
      _refreshToken = refreshToken;
    }
  }

  @override
  Future<void> clear() async {
    _token = null;
    _refreshToken = null;
  }
}

class _TokensStorageImpl implements TokensStorage {
  late SharedPreferences _storage;

  String? _token;
  String? _refreshToken;

  @override
  String? get token => _token;

  @override
  String? get refreshToken => _refreshToken;

  @override
  Future<void> init() async {
    _storage = await SharedPreferences.getInstance();
    _token = _storage.getString(TokensStorageKeys.token);
    _refreshToken = _storage.getString(TokensStorageKeys.refreshToken);
  }

  @override
  void save(String? token, String? refreshToken) {
    if (token != null) {
      _token = token;
      _storage.setString(TokensStorageKeys.token, token);
    }
    if (refreshToken != null) {
      _refreshToken = refreshToken;
      _storage.setString(TokensStorageKeys.refreshToken, refreshToken);
    }
  }

  @override
  Future<void> clear() async {
    _token = null;
    _refreshToken = null;
    await _storage.remove(TokensStorageKeys.token);
    await _storage.remove(TokensStorageKeys.refreshToken);
  }
}
