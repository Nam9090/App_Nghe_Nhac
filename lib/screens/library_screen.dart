import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/song_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/audio_provider.dart';
import '../database/database_helper.dart';
import '../services/file_storage_service.dart';
import '../widgets/track_card.dart';
import '../utils/constants.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../models/artist.dart';
import 'player_screen.dart';
import 'artist_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: const Text(
                'LIBRARY',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(32),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(32),
                ),
                labelColor: Colors.black,
                unselectedLabelColor: AppColors.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                tabs: const [
                  Tab(text: 'LIKED'),
                  Tab(text: 'PLAYLISTS'),
                  Tab(text: 'UPLOADS'),
                  Tab(text: 'FOLLOWING'),
                ],
              ),
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _LikedTabs(),
                  _PlaylistsTab(),
                  _UploadsTab(),
                  _FollowingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LikedTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SongProvider>(
      builder: (context, provider, child) {
        final likedSongs = provider.favoriteSongs;
        
        if (likedSongs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 48, color: AppColors.onSurfaceVariant),
                SizedBox(height: 12),
                Text(
                  'No liked songs yet',
                  style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: likedSongs.length,
          itemBuilder: (context, index) {
            final song = likedSongs[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TrackCard(
                song: song,
                onTap: () {
                  _playSong(context, song, likedSongs);
                },
                onPlay: () {
                  _playSong(context, song, likedSongs);
                },
                onFavorite: () {
                  provider.toggleFavorite(song.id!);
                },
              ),
            );
          },
        );
      },
    );
  }
  
  void _playSong(BuildContext context, Song song, List<Song> queue) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    audioProvider.playSong(song, queue: queue);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlayerScreen()),
    );
  }
}

class _PlaylistsTab extends StatefulWidget {
  @override
  State<_PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<_PlaylistsTab> {
  final FileStorageService _fileStorage = FileStorageService();
  
  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showCreatePlaylistDialog(context);
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('CREATE PLAYLIST'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
            
            Expanded(
              child: provider.playlists.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.playlist_play, size: 48, color: AppColors.onSurfaceVariant),
                          SizedBox(height: 12),
                          Text(
                            'No playlists yet',
                            style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Create your first playlist',
                            style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: provider.playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = provider.playlists[index];
                        return FutureBuilder<List<Song>>(
                          future: provider.getPlaylistSongs(playlist.id!),
                          builder: (context, snapshot) {
                            final songCount = snapshot.data?.length ?? 0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: AppColors.cardGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      child: playlist.coverArt != null && File(playlist.coverArt!).existsSync()
                                          ? Image.file(
                                              File(playlist.coverArt!),
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    AppColors.primary.withOpacity(0.3),
                                                    AppColors.secondary.withOpacity(0.3),
                                                  ],
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.playlist_play,
                                                color: AppColors.primary,
                                                size: 24,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          playlist.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$songCount ${songCount == 1 ? 'track' : 'tracks'}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _showDeletePlaylistDialog(context, playlist);
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppColors.error,
                                      size: 18,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
  
  void _showCreatePlaylistDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    File? _selectedImage;
    bool _isCreating = false;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Create Playlist',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.onSurface,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (image != null) {
                        setState(() {
                          _selectedImage = File(image.path);
                        });
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.outline.withOpacity(0.3),
                        ),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 120,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 32,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Add cover image',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: AppColors.onSurface, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Playlist name',
                      hintStyle: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('CANCEL', style: TextStyle(fontSize: 12)),
                ),
                ElevatedButton(
                  onPressed: _isCreating
                      ? null
                      : () async {
                          if (controller.text.isNotEmpty) {
                            setState(() {
                              _isCreating = true;
                            });
                            
                            String? savedImagePath;
                            if (_selectedImage != null) {
                              savedImagePath = await _fileStorage.saveImageFile(_selectedImage!);
                            }
                            
                            final playlistProvider = Provider.of<PlaylistProvider>(
                              context,
                              listen: false,
                            );
                            await playlistProvider.createPlaylist(
                              controller.text,
                              coverArt: savedImagePath,
                            );
                            
                            if (mounted) {
                              setState(() {
                                _isCreating = false;
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Playlist created!'),
                                  backgroundColor: AppColors.primary,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('CREATE', style: TextStyle(fontSize: 12)),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showDeletePlaylistDialog(BuildContext context, Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerHigh,
          title: const Text('Delete Playlist', style: TextStyle(fontSize: 16)),
          content: Text(
            'Delete "${playlist.name}"?',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted) Navigator.pop(context);
              },
              child: const Text('CANCEL', style: TextStyle(fontSize: 12)),
            ),
            TextButton(
              onPressed: () async {
                final playlistProvider = Provider.of<PlaylistProvider>(
                  context,
                  listen: false,
                );
                await playlistProvider.deletePlaylist(playlist.id!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Playlist deleted'),
                      backgroundColor: AppColors.error,
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: const Text('DELETE', style: TextStyle(color: AppColors.error, fontSize: 12)),
            ),
          ],
        );
      },
    );
  }
}

class _UploadsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SongProvider>(
      builder: (context, provider, child) {
        final songs = provider.songs;
        
        if (songs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload, size: 48, color: AppColors.onSurfaceVariant),
                SizedBox(height: 12),
                Text(
                  'No uploaded songs',
                  style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
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
              padding: const EdgeInsets.only(bottom: 8),
              child: TrackCard(
                song: song,
                onTap: () {
                  _playSong(context, song, songs);
                },
                onPlay: () {
                  _playSong(context, song, songs);
                },
                onFavorite: () {
                  provider.toggleFavorite(song.id!);
                },
              ),
            );
          },
        );
      },
    );
  }
  
  void _playSong(BuildContext context, Song song, List<Song> queue) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    audioProvider.playSong(song, queue: queue);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlayerScreen()),
    );
  }
}

class _FollowingTab extends StatefulWidget {
  @override
  State<_FollowingTab> createState() => _FollowingTabState();
}

class _FollowingTabState extends State<_FollowingTab> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Artist> _following = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }
  
  Future<void> _loadFollowing() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    _following = await _db.getFollowingArtists();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _unfollow(Artist artist) async {
    await _db.removeFollowing(artist.id!);
    if (mounted) {
      await _loadFollowing();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unfollowed ${artist.name}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_following.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 48, color: AppColors.onSurfaceVariant),
            SizedBox(height: 12),
            Text(
              'No artists followed yet',
              style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _following.length,
      itemBuilder: (context, index) {
        final artist = _following[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: artist.avatar != null && File(artist.avatar!).existsSync()
                      ? Image.file(
                          File(artist.avatar!),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArtistDetailScreen(artist: artist),
                      ),
                    );
                  },
                  child: Text(
                    artist.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () => _unfollow(artist),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 10),
                ),
                child: const Text('UNFOLLOW'),
              ),
            ],
          ),
        );
      },
    );
  }
}