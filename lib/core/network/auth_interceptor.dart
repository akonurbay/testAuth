import 'dart:async';
import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../logger.dart';

/// Interceptor that adds JWT to requests and tries to refresh token on 401.
/// refresh uses AuthRemoteDataSource (plain Dio) to avoid interceptor recursion.
class AuthInterceptor extends Interceptor {
  final SecureStorage storage;
  final AuthRemoteDataSource remote; // used for refresh
  final Dio dio;

  // lock & queue helpers
  bool _isRefreshing = false;
  final List<QueuedRequest> _queue = [];

  AuthInterceptor({required this.storage, required this.remote, required this.dio});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final jwt = await storage.readJwt();
    if (jwt != null && jwt.isNotEmpty) {
      // use header expected by API
      options.headers['Auth'] = 'Bearer $jwt';
      logger.d('AuthInterceptor: added Auth header');
    }
    handler.next(options);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    logger.w('AuthInterceptor: request error ${err.response?.statusCode} ${err.requestOptions.path}');
    if (err.response?.statusCode == 401) {
      final refresh = await storage.readRefreshToken();
      if (refresh == null) {
        logger.w('AuthInterceptor: no refresh token, cannot refresh');
        handler.next(err);
        return;
      }

      if (_isRefreshing) {
        logger.d('AuthInterceptor: refresh in progress — queueing request ${err.requestOptions.path}');
        final completer = Completer<Response>();
        _queue.add(QueuedRequest(options: err.requestOptions, completer: completer));
        try {
          final response = await completer.future;
          handler.resolve(response);
        } catch (e) {
          handler.next(err);
        }
        return;
      }

      _isRefreshing = true;
      logger.i('AuthInterceptor: attempting token refresh');
      try {
        final tokens = await remote.refreshToken(refresh);
        await storage.saveJwt(tokens.jwt);
        await storage.saveRefreshToken(tokens.refreshToken);
        logger.i('AuthInterceptor: refresh succeeded, tokens saved');

        // retry original failed request with new token
        final opts = err.requestOptions;
        opts.headers['Auth'] = 'Bearer ${tokens.jwt}';
        final cloneReq = await dio.fetch(opts);
        // resolve queued
        for (final q in _queue) {
          final o = q.options;
          o.headers['Auth'] = 'Bearer ${tokens.jwt}';
          dio.fetch(o).then((r) => q.completer.complete(r)).catchError((e) => q.completer.completeError(e));
        }
        _queue.clear();
        handler.resolve(cloneReq);
      } catch (e, st) {
        logger.e('AuthInterceptor: refresh failed', e, st);
        // refresh failed -> clear storage and propagate
        await storage.clearAll();
        for (final q in _queue) {
          q.completer.completeError(e);
        }
        _queue.clear();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
      return;
    }

    handler.next(err);
  }
}

class QueuedRequest {
  final RequestOptions options;
  final Completer<Response> completer;
  QueuedRequest({required this.options, required this.completer});
}