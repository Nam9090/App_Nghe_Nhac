import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/song_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/track_card.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../services/daily_mix_service.dart';
import 'player_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'trending_screen.dart';
import 'all_playlists_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                  'FOR YOU',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: AppColors.onSurface,
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.cardGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_outlined,
                        size: 20,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.cardGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        size: 20,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildWelcomeBanner(),
                    const SizedBox(height: 20),
                    
                    // Recommended Section
                    const Text(
                      '🔥 Recommended',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<SongProvider>(
                      builder: (context, provider, child) {
                        if (provider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (provider.songs.isEmpty) {
                          return _EmptyState(
                            message: 'No songs yet',
                            buttonText: 'Upload your first track',
                            onPressed: () {},
                          );
                        }
                        return SizedBox(
                          height: 160,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: provider.songs.take(5).length,
                            itemBuilder: (context, index) {
                              final song = provider.songs[index];
                              return GestureDetector(
                                onTap: () {
                                  final audioProvider = Provider.of<AudioProvider>(
                                    context,
                                    listen: false,
                                  );
                                  audioProvider.playSong(song);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const PlayerScreen()),
                                  );
                                },
                                child: Container(
                                  width: 130,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          height: 110,
                                          width: 130,
                                          color: AppColors.primary.withOpacity(0.3),
                                          child: _buildCoverArt(song),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        song.title,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        song.artistName,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.primaryLight,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Daily Mix Section
                    const Text(
                      '🎧 Daily Mix',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<Song>>(
                      future: DailyMixService().generateDailyMix(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError || snapshot.data?.isEmpty == true) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Listen to more music to get your Daily Mix',
                              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                            ),
                          );
                        }
                        final dailyMix = snapshot.data!;
                        return SizedBox(
                          height: 160,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: dailyMix.take(5).length,
                            itemBuilder: (context, index) {
                              final song = dailyMix[index];
                              return GestureDetector(
                                onTap: () {
                                  final audioProvider = Provider.of<AudioProvider>(
                                    context,
                                    listen: false,
                                  );
                                  audioProvider.playSong(song);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const PlayerScreen()),
                                  );
                                },
                                child: Container(
                                  width: 130,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          height: 110,
                                          width: 130,
                                          color: AppColors.primary.withOpacity(0.3),
                                          child: _buildCoverArt(song),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        song.title,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        song.artistName,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.primaryLight,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Playlists Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📀 Your Playlists',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const Text(
                              'Your collections',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AllPlaylistsScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppColors.cardGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'VIEW ALL',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Consumer<PlaylistProvider>(
                      builder: (context, provider, child) {
                        if (provider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (provider.playlists.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No playlists yet',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        return SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: provider.playlists.take(5).length,
                            itemBuilder: (context, index) {
                              final playlist = provider.playlists[index];
                              return FutureBuilder<List<Song>>(
                                future: provider.getPlaylistSongs(playlist.id!),
                                builder: (context, snapshot) {
                                  final songCount = snapshot.data?.length ?? 0;
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PlaylistDetailScreen(playlist: playlist),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 80,
                                      margin: const EdgeInsets.only(right: 12),
                                      child: Column(
                                        children: [
                                          Container(
                                            height: 60,
                                            width: 80,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              image: playlist.coverArt != null && File(playlist.coverArt!).existsSync()
                                                  ? DecorationImage(
                                                      image: FileImage(File(playlist.coverArt!)),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            child: playlist.coverArt == null || !File(playlist.coverArt!).existsSync()
                                                ? Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          AppColors.primary.withOpacity(0.3),
                                                          AppColors.secondary.withOpacity(0.3),
                                                        ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.playlist_play,
                                                        size: 24,
                                                        color: AppColors.primary,
                                                      ),
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            playlist.name,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '$songCount ${songCount == 1 ? 'track' : 'tracks'}',
                                            style: const TextStyle(
                                              fontSize: 8,
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Trending Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '📈 Trending Charts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TrendingScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppColors.cardGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'VIEW ALL',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Consumer<SongProvider>(
                      builder: (context, provider, child) {
                        if (provider.trendingSongs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No trending tracks yet',
                                style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: List.generate(
                            provider.trendingSongs.take(5).length,
                            (index) {
                              final song = provider.trendingSongs[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: TrackCard(
                                  song: song,
                                  onTap: () {
                                    _playSong(context, song, provider.trendingSongs, index);
                                  },
                                  onPlay: () {
                                    _playSong(context, song, provider.trendingSongs, index);
                                  },
                                  onFavorite: () {
                                    provider.toggleFavorite(song.id!);
                                  },
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 30),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎵 Good Morning!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Discover new music today',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.headphones,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCoverArt(Song song) {
    if (song.coverArt != null && File(song.coverArt!).existsSync()) {
      return Image.file(
        File(song.coverArt!),
        width: 130,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.album,
          size: 36,
          color: AppColors.onSurfaceVariant,
        ),
      );
    }
    return const Icon(
      Icons.album,
      size: 36,
      color: AppColors.onSurfaceVariant,
    );
  }
  
  void _playSong(BuildContext context, Song song, List<Song> queue, int index) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    audioProvider.playSong(song, queue: queue, index: index);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlayerScreen()),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final String buttonText;
  final VoidCallback onPressed;
  
  const _EmptyState({
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.music_note_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// PlaylistDetailScreen
class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;
  
  const PlaylistDetailScreen({super.key, required this.playlist});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(playlist.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: FutureBuilder<List<Song>>(
        future: Provider.of<PlaylistProvider>(context, listen: false)
            .getPlaylistSongs(playlist.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final songs = snapshot.data ?? [];
          
          if (songs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_play, size: 64, color: AppColors.onSurfaceVariant),
                  const SizedBox(height: 16),
                  const Text(
                    'No songs in this playlist',
                    style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add songs from the player screen',
                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TrackCard(
                  song: song,
                  onTap: () {
                    final audioProvider = Provider.of<AudioProvider>(
                      context,
                      listen: false,
                    );
                    audioProvider.playSong(song, queue: songs, index: index);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlayerScreen()),
                    );
                  },
                  onPlay: () {
                    final audioProvider = Provider.of<AudioProvider>(
                      context,
                      listen: false,
                    );
                    audioProvider.playSong(song, queue: songs, index: index);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlayerScreen()),
                    );
                  },
                  onFavorite: () {
                    final songProvider = Provider.of<SongProvider>(
                      context,
                      listen: false,
                    );
                    songProvider.toggleFavorite(song.id!);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}