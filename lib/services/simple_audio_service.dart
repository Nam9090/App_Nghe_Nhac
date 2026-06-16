import 'dart:io';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../database/database_helper.dart';

class SimpleAudioService {
  static final SimpleAudioService _instance = SimpleAudioService._internal();
  factory SimpleAudioService() => _instance;
  SimpleAudioService._internal();
  
  final AudioPlayer _player = AudioPlayer();
  final DatabaseHelper _db = DatabaseHelper();
  
  List<Song> _currentQueue = [];
  Song? _currentSong;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  LoopMode _loopMode = LoopMode.off;
  
  AudioPlayer get player => _player;
  List<Song> get currentQueue => _currentQueue;
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  
  void init() {
    _player.positionStream.listen((position) {
      _currentPosition = position;
    });
    
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _totalDuration = _player.duration ?? Duration.zero;
    });
  }
  
  Future<void> playSong(Song song, {List<Song>? queue, int index = 0}) async {
    _currentQueue = queue ?? [song];
    _currentSong = song;
    
    await _player.setAudioSource(AudioSource.uri(Uri.file(song.filePath)));
    await _player.play();
    _isPlaying = true;
    
    await _db.incrementPlayCount(song.id!);
    await _db.addToHistory(song.id!);
  }
  
  Future<void> playPlaylist(List<Song> playlist, {int startIndex = 0}) async {
    if (playlist.isEmpty) return;
    await playSong(playlist[startIndex], queue: playlist, index: startIndex);
  }
  
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
      _isPlaying = false;
    } else {
      await _player.play();
      _isPlaying = true;
    }
  }
  
  Future<void> next() async {
    final currentIndex = _currentQueue.indexWhere((s) => s.id == _currentSong?.id);
    if (currentIndex + 1 < _currentQueue.length) {
      final nextSong = _currentQueue[currentIndex + 1];
      await playSong(nextSong, queue: _currentQueue);
    } else if (_loopMode == LoopMode.all) {
      await playSong(_currentQueue.first, queue: _currentQueue);
    }
  }
  
  Future<void> previous() async {
    final currentIndex = _currentQueue.indexWhere((s) => s.id == _currentSong?.id);
    if (currentIndex - 1 >= 0) {
      final prevSong = _currentQueue[currentIndex - 1];
      await playSong(prevSong, queue: _currentQueue);
    }
  }
  
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }
  
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
  }
  
  Future<void> addToQueue(Song song) async {
    _currentQueue.add(song);
  }
  
  Future<void> removeFromQueue(int songId) async {
    _currentQueue.removeWhere((s) => s.id == songId);
    if (_currentSong?.id == songId && _currentQueue.isNotEmpty) {
      await playSong(_currentQueue.first);
    } else if (_currentQueue.isEmpty) {
      await stop();
    }
  }
  
  Future<void> skipToIndex(int index) async {
    if (index >= 0 && index < _currentQueue.length) {
      await playSong(_currentQueue[index], queue: _currentQueue, index: index);
    }
  }
  
  Future<void> updateQueue(List<Song> newQueue) async {
    _currentQueue = newQueue;
  }
  
  Future<void> setRepeatMode(int mode) async {
    switch (mode) {
      case 1: // one
        _loopMode = LoopMode.one;
        await _player.setLoopMode(LoopMode.one);
        break;
      case 2: // all
        _loopMode = LoopMode.all;
        await _player.setLoopMode(LoopMode.all);
        break;
      default: // none
        _loopMode = LoopMode.off;
        await _player.setLoopMode(LoopMode.off);
    }
  }
  
  void dispose() {
    _player.dispose();
  }
  
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}