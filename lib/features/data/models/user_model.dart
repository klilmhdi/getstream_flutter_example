class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String platform;
  final String token;
  final bool isActiveUser;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.platform,
    required this.token,
    required this.isActiveUser,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? 'Guest User',
      // Fallback to 'Guest User' if name is null
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      platform: data['platform'] ?? '',
      token: data['token'] ?? '',
      isActiveUser: data['isActiveUser'] ?? false,
    );
  }

  UserModel copyWith({String? name}) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      role: role,
      platform: platform,
      token: token,
      isActiveUser: isActiveUser,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': uid,
      'name': name,
      'email': email,
      'token': token,
      'role': role,
      'platform': platform,
      'isActiveUser': isActiveUser
    };
  }
}
