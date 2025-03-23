import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String? avatar;
  final bool? isOnline; // 新增: 在线状态
  final DateTime? lastSeen; // 新增: 最后在线时间
  final DateTime? createdAt; // 新增: 创建时间

  const User({
    required this.id,
    required this.name,
    this.avatar,
    this.isOnline,
    this.lastSeen,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, avatar, isOnline, lastSeen, createdAt];

  // 简化的工厂构造函数，用于测试和模拟数据
  factory User.mock({
    String? id,
    String? name,
    String? avatar,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? 'mock-${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Mock User',
      avatar: avatar,
      isOnline: isOnline ?? false,
      lastSeen: lastSeen ?? DateTime.now().subtract(const Duration(minutes: 5)),
      createdAt: createdAt ?? DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  // 从 JSON 创建用户，便于快速构建测试数据
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['username'] as String,
      avatar: json['avatar'] as String?,
      isOnline: json['isOnline'] as bool? ?? json['connected'] as bool?,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : (json['lastActive'] != null
              ? DateTime.parse(json['lastActive'] as String)
              : null),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (avatar != null) 'avatar': avatar,
      if (isOnline != null) 'isOnline': isOnline,
      if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  // 复制并更新部分属性
  @override
  User copyWith({
    String? id,
    String? name,
    String? avatar,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'User(id: $id, name: $name, isOnline: $isOnline)';
}
