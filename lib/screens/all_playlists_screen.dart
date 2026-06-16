import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/song_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/track_card.dart';
import '../utils/constants.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'player_screen.dart';

class AllPlaylistsScreen extends StatefulWidget {
  const AllPlaylistsScreen({super.key});

  @override
  State<AllPlaylistsScreen> createState() => _AllPlaylistsScreenState();
}

class _AllPlaylistsScreenState extends State<AllPlaylistsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'All Playlists',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.playlists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_play, size: 64, color: AppColors.onSurfaceVariant),
                  const SizedBox(height: 16),
                  const Text(
                    'No playlists yet',
                    style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first playlist in Library',
                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }
          
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: provider.playlists.length,
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
                      decoration: BoxDecoration(
                        gradient: AppColors.cardGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                image: playlist.coverArt != null && File(playlist.coverArt!).existsSync()
                                    ? DecorationImage(
                                        image: FileImage(File(playlist.coverArt!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: playlist.coverArt == null || !File(playlist.coverArt!).existsSync()
                                  ? Center(
                                      child: Icon(
                                        Icons.playlist_play,
                                        size: 48,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playlist.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$songCount ${songCount == 1 ? 'track' : 'tracks'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// PlaylistDetailScreen - Định nghĩa tại đây với đầy đủ import
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