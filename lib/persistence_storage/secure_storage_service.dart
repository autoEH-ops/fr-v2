import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveLogin(String accountId) async {
    await _storage.write(key: 'accountId', value: accountId);
  }

  Future<String?> getLoggedInAccountId() async {
    return await _storage.read(key: 'accountId');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'accountId');
  }
}
