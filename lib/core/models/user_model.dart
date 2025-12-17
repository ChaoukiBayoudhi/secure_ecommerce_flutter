/// User model and related data structures.
///
/// Security considerations:
/// - Never store passwords in frontend
/// - Sanitize user input before sending to backend
/// - Validate data types
library;

class User {
  final int id;
  final String email;
  final String username;
  final String? firstName;
  final String? lastName;
  final bool isActive;
  final bool isSuperuser;
  final DateTime dateJoined;
  final DateTime? lastLogin;
  final bool mfaEnabled;
  final List<Role> roles;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    required this.isActive,
    required this.isSuperuser,
    required this.dateJoined,
    this.lastLogin,
    required this.mfaEnabled,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      username: json['username'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isSuperuser: json['is_superuser'] as bool? ?? false,
      dateJoined: DateTime.parse(json['date_joined'] as String),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'] as String)
          : null,
      mfaEnabled: json['mfa_enabled'] as bool? ?? false,
      roles:
          (json['roles'] as List<dynamic>?)
              ?.map((role) => Role.fromJson(role as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'is_active': isActive,
      'is_superuser': isSuperuser,
      'date_joined': dateJoined.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'mfa_enabled': mfaEnabled,
      'roles': roles.map((role) => role.toJson()).toList(),
    };
  }

  bool hasRole(String roleName) {
    return roles.any(
      (role) => role.name.toUpperCase() == roleName.toUpperCase(),
    );
  }

  bool hasAnyRole(List<String> roleNames) {
    return roleNames.any((roleName) => hasRole(roleName));
  }

  bool get isAdmin => isSuperuser || hasRole('ADMIN');
}

class Role {
  final int id;
  final String name;
  final String? description;

  Role({required this.id, required this.name, this.description});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description};
  }
}

class LoginRequest {
  final String email;
  final String password;
  final String? totpCode;

  LoginRequest({required this.email, required this.password, this.totpCode});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'email': email, 'password': password};
    if (totpCode != null) {
      json['totp_code'] = totpCode!;
    }
    return json;
  }
}

class RegisterRequest {
  final String email;
  final String username;
  final String password;
  final String passwordConfirm;
  final String? firstName;
  final String? lastName;

  RegisterRequest({
    required this.email,
    required this.username,
    required this.password,
    required this.passwordConfirm,
    this.firstName,
    this.lastName,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'email': email.trim(),
      'username': username.trim(),
      'password': password,
      'password_confirm': passwordConfirm,
    };

    // Only include optional fields if they have non-empty values
    if (firstName != null && firstName!.trim().isNotEmpty) {
      json['first_name'] = firstName!.trim();
    }
    if (lastName != null && lastName!.trim().isNotEmpty) {
      json['last_name'] = lastName!.trim();
    }

    return json;
  }
}

class AuthResponse {
  final String? message;
  final User user;
  final Tokens? tokens;
  final bool mfaRequired;

  AuthResponse({
    this.message,
    required this.user,
    this.tokens,
    this.mfaRequired = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] as String?,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      tokens: json['tokens'] != null
          ? Tokens.fromJson(json['tokens'] as Map<String, dynamic>)
          : null,
      mfaRequired: json['mfa_required'] as bool? ?? false,
    );
  }
}

class Tokens {
  final String access;
  final String refresh;

  Tokens({required this.access, required this.refresh});

  factory Tokens.fromJson(Map<String, dynamic> json) {
    return Tokens(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'access': access, 'refresh': refresh};
  }
}

class TokenRefreshResponse {
  final String access;

  TokenRefreshResponse({required this.access});

  factory TokenRefreshResponse.fromJson(Map<String, dynamic> json) {
    final access = json['access'];
    if (access == null || access is! String || access.isEmpty) {
      throw FormatException(
        'Invalid token refresh response: missing or invalid access token',
      );
    }
    return TokenRefreshResponse(access: access);
  }
}
