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
import 'wrapped_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _usernameController = TextEditingController();
  
  String _username = 'Listener';
  File? _avatarImage;
  List<Song> _userSongs = [];
  List<Artist> _following = [];
  int _followersCount = 42;
  int _totalPlays = 0;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _usernameController.text = _username;
  }
  
  Future<void> _loadUserData() async {
    final songs = await _db.getAllSongs();
    final following = await _db.getFollowingArtists();
    final history = await _db.getListeningHistory(limit: 1000);
    
    int totalPlays = 0;
    for (var song in songs) {
      totalPlays += song.playCount;
    }
    
    setState(() {
      _userSongs = songs;
      _following = following;
      _totalPlays = totalPlays;
    });
  }
  
  Future<void> _updateUsername() async {
    final newName = _usernameController.text.trim();
    if (newName.isNotEmpty) {
      setState(() {
        _username = newName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username updated'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
    Navigator.pop(context);
  }
  
  void _showEditUsernameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: const Text('Edit Username'),
        content: TextField(
          controller: _usernameController,
          style: const TextStyle(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: 'Enter username',
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
            onPressed: _updateUsername,
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WrappedScreen()),
              );
            },
            icon: const Icon(Icons.auto_awesome, color: AppColors.primary),
            tooltip: 'Your Year in Music',
          ),
          IconButton(
            onPressed: _showEditUsernameDialog,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.transparent,
                        backgroundImage: _avatarImage != null
                            ? FileImage(_avatarImage!)
                            : null,
                        child: _avatarImage == null
                            ? Icon(
                                Icons.person,
                                size: 48,
                                color: Colors.black.withOpacity(0.5),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Member since 2024',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                        value: _userSongs.length.toString(),
                        label: 'TRACKS',
                      ),
                      _StatItem(
                        value: _totalPlays.toString(),
                        label: 'PLAYS',
                      ),
                      _StatItem(
                        value: _followersCount.toString(),
                        label: 'FOLLOWERS',
                      ),
                      _StatItem(
                        value: _following.length.toString(),
                        label: 'FOLLOWING',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _showEditUsernameDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('EDIT PROFILE'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text(
                  'YOUR TRACKS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
              ]),
            ),
          ),
          
          if (_userSongs.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.music_note_outlined,
                        size: 48,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No tracks uploaded yet',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text('UPLOAD YOUR FIRST TRACK'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _userSongs[index];
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
                childCount: _userSongs.length,
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  
  const _StatItem({
    required this.value,
    required this.label,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}