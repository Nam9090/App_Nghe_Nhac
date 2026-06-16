import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/playlist.dart';
import '../models/song.dart';

class PlaylistProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  
  List<Playlist> _playlists = [];
  bool _isLoading = false;
  
  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading;
  
  PlaylistProvider() {
    loadPlaylists();
  }
  
  Future<void> loadPlaylists() async {
    _isLoading = true;
    notifyListeners();
    
    _playlists = await _db.getAllPlaylists();
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> createPlaylist(String name, {String? coverArt}) async {
    final playlist = Playlist(
      name: name,
      coverArt: coverArt,
      createdAt: DateTime.now(),
    );
    await _db.insertPlaylist(playlist);
    await loadPlaylists();
  }
  
  Future<void> addSongToPlaylist(int playlistId, int songId, int orderIndex) async {
    await _db.addSongToPlaylist(playlistId, songId, orderIndex);
    await loadPlaylists();
  }
  
  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    await _db.removeSongFromPlaylist(playlistId, songId);
    await loadPlaylists();
  }
  
  Future<void> deletePlaylist(int playlistId) async {
    await _db.deletePlaylist(playlistId);
    await loadPlaylists();
  }
  
  Future<List<Song>> getPlaylistSongs(int playlistId) async {
    return await _db.getPlaylistSongs(playlistId);
  }
}