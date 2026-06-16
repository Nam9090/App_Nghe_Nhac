class Artist {
  final int? id;
  final String name;
  final String? avatar;
  final String? bio;
  final DateTime createdAt;
  
  Artist({
    this.id,
    required this.name,
    this.avatar,
    this.bio,
    required this.createdAt,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'bio': bio,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
  
  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'],
      name: map['name'],
      avatar: map['avatar'],
      bio: map['bio'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }
  
  Artist copyWith({
    int? id,
    String? name,
    String? avatar,
    String? bio,
    DateTime? createdAt,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}