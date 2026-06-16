import 'song.dart';

class Playlist {
  final int? id;
  final String name;
  final String? coverArt;
  final DateTime createdAt;
  List<Song>? songs;
  
  Playlist({
    this.id,
    required this.name,
    this.coverArt,
    required this.createdAt,
    this.songs,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cover_art': coverArt,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
  
  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'],
      name: map['name'],
      coverArt: map['cover_art'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }
  
  Playlist copyWith({
    int? id,
    String? name,
    String? coverArt,
    DateTime? createdAt,
    List<Song>? songs,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      coverArt: coverArt ?? this.coverArt,
      createdAt: createdAt ?? this.createdAt,
      songs: songs ?? this.songs,
    );
  }
  
  int get totalDuration {
    if (songs == null) return 0;
    return songs!.fold(0, (sum, song) => sum + song.duration);
  }
}

class PlaylistSong {
  final int playlistId;
  final int songId;
  final int orderIndex;
  
  PlaylistSong({
    required this.playlistId,
    required this.songId,
    required this.orderIndex,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'playlist_id': playlistId,
      'song_id': songId,
      'order_index': orderIndex,
    };
  }
}