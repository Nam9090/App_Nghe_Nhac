import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/song_provider.dart';
import '../providers/audio_provider.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../models/song.dart';
import '../models/artist.dart';
import 'player_screen.dart';

class ArtistDetailScreen extends StatefulWidget {
  final Artist artist;
  
  const ArtistDetailScreen({super.key, required this.artist});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  List<Song> _songs = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  int _followerCount = 0;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _checkFollowing();
    _loadFollowerCount();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    _songs = await _db.getSongsByArtist(widget.artist.id!);
    _songs.sort((a, b) => b.playCount.compareTo(a.playCount));
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _checkFollowing() async {
    final isFollowing = await _db.isFollowing(widget.artist.id!);
    setState(() {
      _isFollowing = isFollowing;
    });
  }
  
  Future<void> _loadFollowerCount() async {
    final count = await _db.getFollowerCount(widget.artist.id!);
    setState(() {
      _followerCount = count;
    });
  }
  
  Future<void> _toggleFollow() async {
    if (_isFollowing) {
      await _db.removeFollowing(widget.artist.id!);
      setState(() {
        _isFollowing = false;
        _followerCount--;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unfollowed ${widget.artist.name}'),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      await _db.addFollowing(widget.artist.id!);
      setState(() {
        _isFollowing = true;
        _followerCount++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Following ${widget.artist.name}'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
  
  String _formatPlayCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
  
  String _formatFollowerCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: AppColors.background,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                            AppColors.background,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    // Artist avatar
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: widget.artist.avatar != null && File(widget.artist.avatar!).existsSync()
                              ? FileImage(File(widget.artist.avatar!))
                              : null,
                          child: widget.artist.avatar == null || !File(widget.artist.avatar!).existsSync()
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  // Artist name
                  Text(
                    widget.artist.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Follower count
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatFollowerCount(_followerCount)} người nghe hàng tháng',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Follow button
                  SizedBox(
                    width: 140,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing ? Colors.transparent : AppColors.primary,
                        foregroundColor: _isFollowing ? AppColors.onSurface : Colors.black,
                        side: _isFollowing
                            ? const BorderSide(color: AppColors.primary)
                            : BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isFollowing ? Icons.check : Icons.person_add,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isFollowing ? 'ĐANG THEO DÕI' : 'THEO DÕI',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.outline.withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.onSurfaceVariant,
                      tabs: const [
                        Tab(text: 'PHỔ BIẾN'),
                        Tab(text: 'TẤT CẢ'),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Popular Songs
            _buildPopularSongs(),
            // All Songs
            _buildAllSongs(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPopularSongs() {
    final popularSongs = _songs.take(10).toList();
    
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : popularSongs.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No tracks from this artist yet',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: popularSongs.length,
                itemBuilder: (context, index) {
                  final song = popularSongs[index];
                  return _buildSongTile(song, index + 1);
                },
              );
  }
  
  Widget _buildAllSongs() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _songs.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No tracks from this artist yet',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  final song = _songs[index];
                  return _buildSongTile(song, index + 1);
                },
              );
  }
  
  Widget _buildSongTile(Song song, int rank) {
    return GestureDetector(
      onTap: () {
        final audioProvider = Provider.of<AudioProvider>(context, listen: false);
        audioProvider.playSong(song);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlayerScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Rank
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: rank <= 3
                    ? LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      )
                    : null,
                color: rank > 3 ? AppColors.surfaceContainerHigh : null,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: rank <= 3 ? Colors.black : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Cover Art
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 48,
                height: 48,
                color: AppColors.primary.withOpacity(0.3),
                child: song.coverArt != null && File(song.coverArt!).existsSync()
                    ? Image.file(
                        File(song.coverArt!),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.music_note,
                          size: 24,
                          color: AppColors.onSurfaceVariant,
                        ),
                      )
                    : const Icon(
                        Icons.music_note,
                        size: 24,
                        color: AppColors.onSurfaceVariant,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        size: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatPlayCount(song.playCount)} plays',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.timer_outlined,
                        size: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Helpers.formatDuration(Duration(seconds: song.duration)),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Play button
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  final audioProvider = Provider.of<AudioProvider>(context, listen: false);
                  audioProvider.playSong(song);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlayerScreen()),
                  );
                },
                icon: const Icon(
                  Icons.play_arrow,
                  color: Colors.black,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}