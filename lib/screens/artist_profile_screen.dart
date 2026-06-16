import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/song_provider.dart';
import '../providers/audio_provider.dart';
import '../database/database_helper.dart';
import '../widgets/track_card.dart';
import '../utils/constants.dart';
import '../models/song.dart';
import '../models/artist.dart';
import 'player_screen.dart';

class ArtistProfileScreen extends StatefulWidget {
  final Artist artist;
  
  const ArtistProfileScreen({super.key, required this.artist});

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Song> _songs = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
    _checkFollowing();
  }
  
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    _songs = await _db.getSongsByArtist(widget.artist.id!);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _checkFollowing() async {
    final isFollowing = await _db.isFollowing(widget.artist.id!);
    if (mounted) {
      setState(() {
        _isFollowing = isFollowing;
      });
    }
  }
  
  Future<void> _toggleFollow() async {
    if (_isFollowing) {
      await _db.removeFollowing(widget.artist.id!);
      if (mounted) {
        setState(() {
          _isFollowing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unfollowed ${widget.artist.name}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      await _db.addFollowing(widget.artist.id!);
      if (mounted) {
        setState(() {
          _isFollowing = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Following ${widget.artist.name}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
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
                child: Center(
                  child: widget.artist.avatar != null && File(widget.artist.avatar!).existsSync()
                      ? CircleAvatar(
                          radius: 80,
                          backgroundImage: FileImage(File(widget.artist.avatar!)),
                        )
                      : const CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 80,
                            color: AppColors.primary,
                          ),
                        ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _toggleFollow,
                icon: Icon(
                  _isFollowing ? Icons.person_remove : Icons.person_add,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.artist.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.artist.bio != null && widget.artist.bio!.isNotEmpty)
                    Text(
                      widget.artist.bio!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.outline),
                  const SizedBox(height: 16),
                  Text(
                    '${_songs.length} ${_songs.length == 1 ? 'TRACK' : 'TRACKS'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_songs.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No tracks from this artist yet',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _songs[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TrackCard(
                      song: song,
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
                      onPlay: () {
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
                childCount: _songs.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}