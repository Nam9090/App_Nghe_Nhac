import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../models/artist.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'soundcloud.db');
    
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // Create artists table
    await db.execute('''
      CREATE TABLE artists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        avatar TEXT,
        bio TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    
    // Create songs table
    await db.execute('''
      CREATE TABLE songs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        artist_id INTEGER,
        file_path TEXT NOT NULL,
        cover_art TEXT,
        duration INTEGER NOT NULL,
        is_favorite INTEGER DEFAULT 0,
        genre TEXT,
        upload_date INTEGER NOT NULL,
        play_count INTEGER DEFAULT 0,
        FOREIGN KEY(artist_id) REFERENCES artists(id) ON DELETE SET NULL
      )
    ''');
    
    // Create playlists table
    await db.execute('''
      CREATE TABLE playlists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cover_art TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    
    // Create playlist_songs junction table
    await db.execute('''
      CREATE TABLE playlist_songs(
        playlist_id INTEGER,
        song_id INTEGER,
        order_index INTEGER,
        FOREIGN KEY(playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
        FOREIGN KEY(song_id) REFERENCES songs(id) ON DELETE CASCADE,
        PRIMARY KEY(playlist_id, song_id)
      )
    ''');
    
    // Create recent_searches table
    await db.execute('''
      CREATE TABLE recent_searches(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        searched_at INTEGER NOT NULL
      )
    ''');
    
    // Create downloads table
    await db.execute('''
      CREATE TABLE downloads(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        downloaded_at INTEGER NOT NULL,
        FOREIGN KEY(song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');
    
    // Create comments table
    await db.execute('''
      CREATE TABLE comments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_id INTEGER NOT NULL,
        username TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        position_ms INTEGER DEFAULT 0,
        FOREIGN KEY(song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');
    
    // Create notifications table
    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        song_id INTEGER,
        is_read INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(song_id) REFERENCES songs(id) ON DELETE SET NULL
      )
    ''');
    
    // Create following table
    await db.execute('''
      CREATE TABLE following(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        artist_id INTEGER NOT NULL,
        followed_at INTEGER NOT NULL,
        FOREIGN KEY(artist_id) REFERENCES artists(id) ON DELETE CASCADE,
        UNIQUE(artist_id)
      )
    ''');
    
    // Create listening_history table
    await db.execute('''
      CREATE TABLE listening_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_id INTEGER NOT NULL,
        listened_at INTEGER NOT NULL,
        FOREIGN KEY(song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Tạo bảng artists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS artists(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          avatar TEXT,
          bio TEXT,
          created_at INTEGER NOT NULL
        )
      ''');
      
      // Tạo bảng following
      await db.execute('''
        CREATE TABLE IF NOT EXISTS following(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          artist_id INTEGER NOT NULL,
          followed_at INTEGER NOT NULL,
          FOREIGN KEY(artist_id) REFERENCES artists(id) ON DELETE CASCADE,
          UNIQUE(artist_id)
        )
      ''');
      
      // Thêm cột artist_id vào bảng songs
      try {
        await db.execute('ALTER TABLE songs ADD COLUMN artist_id INTEGER REFERENCES artists(id) ON DELETE SET NULL');
      } catch (e) {
        print('Column artist_id already exists');
      }
    }
    
    if (oldVersion < 3) {
      // Tạo bảng listening_history
      await db.execute('''
        CREATE TABLE IF NOT EXISTS listening_history(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          song_id INTEGER NOT NULL,
          listened_at INTEGER NOT NULL,
          FOREIGN KEY(song_id) REFERENCES songs(id) ON DELETE CASCADE
        )
      ''');
    }
  }
  
  // ==================== ARTIST OPERATIONS ====================
  
  Future<int> insertArtist(Artist artist) async {
    final db = await database;
    return await db.insert('artists', artist.toMap());
  }
  
  Future<List<Artist>> getAllArtists() async {
    final db = await database;
    final result = await db.query('artists', orderBy: 'name ASC');
    return result.map((map) => Artist.fromMap(map)).toList();
  }
  
  Future<Artist?> getArtistById(int id) async {
    final db = await database;
    final result = await db.query('artists', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Artist.fromMap(result.first);
    }
    return null;
  }
  
  Future<Artist?> getArtistByName(String name) async {
    final db = await database;
    final result = await db.query('artists', where: 'name = ?', whereArgs: [name]);
    if (result.isNotEmpty) {
      return Artist.fromMap(result.first);
    }
    return null;
  }
  
  Future<int> updateArtist(Artist artist) async {
    final db = await database;
    return await db.update(
      'artists',
      artist.toMap(),
      where: 'id = ?',
      whereArgs: [artist.id],
    );
  }
  
  Future<int> deleteArtist(int id) async {
    final db = await database;
    return await db.delete('artists', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<int> getFollowerCount(int artistId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM following WHERE artist_id = ?',
      [artistId],
    );
    return result.first['count'] as int;
  }
  
  Future<List<Artist>> searchArtists(String query) async {
    final db = await database;
    final result = await db.query(
      'artists',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((map) => Artist.fromMap(map)).toList();
  }
  
  // ==================== SONG OPERATIONS ====================
  
  Future<int> insertSong(Song song) async {
    final db = await database;
    return await db.insert('songs', song.toMap());
  }
  
  Future<List<Song>> getAllSongs() async {
    final db = await database;
    final result = await db.query('songs', orderBy: 'upload_date DESC');
    final songs = <Song>[];
    for (var map in result) {
      final song = Song.fromMap(map);
      if (song.artistId != null) {
        final artist = await getArtistById(song.artistId!);
        song.artistName = artist?.name ?? 'Unknown Artist';
      } else {
        song.artistName = 'Unknown Artist';
      }
      songs.add(song);
    }
    return songs;
  }
  
  Future<List<Song>> getFavoriteSongs() async {
    final db = await database;
    final result = await db.query(
      'songs',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'upload_date DESC',
    );
    final songs = <Song>[];
    for (var map in result) {
      final song = Song.fromMap(map);
      if (song.artistId != null) {
        final artist = await getArtistById(song.artistId!);
        song.artistName = artist?.name ?? 'Unknown Artist';
      } else {
        song.artistName = 'Unknown Artist';
      }
      songs.add(song);
    }
    return songs;
  }
  
  Future<List<Song>> getTrendingSongs({int limit = 10, String period = 'all'}) async {
    final db = await database;
    String whereClause = '';
    List<Object?> whereArgs = [];
    
    final now = DateTime.now();
    if (period == 'week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      whereClause = 'upload_date >= ?';
      whereArgs = [weekAgo.millisecondsSinceEpoch];
    } else if (period == 'month') {
      final monthAgo = now.subtract(const Duration(days: 30));
      whereClause = 'upload_date >= ?';
      whereArgs = [monthAgo.millisecondsSinceEpoch];
    } else if (period == 'year') {
      final yearAgo = now.subtract(const Duration(days: 365));
      whereClause = 'upload_date >= ?';
      whereArgs = [yearAgo.millisecondsSinceEpoch];
    }
    
    final result = await db.query(
      'songs',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'play_count DESC',
      limit: limit,
    );
    
    final songs = <Song>[];
    for (var map in result) {
      final song = Song.fromMap(map);
      if (song.artistId != null) {
        final artist = await getArtistById(song.artistId!);
        song.artistName = artist?.name ?? 'Unknown Artist';
      } else {
        song.artistName = 'Unknown Artist';
      }
      songs.add(song);
    }
    return songs;
  }
  
  Future<List<Song>> searchSongs(String query) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT s.* FROM songs s
      LEFT JOIN artists a ON s.artist_id = a.id
      WHERE s.title LIKE ? OR a.name LIKE ?
      ORDER BY s.play_count DESC
    ''', ['%$query%', '%$query%']);
    
    final songs = <Song>[];
    for (var map in result) {
      final song = Song.fromMap(map);
      if (song.artistId != null) {
        final artist = await getArtistById(song.artistId!);
        song.artistName = artist?.name ?? 'Unknown Artist';
      } else {
        song.artistName = 'Unknown Artist';
      }
      songs.add(song);
    }
    return songs;
  }
  
  Future<List<Song>> getSongsByGenre(String genre) async {
    final db = await database;
    final result = await db.query(
      'songs',
      where: 'genre = ?',
      whereArgs: [genre],
      orderBy: 'play_count DESC',
    );
    
    final songs = <Song>[];
    for (var map in result) {
      final song = Song.fromMap(map);
      if (song.artistId != null) {
        final artist = await getArtistById(song.artistId!);
        song.artistName = artist?.name ?? 'Unknown Artist';
      } else {
        song.artistName = 'Unknown Artist';
      }
      songs.add(song);
    }
    return songs;
  }
  
  Future<List<Song>> getSongsByArtist(int artistId) async {
    final db = await database;
    final result = await db.query(
      'songs',
      where: 'artist_id = ?',
      whereArgs: [artistId],
      orderBy: 'upload_date DESC',
    );
    
    final songs = <Song>[];
    for (var map in result) {
      final song = Song.fromMap(map);
      final artist = await getArtistById(artistId);
      song.artistName = artist?.name ?? 'Unknown Artist';
      songs.add(song);
    }
    return songs;
  }
  
  Future<int> updateSong(Song song) async {
    final db = await database;
    return await db.update(
      'songs',
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }
  
  Future<int> deleteSong(int id) async {
    final db = await database;
    return await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<void> toggleFavorite(int songId) async {
    final db = await database;
    final song = await getSongById(songId);
    if (song != null) {
      await db.update(
        'songs',
        {'is_favorite': song.isFavorite ? 0 : 1},
        where: 'id = ?',
        whereArgs: [songId],
      );
    }
  }
  
  Future<Song?> getSongById(int id) async {
    final db = await database;
    final result = await db.query('songs', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      final song = Song.fromMap(result.first);
      if (song.artistId != null) {
        final artist = await getArtistById(song.artistId!);
        song.artistName = artist?.name ?? 'Unknown Artist';
      } else {
        song.artistName = 'Unknown Artist';
      }
      return song;
    }
    return null;
  }
  
  Future<void> incrementPlayCount(int songId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE songs SET play_count = play_count + 1 WHERE id = ?',
      [songId],
    );
  }
  
  // ==================== PLAYLIST OPERATIONS ====================
  
  Future<int> insertPlaylist(Playlist playlist) async {
    final db = await database;
    return await db.insert('playlists', playlist.toMap());
  }
  
  Future<List<Playlist>> getAllPlaylists() async {
    final db = await database;
    final result = await db.query('playlists', orderBy: 'created_at DESC');
    return result.map((map) => Playlist.fromMap(map)).toList();
  }
  
  Future<Playlist?> getPlaylistById(int id) async {
    final db = await database;
    final result = await db.query('playlists', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      final playlist = Playlist.fromMap(result.first);
      final songs = await getPlaylistSongs(id);
      return playlist.copyWith(songs: songs);
    }
    return null;
  }
  
  Future<List<Song>> getPlaylistSongs(int playlistId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN playlist_songs ps ON s.id = ps.song_id
      WHERE ps.playlist_id = ?
      ORDER BY ps.order_index ASC
    ''', [playlistId]);
    
    final songs = <Song>[];
    for (var map in result) {
      final song = Song.fromMap(map);
      if (song.artistId != null) {
        final artist = await getArtistById(song.artistId!);
        song.artistName = artist?.name ?? 'Unknown Artist';
      } else {
        song.artistName = 'Unknown Artist';
      }
      songs.add(song);
    }
    return songs;
  }
  
  Future<void> addSongToPlaylist(int playlistId, int songId, int orderIndex) async {
    final db = await database;
    await db.insert('playlist_songs', {
      'playlist_id': playlistId,
      'song_id': songId,
      'order_index': orderIndex,
    });
  }
  
  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    final db = await database;
    await db.delete(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
  }
  
  Future<int> deletePlaylist(int id) async {
    final db = await database;
    return await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }
  
  // ==================== FOLLOW OPERATIONS ====================
  
  Future<void> addFollowing(int artistId) async {
    final db = await database;
    final existing = await db.query(
      'following',
      where: 'artist_id = ?',
      whereArgs: [artistId],
    );
    if (existing.isEmpty) {
      await db.insert('following', {
        'artist_id': artistId,
        'followed_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
  
  Future<void> removeFollowing(int artistId) async {
    final db = await database;
    await db.delete('following', where: 'artist_id = ?', whereArgs: [artistId]);
  }
  
  Future<List<Artist>> getFollowingArtists() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT a.* FROM artists a
      INNER JOIN following f ON a.id = f.artist_id
      ORDER BY f.followed_at DESC
    ''');
    return result.map((map) => Artist.fromMap(map)).toList();
  }
  
  Future<bool> isFollowing(int artistId) async {
    final db = await database;
    final result = await db.query(
      'following',
      where: 'artist_id = ?',
      whereArgs: [artistId],
    );
    return result.isNotEmpty;
  }
  
  // ==================== RECENT SEARCH OPERATIONS ====================
  
  Future<void> addRecentSearch(String query) async {
    final db = await database;
    await db.delete(
      'recent_searches',
      where: 'query = ?',
      whereArgs: [query],
    );
    await db.insert('recent_searches', {
      'query': query,
      'searched_at': DateTime.now().millisecondsSinceEpoch,
    });
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM recent_searches');
    if (count.first['count'] as int > 10) {
      await db.rawQuery('''
        DELETE FROM recent_searches 
        WHERE id NOT IN (
          SELECT id FROM recent_searches 
          ORDER BY searched_at DESC 
          LIMIT 10
        )
      ''');
    }
  }
  
  Future<List<String>> getRecentSearches() async {
    final db = await database;
    final result = await db.query(
      'recent_searches',
      orderBy: 'searched_at DESC',
      limit: 10,
    );
    return result.map((map) => map['query'] as String).toList();
  }
  
  Future<void> clearRecentSearches() async {
    final db = await database;
    await db.delete('recent_searches');
  }
  
  // ==================== DOWNLOAD OPERATIONS ====================
  
  Future<void> addDownload(int songId, String filePath) async {
    final db = await database;
    await db.insert('downloads', {
      'song_id': songId,
      'file_path': filePath,
      'downloaded_at': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  Future<List<Song>> getDownloadedSongs() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN downloads d ON s.id = d.song_id
      ORDER BY d.downloaded_at DESC
    ''');
    
    final songs = <Song>[];
    for (var map in result) {
      final song = Song.fromMap(map);
      if (song.artistId != null) {
        final artist = await getArtistById(song.artistId!);
        song.artistName = artist?.name ?? 'Unknown Artist';
      } else {
        song.artistName = 'Unknown Artist';
      }
      songs.add(song);
    }
    return songs;
  }
  
  Future<bool> isSongDownloaded(int songId) async {
    final db = await database;
    final result = await db.query(
      'downloads',
      where: 'song_id = ?',
      whereArgs: [songId],
    );
    return result.isNotEmpty;
  }
  
  Future<void> removeDownload(int songId) async {
    final db = await database;
    await db.delete('downloads', where: 'song_id = ?', whereArgs: [songId]);
  }
  
  // ==================== COMMENT OPERATIONS ====================
  
  Future<int> addComment(int songId, String username, String content, int positionMs) async {
    final db = await database;
    return await db.insert('comments', {
      'song_id': songId,
      'username': username,
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'position_ms': positionMs,
    });
  }
  
  Future<List<Map<String, dynamic>>> getCommentsBySong(int songId) async {
    final db = await database;
    return await db.query(
      'comments',
      where: 'song_id = ?',
      whereArgs: [songId],
      orderBy: 'timestamp ASC',
    );
  }
  
  Future<int> deleteComment(int commentId) async {
    final db = await database;
    return await db.delete('comments', where: 'id = ?', whereArgs: [commentId]);
  }
  
  // ==================== NOTIFICATION OPERATIONS ====================
  
  Future<int> addNotification({
    required String type,
    required String title,
    required String message,
    int? songId,
  }) async {
    final db = await database;
    return await db.insert('notifications', {
      'type': type,
      'title': title,
      'message': message,
      'song_id': songId,
      'is_read': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  Future<List<Map<String, dynamic>>> getNotifications({bool unreadOnly = false}) async {
    final db = await database;
    return await db.query(
      'notifications',
      where: unreadOnly ? 'is_read = 0' : null,
      orderBy: 'created_at DESC',
    );
  }
  
  Future<void> markNotificationAsRead(int id) async {
    final db = await database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<void> markAllNotificationsAsRead() async {
    final db = await database;
    await db.update('notifications', {'is_read': 1});
  }
  
  Future<int> getUnreadNotificationCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM notifications WHERE is_read = 0');
    return result.first['count'] as int;
  }
  
  Future<void> deleteNotification(int id) async {
    final db = await database;
    await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }
  
  // ==================== LISTENING HISTORY OPERATIONS ====================
  
  Future<void> addToHistory(int songId) async {
    final db = await database;
    await db.insert('listening_history', {
      'song_id': songId,
      'listened_at': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  Future<List<Song>> getListeningHistory({int limit = 50}) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN listening_history lh ON s.id = lh.song_id
      ORDER BY lh.listened_at DESC
      LIMIT ?
    ''', [limit]);
    
    final songs = <Song>[];
    for (var map in result) {
      final song = Song.fromMap(map);
      if (song.artistId != null) {
        final artist = await getArtistById(song.artistId!);
        song.artistName = artist?.name ?? 'Unknown Artist';
      }
      songs.add(song);
    }
    return songs;
  }
}