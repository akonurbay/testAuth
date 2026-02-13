class TokenModel {
  final String jwt;
  final String refreshToken;

  TokenModel({required this.jwt, required this.refreshToken});

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      jwt: json['jwt'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
    );
  }
}