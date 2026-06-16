import '../database/database_helper.dart';
import '../models/song.dart';

class DailyMixService {
  final DatabaseHelper _db = DatabaseHelper();
  
  Future<List<Song>> generateDailyMix() async {
    final allSongs = await _db.getAllSongs();
    final favoriteSongs = await _db.getFavoriteSongs();
    final listeningHistory = await _db.getListeningHistory(limit: 50);
    
    if (allSongs.isEmpty) return [];
    if (favoriteSongs.isEmpty && listeningHistory.isEmpty) {
      return await _db.getTrendingSongs(limit: 20);
    }
    
    final favoriteGenres = <String, int>{};
    for (var song in favoriteSongs) {
      favoriteGenres[song.genre] = (favoriteGenres[song.genre] ?? 0) + 1;
    }
    
    final favoriteArtists = <int, int>{};
    for (var song in favoriteSongs) {
      if (song.artistId != null) {
        favoriteArtists[song.artistId!] = (favoriteArtists[song.artistId!] ?? 0) + 1;
      }
    }
    
    final sortedGenres = favoriteGenres.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topGenre = sortedGenres.isNotEmpty ? sortedGenres.first.key : null;
    
    final topArtistId = favoriteArtists.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topArtist = topArtistId.isNotEmpty ? topArtistId.first.key : null;
    
    List<Song> recommended = [];
    
    if (topArtist != null) {
      final artistSongs = await _db.getSongsByArtist(topArtist);
      recommended.addAll(artistSongs);
    }
    
    if (topGenre != null) {
      final genreSongs = await _db.getSongsByGenre(topGenre);
      for (var song in genreSongs) {
        if (!recommended.any((s) => s.id == song.id)) {
          recommended.add(song);
        }
      }
    }
    
    final trending = await _db.getTrendingSongs(limit: 10);
    for (var song in trending) {
      if (!recommended.any((s) => s.id == song.id)) {
        recommended.add(song);
      }
    }
    
    final recentSongIds = listeningHistory.map((s) => s.id).toSet();
    recommended.removeWhere((song) => recentSongIds.contains(song.id));
    
    return recommended.take(20).toList();
  }
}