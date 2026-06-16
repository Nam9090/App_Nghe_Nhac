import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';
import '../models/song.dart';
import '../models/artist.dart';

class WrappedScreen extends StatefulWidget {
  const WrappedScreen({super.key});

  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<Song> _topSongs = [];
  List<Artist> _topArtists = [];
  List<String> _topGenres = [];
  int _totalPlays = 0;
  int _totalMinutes = 0;
  String _topTimeOfDay = '';
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _loadWrappedData();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadWrappedData() async {
    setState(() {
      _isLoading = true;
    });
    
    final listeningHistory = await _db.getListeningHistory(limit: 1000);
    
    _totalPlays = listeningHistory.length;
    _totalMinutes = listeningHistory.fold(0, (sum, song) => sum + (song.duration ~/ 60));
    
    // Top bài hát
    final songPlayCount = <int, int>{};
    for (var song in listeningHistory) {
      songPlayCount[song.id!] = (songPlayCount[song.id!] ?? 0) + 1;
    }
    final topSongIds = songPlayCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    _topSongs = [];
    for (var entry in topSongIds.take(5)) {
      final song = await _db.getSongById(entry.key);
      if (song != null) {
        _topSongs.add(song);
      }
    }
    
    // Top nghệ sĩ
    final artistPlayCount = <int, int>{};
    for (var song in listeningHistory) {
      if (song.artistId != null) {
        artistPlayCount[song.artistId!] = (artistPlayCount[song.artistId!] ?? 0) + 1;
      }
    }
    final topArtistIds = artistPlayCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    _topArtists = [];
    for (var entry in topArtistIds.take(5)) {
      final artist = await _db.getArtistById(entry.key);
      if (artist != null) {
        _topArtists.add(artist);
      }
    }
    
    // Top thể loại - SỬA LỖI Ở ĐÂY
    final genrePlayCount = <String, int>{};
    for (var song in listeningHistory) {
      genrePlayCount[song.genre] = (genrePlayCount[song.genre] ?? 0) + 1;
    }
    final sortedGenres = genrePlayCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    _topGenres = [];
    for (var entry in sortedGenres.take(5)) {
      _topGenres.add(entry.key);
    }
    
    // Thời gian nghe nhiều nhất
    final hourCount = List.filled(24, 0);
    for (var song in listeningHistory) {
      final hour = DateTime.fromMillisecondsSinceEpoch(song.uploadDate.millisecondsSinceEpoch).hour;
      hourCount[hour]++;
    }
    final topHour = hourCount.indexOf(hourCount.reduce((a, b) => a > b ? a : b));
    _topTimeOfDay = _getTimeOfDayName(topHour);
    
    setState(() {
      _isLoading = false;
    });
  }
  
  String _getTimeOfDayName(int hour) {
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 21) return 'Evening';
    return 'Night';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 200,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      flexibleSpace: FlexibleSpaceBar(
                        title: const Text(
                          'Your Year in Music',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.celebration,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      leading: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: AppColors.cardGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _StatCard(
                                      icon: Icons.play_circle,
                                      value: '$_totalPlays',
                                      label: 'Total Plays',
                                    ),
                                    _StatCard(
                                      icon: Icons.timer,
                                      value: '${_totalMinutes ~/ 60}h ${_totalMinutes % 60}m',
                                      label: 'Listening Time',
                                    ),
                                    _StatCard(
                                      icon: Icons.wb_twilight,
                                      value: _topTimeOfDay,
                                      label: 'Favorite Time',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          const Text(
                            '🎵 Top Songs',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._topSongs.asMap().entries.map((entry) {
                            final index = entry.key;
                            final song = entry.value;
                            return _RankCard(
                              rank: index + 1,
                              title: song.title,
                              subtitle: song.artistName,
                              coverArt: song.coverArt,
                            );
                          }),
                          const SizedBox(height: 24),
                          
                          const Text(
                            '🎤 Top Artists',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._topArtists.asMap().entries.map((entry) {
                            final index = entry.key;
                            final artist = entry.value;
                            return _RankCard(
                              rank: index + 1,
                              title: artist.name,
                              subtitle: artist.bio?.substring(0, 50) ?? 'Artist',
                              coverArt: artist.avatar,
                              isArtist: true,
                            );
                          }),
                          const SizedBox(height: 24),
                          
                          const Text(
                            '🎧 Top Genres',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _topGenres.map((genre) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: AppColors.cardGradient,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  genre,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 40),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RankCard extends StatelessWidget {
  final int rank;
  final String title;
  final String subtitle;
  final String? coverArt;
  final bool isArtist;
  
  const _RankCard({
    required this.rank,
    required this.title,
    required this.subtitle,
    this.coverArt,
    this.isArtist = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: rank <= 3
                  ? LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    )
                  : null,
              color: rank > 3 ? AppColors.surfaceContainerHigh : null,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.black : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 48,
              height: 48,
              color: AppColors.primary.withOpacity(0.3),
              child: coverArt != null && File(coverArt!).existsSync()
                  ? Image.file(
                      File(coverArt!),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        isArtist ? Icons.person : Icons.music_note,
                        color: AppColors.onSurfaceVariant,
                      ),
                    )
                  : Icon(
                      isArtist ? Icons.person : Icons.music_note,
                      color: AppColors.onSurfaceVariant,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}