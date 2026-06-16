class Song {
  final int? id;
  final String title;
  final int? artistId;
  String artistName;
  final String filePath;
  final String? coverArt;
  final int duration;
  final bool isFavorite;
  final String genre;
  final DateTime uploadDate;
  final int playCount;
  
  Song({
    this.id,
    required this.title,
    this.artistId,
    this.artistName = 'Unknown Artist',
    required this.filePath,
    this.coverArt,
    required this.duration,
    this.isFavorite = false,
    this.genre = 'Unknown',
    required this.uploadDate,
    this.playCount = 0,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist_id': artistId,
      'file_path': filePath,
      'cover_art': coverArt,
      'duration': duration,
      'is_favorite': isFavorite ? 1 : 0,
      'genre': genre,
      'upload_date': uploadDate.millisecondsSinceEpoch,
      'play_count': playCount,
    };
  }
  
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'],
      title: map['title'],
      artistId: map['artist_id'],
      artistName: 'Unknown Artist',
      filePath: map['file_path'],
      coverArt: map['cover_art'],
      duration: map['duration'],
      isFavorite: map['is_favorite'] == 1,
      genre: map['genre'] ?? 'Unknown',
      uploadDate: DateTime.fromMillisecondsSinceEpoch(map['upload_date']),
      playCount: map['play_count'] ?? 0,
    );
  }
  
  Song copyWith({
    int? id,
    String? title,
    int? artistId,
    String? artistName,
    String? filePath,
    String? coverArt,
    int? duration,
    bool? isFavorite,
    String? genre,
    DateTime? uploadDate,
    int? playCount,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artistId: artistId ?? this.artistId,
      artistName: artistName ?? this.artistName,
      filePath: filePath ?? this.filePath,
      coverArt: coverArt ?? this.coverArt,
      duration: duration ?? this.duration,
      isFavorite: isFavorite ?? this.isFavorite,
      genre: genre ?? this.genre,
      uploadDate: uploadDate ?? this.uploadDate,
      playCount: playCount ?? this.playCount,
    );
  }
}