import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:test_auth/core/logger.dart';
import '../../data/models/token_model.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  AuthCubit({required this.repository}) : super(AuthInitial());

  Future<void> appStarted() async {
    logger.i('AuthCubit: appStarted');
    emit(AuthLoading());

    final refresh = await repository.readRefreshToken();
    if (refresh == null) {
      logger.d('AuthCubit: no refresh token -> Unauthenticated');
      emit(Unauthenticated());
      return;
    }

    try {
      await repository.refreshToken(refresh);
      final userId = await repository.getUserId();
      logger.i('AuthCubit: restored session for user $userId');
      emit(Authenticated(userId));
    } catch (e, st) {
      logger.w('AuthCubit: session restore failed', e, st);
      emit(Unauthenticated());
    }
  }

  Future<void> sendEmail(String email) async {
    logger.i('AuthCubit: sendEmail');
    emit(AuthLoading());
    try {
      await repository.sendEmail(email);
      emit(CodeSent());
    } catch (e, st) {
      logger.e('AuthCubit: sendEmail error', e, st);
      emit(AuthError(e.toString()));
    }
  }

  Future<void> confirmCode(String email, int code) async {
    logger.i('AuthCubit: confirmCode');
    emit(AuthLoading());
    try {
      final TokenModel tokens = await repository.confirmCode(email, code);
      // tokens already saved by repository
      final userId = await repository.getUserId();
      logger.i('AuthCubit: confirmCode succeeded for user $userId');
      emit(Authenticated(userId));
    } catch (e, st) {
      logger.e('AuthCubit: confirmCode error', e, st);
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    logger.i('AuthCubit: logout');
    emit(AuthLoading());
    await repository.logout();
    emit(Unauthenticated());
  }
}