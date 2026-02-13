import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../logger.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;
  SecureStorage([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const _keyJwt = 'jwt';
  static const _keyRefresh = 'refresh_token';

  Future<void> saveJwt(String jwt) {
    logger.d('SecureStorage: saveJwt');
    return _storage.write(key: _keyJwt, value: jwt);
  }
  Future<void> saveRefreshToken(String token) {
    logger.d('SecureStorage: saveRefreshToken');
    return _storage.write(key: _keyRefresh, value: token);
  }
  Future<String?> readJwt() {
    logger.d('SecureStorage: readJwt');
    return _storage.read(key: _keyJwt);
  }
  Future<String?> readRefreshToken() {
    logger.d('SecureStorage: readRefreshToken');
    return _storage.read(key: _keyRefresh);
  }
  Future<void> clearAll() {
    logger.i('SecureStorage: clearAll');
    return _storage.deleteAll();
  }
}