import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/song_provider.dart';
import '../providers/playlist_provider.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../models/artist.dart';
import 'comments_screen.dart';
import 'artist_detail_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _waveAnimationController;
  
  @override
  void initState() {
    super.initState();
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _waveAnimationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer2<AudioProvider, SongProvider>(
      builder: (context, audioProvider, songProvider, child) {
        final song = audioProvider.currentSong;
        
        if (song == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(
              child: Text(
                'No song playing',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
          );
        }
        
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_downward, color: AppColors.onSurface),
                      ),
                      const Text(
                        'NOW PLAYING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_horiz, color: AppColors.onSurface),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(24),
                          width: MediaQuery.of(context).size.width - 80,
                          height: MediaQuery.of(context).size.width - 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: _buildAlbumArt(song),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Text(
                                song.title.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  if (song.artistId != null) {
                                    final db = DatabaseHelper();
                                    final artist = await db.getArtistById(song.artistId!);
                                    if (artist != null && context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ArtistDetailScreen(artist: artist),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  song.artistName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildWaveformVisualizer(audioProvider),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Slider(
                                value: audioProvider.progress.clamp(0.0, 1.0),
                                onChanged: (value) {
                                  final position = Duration(
                                    milliseconds: (value * audioProvider.totalDuration.inMilliseconds).toInt(),
                                  );
                                  audioProvider.seek(position);
                                },
                                activeColor: AppColors.primary,
                                inactiveColor: AppColors.surfaceContainerHighest,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      audioProvider.formatDuration(audioProvider.currentPosition),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      audioProvider.formatDuration(audioProvider.totalDuration),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () => audioProvider.toggleShuffle(),
                                icon: Icon(
                                  Icons.shuffle,
                                  color: audioProvider.isShuffled
                                      ? AppColors.primary
                                      : AppColors.onSurfaceVariant,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surfaceContainerHigh,
                                ),
                                child: IconButton(
                                  onPressed: () => audioProvider.previous(),
                                  icon: const Icon(
                                    Icons.skip_previous,
                                    color: AppColors.onSurface,
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              GestureDetector(
                                onTap: () => audioProvider.togglePlayPause(),
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primaryLight,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.4),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    audioProvider.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.black,
                                    size: 40,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surfaceContainerHigh,
                                ),
                                child: IconButton(
                                  onPressed: () => audioProvider.next(),
                                  icon: const Icon(
                                    Icons.skip_next,
                                    color: AppColors.onSurface,
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                onPressed: () => audioProvider.toggleRepeat(),
                                icon: _buildRepeatIcon(audioProvider.repeatMode),
                                iconSize: 28,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(
                                icon: song.isFavorite ? Icons.favorite : Icons.favorite_border,
                                label: song.isFavorite ? 'LIKED' : 'LIKE',
                                isActive: song.isFavorite,
                                onTap: () {
                                  songProvider.toggleFavorite(song.id!);
                                },
                              ),
                              _buildActionButton(
                                icon: Icons.add_comment_outlined,
                                label: 'COMMENT',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CommentsScreen(song: song),
                                    ),
                                  );
                                },
                              ),
                              _buildActionButton(
                                icon: Icons.download_outlined,
                                label: 'DOWNLOAD',
                                onTap: () async {
                                  final db = DatabaseHelper();
                                  final isDownloaded = await db.isSongDownloaded(song.id!);
                                  if (!isDownloaded) {
                                    await db.addDownload(song.id!, song.filePath);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Downloaded successfully'),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Already downloaded'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                },
                              ),
                              _buildActionButton(
                                icon: Icons.person_add_outlined,
                                label: 'FOLLOW',
                                onTap: () async {
                                  final db = DatabaseHelper();
                                  if (song.artistId != null) {
                                    final artist = await db.getArtistById(song.artistId!);
                                    if (artist != null) {
                                      final isFollowing = await db.isFollowing(artist.id!);
                                      if (!isFollowing) {
                                        await db.addFollowing(artist.id!);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Following ${artist.name}'),
                                            backgroundColor: AppColors.primary,
                                          ),
                                        );
                                      } else {
                                        await db.removeFollowing(artist.id!);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Unfollowed ${artist.name}'),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                      }
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Artist not found'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                },
                              ),
                              _buildActionButton(
                                icon: Icons.playlist_add,
                                label: 'ADD',
                                onTap: () {
                                  _showAddToPlaylistDialog(context, song);
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        _buildUpNextSection(audioProvider),
                        
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAlbumArt(Song song) {
    if (song.coverArt != null && File(song.coverArt!).existsSync()) {
      return Image.file(
        File(song.coverArt!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.primary.withOpacity(0.3),
          child: const Icon(
            Icons.album,
            size: 80,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }
    return Container(
      color: AppColors.primary.withOpacity(0.3),
      child: const Icon(
        Icons.album,
        size: 80,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
  
  Widget _buildWaveformVisualizer(AudioProvider audioProvider) {
    final bars = List.generate(30, (index) {
      final height = audioProvider.isPlaying
          ? 20 + (index % 10) * 3
          : 10;
      return Container(
        width: 3,
        height: height.toDouble(),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: audioProvider.currentPosition.inSeconds > index * 2
              ? AppColors.primary
              : AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    });
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: bars,
    );
  }
  
  Widget _buildRepeatIcon(int mode) {
    switch (mode) {
      case 1:
        return const Icon(Icons.repeat_one, color: AppColors.primary);
      case 2:
        return const Icon(Icons.repeat, color: AppColors.primary);
      default:
        return const Icon(Icons.repeat, color: AppColors.onSurfaceVariant);
    }
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(
            icon,
            color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
            size: 28,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  
  Widget _buildUpNextSection(AudioProvider audioProvider) {
    final queue = audioProvider.currentQueue;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'UP NEXT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'QUEUE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: queue.length,
          itemBuilder: (context, index) {
            final song = queue[index];
            final isCurrent = audioProvider.currentSong?.id == song.id;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isCurrent
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 40,
                      height: 40,
                      color: AppColors.primary.withOpacity(0.3),
                      child: _buildQueueCoverArt(song),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? AppColors.primary : AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song.artistName,
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
                  Text(
                    Helpers.formatDuration(Duration(seconds: song.duration)),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildQueueCoverArt(Song song) {
    if (song.coverArt != null && File(song.coverArt!).existsSync()) {
      return Image.file(
        File(song.coverArt!),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.music_note,
          size: 20,
          color: AppColors.onSurfaceVariant,
        ),
      );
    }
    return const Icon(
      Icons.music_note,
      size: 20,
      color: AppColors.onSurfaceVariant,
    );
  }
  
  Future<List<Playlist>> _getPlaylists(PlaylistProvider provider) async {
    await provider.loadPlaylists();
    return provider.playlists;
  }
  
  void _showAddToPlaylistDialog(BuildContext context, Song song) {
    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.onSurfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Add to Playlist',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: FutureBuilder<List<Playlist>>(
                      future: _getPlaylists(playlistProvider),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: AppColors.error),
                            ),
                          );
                        }
                        final playlists = snapshot.data ?? [];
                        if (playlists.isEmpty) {
                          return const Center(
                            child: Text(
                              'No playlists yet.\nCreate one!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.onSurfaceVariant),
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = playlists[index];
                            return ListTile(
                              leading: const Icon(Icons.playlist_play, color: AppColors.primary),
                              title: Text(
                                playlist.name,
                                style: const TextStyle(color: AppColors.onSurface),
                              ),
                              trailing: const Icon(Icons.add, color: AppColors.primary),
                              onTap: () async {
                                final songs = await playlistProvider.getPlaylistSongs(playlist.id!);
                                await playlistProvider.addSongToPlaylist(
                                  playlist.id!,
                                  song.id!,
                                  songs.length,
                                );
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added to "${playlist.name}"'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showCreatePlaylistDialog(context, song);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text('+ CREATE NEW PLAYLIST'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  void _showCreatePlaylistDialog(BuildContext context, Song song) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerHigh,
          title: const Text(
            'Create Playlist',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: 'Playlist name',
              hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final playlistProvider = Provider.of<PlaylistProvider>(
                    context,
                    listen: false,
                  );
                  await playlistProvider.createPlaylist(controller.text);
                  Navigator.pop(context);
                  _showAddToPlaylistDialog(context, song);
                }
              },
              child: const Text('CREATE'),
            ),
          ],
        );
      },
    );
  }
}