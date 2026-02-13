import '../../data/models/token_model.dart';

abstract class AuthRepository {
  Future<void> sendEmail(String email);
  Future<TokenModel> confirmCode(String email, int code);
  Future<TokenModel> refreshToken(String refreshToken);
  Future<String> getUserId();
  Future<void> logout();

  // added: read stored refresh token for startup logic
  Future<String?> readRefreshToken();
}