import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/simple_audio_service.dart';

class AudioProvider extends ChangeNotifier {
  final SimpleAudioService _audioService = SimpleAudioService();
  
  List<Song> _originalQueue = [];
  bool _isShuffled = false;
  int _repeatMode = 0; // 0: none, 1: one, 2: all
  
  List<Song> get currentQueue => _audioService.currentQueue;
  Song? get currentSong => _audioService.currentSong;
  bool get isPlaying => _audioService.isPlaying;
  Duration get currentPosition => _audioService.currentPosition;
  Duration get totalDuration => _audioService.totalDuration;
  bool get isShuffled => _isShuffled;
  int get repeatMode => _repeatMode;
  double get progress => totalDuration.inMilliseconds > 0
      ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
      : 0;
  
  AudioProvider() {
    _audioService.init();
    _audioService.playerStateStream.listen((_) {
      notifyListeners();
    });
    _audioService.positionStream.listen((_) {
      notifyListeners();
    });
  }
  
  Future<void> playSong(Song song, {List<Song>? queue, int index = 0}) async {
    final playQueue = queue ?? [song];
    _originalQueue = List.from(playQueue);
    _isShuffled = false;
    await _audioService.playSong(song, queue: playQueue, index: index);
    notifyListeners();
  }
  
  Future<void> playPlaylist(List<Song> playlist, {int startIndex = 0}) async {
    if (playlist.isEmpty) return;
    _originalQueue = List.from(playlist);
    _isShuffled = false;
    await playSong(playlist[startIndex], queue: playlist, index: startIndex);
  }
  
  // Shuffle Mode
  Future<void> toggleShuffle() async {
    if (_isShuffled) {
      // Khôi phục queue gốc
      await _audioService.updateQueue(_originalQueue);
      final currentIndex = _originalQueue.indexWhere((s) => s.id == currentSong?.id);
      if (currentIndex != -1) {
        await _audioService.seek(Duration.zero);
        await _audioService.skipToIndex(currentIndex);
      }
      _isShuffled = false;
    } else {
      // Tạo queue ngẫu nhiên
      final shuffledQueue = List<Song>.from(_audioService.currentQueue);
      shuffledQueue.shuffle();
      final currentSongId = currentSong?.id;
      if (currentSongId != null) {
        final newIndex = shuffledQueue.indexWhere((s) => s.id == currentSongId);
        if (newIndex != -1 && newIndex != 0) {
          final temp = shuffledQueue[0];
          shuffledQueue[0] = shuffledQueue[newIndex];
          shuffledQueue[newIndex] = temp;
        }
      }
      await _audioService.updateQueue(shuffledQueue);
      _isShuffled = true;
    }
    notifyListeners();
  }
  
  // Repeat Mode
  Future<void> toggleRepeat() async {
    _repeatMode = (_repeatMode + 1) % 3;
    await _audioService.setRepeatMode(_repeatMode);
    notifyListeners();
  }
  
  Future<void> togglePlayPause() async {
    await _audioService.togglePlayPause();
    notifyListeners();
  }
  
  Future<void> next() async {
    await _audioService.next();
    notifyListeners();
  }
  
  Future<void> previous() async {
    await _audioService.previous();
    notifyListeners();
  }
  
  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
    notifyListeners();
  }
  
  Future<void> stop() async {
    await _audioService.stop();
    notifyListeners();
  }
  
  Future<void> addToQueue(Song song) async {
    _originalQueue.add(song);
    await _audioService.addToQueue(song);
    notifyListeners();
  }
  
  Future<void> removeFromQueue(int songId) async {
    _originalQueue.removeWhere((s) => s.id == songId);
    await _audioService.removeFromQueue(songId);
    notifyListeners();
  }
  
  String formatDuration(Duration duration) {
    return _audioService.formatDuration(duration);
  }
  
  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}