import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../providers/audio_provider.dart';
import '../utils/constants.dart';
import '../models/song.dart';
import 'player_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Song> _downloadedSongs = [];
  bool _isLoading = true;
  double _totalStorageUsed = 0;
  
  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }
  
  Future<void> _loadDownloads() async {
    setState(() {
      _isLoading = true;
    });
    _downloadedSongs = await _db.getDownloadedSongs();
    await _calculateStorage();
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _calculateStorage() async {
    double totalBytes = 0;
    for (var song in _downloadedSongs) {
      final file = File(song.filePath);
      if (await file.exists()) {
        totalBytes += await file.length();
      }
    }
    setState(() {
      _totalStorageUsed = totalBytes / (1024 * 1024);
    });
  }
  
  Future<void> _removeDownload(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: const Text('Remove Download'),
        content: Text('Remove "${song.title}" from downloads?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('REMOVE', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _db.removeDownload(song.id!);
      await _loadDownloads();
      _showSnackBar('Removed from downloads', isError: false);
    }
  }
  
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Downloads',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _downloadedSongs.isEmpty
              ? _EmptyDownloads()
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.storage,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Storage used: ${_totalStorageUsed.toStringAsFixed(1)} MB',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _downloadedSongs.length,
                        itemBuilder: (context, index) {
                          final song = _downloadedSongs[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    color: AppColors.primary.withOpacity(0.3),
                                    child: _buildCoverArt(song),
                                  ),
                                ),
                                const SizedBox(width: 12),
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
                                      Text(
                                        song.artistName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 12,
                                            color: Colors.green,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Downloaded',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      final audioProvider = Provider.of<AudioProvider>(
                                        context,
                                        listen: false,
                                      );
                                      audioProvider.playSong(song);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const PlayerScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _removeDownload(song),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.music_note,
          color: AppColors.onSurfaceVariant,
        ),
      );
    }
    return const Icon(
      Icons.music_note,
      color: AppColors.onSurfaceVariant,
    );
  }
}

class _EmptyDownloads extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_outlined, size: 64, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 16),
          const Text(
            'No downloaded songs',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Songs you download will appear here',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('BROWSE MUSIC'),
          ),
        ],
      ),
    );
  }
}