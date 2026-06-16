import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/song_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/track_card.dart';
import '../utils/constants.dart';
import '../models/song.dart';
import 'player_screen.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'all';
  
  final List<String> _periods = ['all', 'week', 'month', 'year'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedPeriod = _periods[_tabController.index];
        });
      }
    });
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
      appBar: AppBar(
        title: const Text(
          'TRENDING CHARTS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          tabs: const [
            Tab(text: 'ALL'),
            Tab(text: 'WEEK'),
            Tab(text: 'MONTH'),
            Tab(text: 'YEAR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _periods.map((period) => _TrendingContent(period: period)).toList(),
      ),
    );
  }
}

class _TrendingContent extends StatefulWidget {
  final String period;
  
  const _TrendingContent({required this.period});
  
  @override
  State<_TrendingContent> createState() => _TrendingContentState();
}

class _TrendingContentState extends State<_TrendingContent> {
  List<Song> _trendingSongs = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadTrending();
  }
  
  Future<void> _loadTrending() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    
    final provider = Provider.of<SongProvider>(context, listen: false);
    await provider.loadTrendingSongs(period: widget.period);
    
    if (mounted) {
      setState(() {
        _trendingSongs = provider.trendingSongs;
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_trendingSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text(
              'No trending tracks in this period',
              style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload and listen to music to see trending!',
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trendingSongs.length,
      itemBuilder: (context, index) {
        final song = _trendingSongs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: index < 3
                      ? AppColors.primaryGradient
                      : LinearGradient(
                          colors: [AppColors.surfaceContainerLow, AppColors.surfaceContainerLow],
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: index < 3 ? Colors.black : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                    final songProvider = Provider.of<SongProvider>(
                      context,
                      listen: false,
                    );
                    songProvider.toggleFavorite(song.id!);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}