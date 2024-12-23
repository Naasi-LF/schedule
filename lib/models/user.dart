class User {
  final int? id;
  final String username;
  final String password; // 实际应用中应该存储加密后的密码
  final String? email;

  User({
    this.id,
    required this.username,
    required this.password,
    this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      email: map['email'],
    );
  }
}
