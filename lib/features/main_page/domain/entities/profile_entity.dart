class ProfileEntity {
  const ProfileEntity({
    required this.id,
    required this.fullName,
    required this.type,
    this.avatarUrl,
    this.cpfCnpj,
    this.isVerified,
    this.locationLabel,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String fullName;
  final String type;
  final String? avatarUrl;
  final String? cpfCnpj;
  final bool? isVerified;
  final String? locationLabel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProfileEntity copyWith({
    String? fullName,
    String? type,
    String? avatarUrl,
    String? cpfCnpj,
    bool? isVerified,
    String? locationLabel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileEntity(
      id: id,
      fullName: fullName ?? this.fullName,
      type: type ?? this.type,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      cpfCnpj: cpfCnpj ?? this.cpfCnpj,
      isVerified: isVerified ?? this.isVerified,
      locationLabel: locationLabel ?? this.locationLabel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
