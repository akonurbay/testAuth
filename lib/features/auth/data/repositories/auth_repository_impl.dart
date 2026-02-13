import 'dart:async';
import 'package:dio/dio.dart';
import 'package:test_auth/core/storage/secure_storage.dart';
import 'package:test_auth/core/logger.dart';
import '../models/token_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final SecureStorage storage;

  AuthRepositoryImpl({required this.remote, required this.storage});

  @override
  Future<void> sendEmail(String email) {
    logger.i('Repository: sendEmail $email');
    return remote.sendEmail(email);
  }

  @override
  Future<TokenModel> confirmCode(String email, int code) async {
    logger.i('Repository: confirmCode');
    final tokens = await remote.confirmCode(email, code);
    await storage.saveJwt(tokens.jwt);
    await storage.saveRefreshToken(tokens.refreshToken);
    logger.i('Repository: tokens saved (confirmCode)');
    return tokens;
  }

  @override
  Future<TokenModel> refreshToken(String refreshToken) async {
    logger.i('Repository: refreshToken');
    final tokens = await remote.refreshToken(refreshToken);
    await storage.saveJwt(tokens.jwt);
    await storage.saveRefreshToken(tokens.refreshToken);
    logger.i('Repository: tokens saved (refreshToken)');
    return tokens;
  }

  @override
  Future<String> getUserId() async {
    logger.d('Repository: getUserId');
    final jwt = await storage.readJwt();
    if (jwt == null) {
      logger.w('Repository: getUserId - no jwt');
      throw Exception('No JWT');
    }
    return remote.getUserId(jwt);
  }

  @override
  Future<void> logout() async {
    logger.i('Repository: logout - clearing storage');
    await storage.clearAll();
  }

  @override
  Future<String?> readRefreshToken() => storage.readRefreshToken();
}