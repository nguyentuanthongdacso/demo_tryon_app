/// Model chung cho user đã đăng nhập
class AuthUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final AuthProvider provider;

  AuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.provider,
  });

  @override
  String toString() {
    return 'AuthUser(id: $id, email: $email, displayName: $displayName, provider: ${provider.name})';
  }
}

enum AuthProvider {
  google,
}
