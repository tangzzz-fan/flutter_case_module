import 'package:freezed_annotation/freezed_annotation.dart';

import 'exceptions.dart';

part 'failure.freezed.dart';

/// 统一的失败类型定义
///
/// 这个类合并了原来的 failure.dart 和 failures.dart 中的定义
/// 提供 Freezed 风格的模式匹配和构造函数
@freezed
class Failure with _$Failure {
  // 主要失败类型
  const factory Failure.server([String? message]) = ServerFailure;
  const factory Failure.cache([String? message]) = CacheFailure;
  const factory Failure.connection([String? message]) = ConnectionFailure;
  const factory Failure.authentication([String? message]) =
      AuthenticationFailure;

  // 从异常转换为Failure的工厂方法
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

// 为了兼容性而添加的别名类型
typedef RemoteFailure = Failure;
typedef LocalFailure = Failure;
