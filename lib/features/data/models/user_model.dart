class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String platform;
  final String token;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.platform,
    required this.token,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? 'Guest User',  // Fallback to 'Guest User' if name is null
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      platform: data['platform'] ?? '',
      token: data['token'] ?? '',
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
    );
  }
}
