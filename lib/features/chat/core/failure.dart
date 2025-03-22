import 'package:freezed_annotation/freezed_annotation.dart';

import 'exceptions.dart';

part 'failure.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure.server([String? message]) = ServerFailure;
  const factory Failure.cache([String? message]) = CacheFailure;
  const factory Failure.connection([String? message]) = ConnectionFailure;
  const factory Failure.authentication([String? message]) =
      AuthenticationFailure;

  // 添加此工厂方法将异常转换为Failure
  factory Failure.fromException(Exception exception) {
    if (exception is ServerException) {
      return Failure.server(exception.toString());
    } else if (exception is CacheException) {
      return Failure.cache(exception.toString());
    } else if (exception is ConnectionException) {
      return Failure.connection(exception.toString());
    } else if (exception is AuthenticationException) {
      return Failure.authentication(exception.toString());
    } else {
      return const Failure.server('未知错误');
    }
  }
}
