import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/song_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/track_card.dart';
import '../utils/constants.dart';
import '../models/song.dart';
import 'player_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Explore',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
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
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(text: 'TRENDING'),
                  Tab(text: 'NEW RELEASES'),
                ],
              ),
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TrendingTab(),
                  _NewReleasesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SongProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final trending = provider.trendingSongs;
        
        if (trending.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, size: 48, color: AppColors.onSurfaceVariant),
                SizedBox(height: 12),
                Text(
                  'No trending tracks yet',
                  style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trending.length,
          itemBuilder: (context, index) {
            final song = trending[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: index < 3
                          ? AppColors.primaryGradient
                          : const LinearGradient(
                              colors: [AppColors.surfaceContainerLow, AppColors.surfaceContainerLow],
                            ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: index < 3 ? Colors.black : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
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
                        provider.toggleFavorite(song.id!);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _NewReleasesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SongProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Lọc bài hát có play_count < 5 (dưới 5 lượt nghe)
        final newReleases = provider.songs.where((song) => song.playCount < 5).toList();
        
        if (newReleases.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.new_releases, size: 48, color: AppColors.onSurfaceVariant),
                const SizedBox(height: 12),
                const Text(
                  'No new releases yet',
                  style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload new tracks to see them here!',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: newReleases.length,
          itemBuilder: (context, index) {
            final song = newReleases[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
                  provider.toggleFavorite(song.id!);
                },
              ),
            );
          },
        );
      },
    );
  }
}