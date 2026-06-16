import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/song.dart';

class SongProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  
  List<Song> _songs = [];
  List<Song> _favoriteSongs = [];
  List<Song> _trendingSongs = [];
  bool _isLoading = false;
  
  List<Song> get songs => _songs;
  List<Song> get favoriteSongs => _favoriteSongs;
  List<Song> get trendingSongs => _trendingSongs;
  bool get isLoading => _isLoading;
  
  SongProvider() {
    loadAllSongs();
    loadFavoriteSongs();
    loadTrendingSongs();
  }
  
  Future<void> loadAllSongs() async {
    _isLoading = true;
    notifyListeners();
    
    _songs = await _db.getAllSongs();
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> loadFavoriteSongs() async {
    _favoriteSongs = await _db.getFavoriteSongs();
    notifyListeners();
  }
  
  Future<void> loadTrendingSongs({String period = 'all'}) async {
    _trendingSongs = await _db.getTrendingSongs(limit: 10, period: period);
    notifyListeners();
  }
  
  Future<void> addSong(Song song) async {
    await _db.insertSong(song);
    await loadAllSongs();
    await loadTrendingSongs();
  }
  
  Future<void> toggleFavorite(int songId) async {
    await _db.toggleFavorite(songId);
    await loadFavoriteSongs();
    await loadAllSongs();
  }
  
  Future<List<Song>> searchSongs(String query) async {
    if (query.isEmpty) return [];
    await _db.addRecentSearch(query);
    return await _db.searchSongs(query);
  }
  
  Future<List<Song>> getSongsByGenre(String genre) async {
    return await _db.getSongsByGenre(genre);
  }
  
  Future<List<Song>> getSongsByArtist(int artistId) async {
    return await _db.getSongsByArtist(artistId);
  }
  
  Future<void> incrementPlayCount(int songId) async {
    await _db.incrementPlayCount(songId);
    await loadTrendingSongs();
  }
  
  Future<void> deleteSong(int songId) async {
    await _db.deleteSong(songId);
    await loadAllSongs();
    await loadFavoriteSongs();
    await loadTrendingSongs();
  }
}