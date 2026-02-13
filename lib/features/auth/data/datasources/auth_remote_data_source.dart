import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:test_auth/core/network/api_constants.dart';
import 'package:test_auth/core/logger.dart';
import '../models/token_model.dart';

class AuthRemoteDataSource {
  final Dio authDio; // plain Dio without interceptor for auth endpoints

  AuthRemoteDataSource({Dio? dio}) : authDio = dio ?? Dio() {
    authDio.options.baseUrl = baseUrl;
    authDio.options.headers['Content-Type'] = 'application/json';
    // allow handling 4xx responses manually
    authDio.options.validateStatus = (status) => status != null && status < 500;
  }

  Future<void> sendEmail(String email) async {
    logger.d('AuthRemote: sendEmail -> $email');
    try {
      final res = await authDio.post(sendEmailPath, data: {'email': email});
      logger.d('AuthRemote: sendEmail status ${res.statusCode} data=${res.data}');
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception('sendEmail failed: ${res.statusCode} ${res.data}');
      }
    } on DioException catch (e) {
      logger.e('AuthRemote: sendEmail DioException', e, e.stackTrace);
      final status = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception('sendEmail failed: $status - $data');
    } catch (e, st) {
      logger.e('AuthRemote: sendEmail error', e, st);
      rethrow;
    }
  }

  Future<TokenModel> confirmCode(String email, int code) async {
    logger.d('AuthRemote: confirmCode -> $email code:$code');
    try {
      final res = await authDio.post(confirmCodePath, data: {'email': email, 'code': code});
      logger.d('AuthRemote: confirmCode status ${res.statusCode} data=${res.data}');
      if (res.statusCode == 200) {
        return TokenModel.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('confirmCode failed: ${res.statusCode} ${res.data}');
    } on DioException catch (e) {
      logger.e('AuthRemote: confirmCode DioException', e, e.stackTrace);
      final status = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception('confirmCode failed: $status - $data');
    } catch (e, st) {
      logger.e('AuthRemote: confirmCode error', e, st);
      rethrow;
    }
  }

  Future<TokenModel> refreshToken(String refreshToken) async {
    logger.d('AuthRemote: refreshToken');
    try {
      final res = await authDio.post(refreshTokenPath, data: {'token': refreshToken});
      logger.d('AuthRemote: refreshToken status ${res.statusCode} data=${res.data}');
      if (res.statusCode == 200) {
        return TokenModel.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('refreshToken failed: ${res.statusCode} ${res.data}');
    } on DioException catch (e) {
      logger.e('AuthRemote: refreshToken DioException', e, e.stackTrace);
      final status = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception('refreshToken failed: $status - $data');
    } catch (e, st) {
      logger.e('AuthRemote: refreshToken error', e, st);
      rethrow;
    }
  }

  Future<String> getUserId(String jwt) async {
    logger.d('AuthRemote: getUserId using jwt');
    try {
      // use header expected by API
      final res = await authDio.get(authPath, options: Options(headers: {'Auth': 'Bearer $jwt'}));
      logger.d('AuthRemote: getUserId status ${res.statusCode} data=${res.data}');
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map && data.containsKey('user_id')) {
          return data['user_id'].toString();
        }
        return data.toString();
      }
      throw Exception('getUserId failed: ${res.statusCode} ${res.data}');
    } on DioException catch (e) {
      logger.e('AuthRemote: getUserId DioException', e, e.stackTrace);
      final status = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception('getUserId failed: $status - $data');
    } catch (e, st) {
      logger.e('AuthRemote: getUserId error', e, st);
      rethrow;
    }
  }
}