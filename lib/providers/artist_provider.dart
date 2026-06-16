import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/artist.dart';

class ArtistProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  
  List<Artist> _artists = [];
  bool _isLoading = false;
  
  List<Artist> get artists => _artists;
  bool get isLoading => _isLoading;
  
  ArtistProvider() {
    loadArtists();
  }
  
  Future<void> loadArtists() async {
    _isLoading = true;
    notifyListeners();
    
    _artists = await _db.getAllArtists();
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<Artist?> createArtist(String name, {String? avatar, String? bio}) async {
    final artist = Artist(
      name: name,
      avatar: avatar,
      bio: bio,
      createdAt: DateTime.now(),
    );
    final id = await _db.insertArtist(artist);
    await loadArtists();
    return await _db.getArtistById(id);
  }
  
  Future<void> updateArtist(Artist artist) async {
    await _db.updateArtist(artist);
    await loadArtists();
  }
  
  Future<void> deleteArtist(int id) async {
    await _db.deleteArtist(id);
    await loadArtists();
  }
  
  Future<Artist?> getArtistById(int id) async {
    return await _db.getArtistById(id);
  }
  
  Future<List<Artist>> getFollowingArtists() async {
    return await _db.getFollowingArtists();
  }
  
  Future<bool> isFollowing(int artistId) async {
    return await _db.isFollowing(artistId);
  }
  
  Future<void> followArtist(int artistId) async {
    await _db.addFollowing(artistId);
    notifyListeners();
  }
  
  Future<void> unfollowArtist(int artistId) async {
    await _db.removeFollowing(artistId);
    notifyListeners();
  }
}