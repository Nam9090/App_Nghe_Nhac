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
import 'artist_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  
  List<Song> _searchResults = [];
  List<Artist> _artistResults = [];
  List<String> _recentSearches = [];
  bool _isSearching = false;
  String _selectedGenre = 'All';
  String _searchType = 'all'; // 'all', 'songs', 'artists'
  
  final List<String> _genres = [
    'All', 'Electronic', 'Hip Hop', 'Ambient', 'Techno', 
    'Phonk', 'Rock', 'Pop', 'Jazz', 'Classical', 'Lo-fi'
  ];
  
  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }
  
  Future<void> _loadRecentSearches() async {
    final searches = await _db.getRecentSearches();
    if (mounted) {
      setState(() {
        _recentSearches = searches;
      });
    }
  }
  
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _artistResults = [];
        _isSearching = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    
    if (_searchType == 'songs' || _searchType == 'all') {
      final songs = await songProvider.searchSongs(query);
      setState(() {
        _searchResults = songs;
      });
    }
    
    if (_searchType == 'artists' || _searchType == 'all') {
      final artists = await _db.searchArtists(query);
      setState(() {
        _artistResults = artists;
      });
    }
    
    setState(() {
      _isSearching = false;
    });
    
    await _loadRecentSearches();
  }
  
  Future<void> _searchByGenre(String genre) async {
    if (genre == 'All') {
      setState(() {
        _searchResults = [];
        _searchController.clear();
        _isSearching = false;
        _selectedGenre = 'All';
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _searchController.text = genre;
    });
    
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final results = await songProvider.getSongsByGenre(genre);
    
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }
  
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _artistResults = [];
      _isSearching = false;
      _selectedGenre = 'All';
    });
  }
  
  void _clearRecentSearches() async {
    await _db.clearRecentSearches();
    await _loadRecentSearches();
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
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: AppColors.onSurface),
                      onChanged: _performSearch,
                      decoration: InputDecoration(
                        hintText: 'Artists, songs, genres...',
                        hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.onSurfaceVariant,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: _clearSearch,
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search type selector
                  Row(
                    children: [
                      _buildSearchTypeChip('TẤT CẢ', 'all'),
                      const SizedBox(width: 8),
                      _buildSearchTypeChip('BÀI HÁT', 'songs'),
                      const SizedBox(width: 8),
                      _buildSearchTypeChip('NGHỆ SĨ', 'artists'),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : (_searchResults.isNotEmpty || _artistResults.isNotEmpty || _searchController.text.isNotEmpty)
                      ? _SearchResults(
                          songs: _searchResults,
                          artists: _artistResults,
                          searchType: _searchType,
                        )
                      : _RecentAndGenres(
                          recentSearches: _recentSearches,
                          selectedGenre: _selectedGenre,
                          genres: _genres,
                          onSearch: _performSearch,
                          onClearRecent: _clearRecentSearches,
                          onGenreSelected: (genre) {
                            setState(() {
                              _selectedGenre = genre;
                            });
                            _searchByGenre(genre);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchTypeChip(String label, String type) {
    final isSelected = _searchType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _searchType = type;
        });
        _performSearch(_searchController.text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List<Song> songs;
  final List<Artist> artists;
  final String searchType;
  
  const _SearchResults({
    required this.songs,
    required this.artists,
    required this.searchType,
  });
  
  @override
  Widget build(BuildContext context) {
    if (searchType == 'artists' || (searchType == 'all' && artists.isNotEmpty)) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return _ArtistResultCard(artist: artist);
        },
      );
    }
    
    if (songs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off, size: 48, color: AppColors.onSurfaceVariant),
            SizedBox(height: 12),
            Text(
              'No results found',
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
              final audioProvider = Provider.of<AudioProvider>(context, listen: false);
              audioProvider.playSong(song);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayerScreen()),
              );
            },
            onPlay: () {
              final audioProvider = Provider.of<AudioProvider>(context, listen: false);
              audioProvider.playSong(song);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayerScreen()),
              );
            },
            onFavorite: () {
              final songProvider = Provider.of<SongProvider>(context, listen: false);
              songProvider.toggleFavorite(song.id!);
            },
          ),
        );
      },
    );
  }
}

class _ArtistResultCard extends StatelessWidget {
  final Artist artist;
  
  const _ArtistResultCard({required this.artist});
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArtistDetailScreen(artist: artist),
          ),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 56,
                height: 56,
                color: AppColors.primary.withOpacity(0.3),
                child: artist.avatar != null && File(artist.avatar!).existsSync()
                    ? Image.file(
                        File(artist.avatar!),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 32,
                        color: AppColors.primary,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artist.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nghệ sĩ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentAndGenres extends StatelessWidget {
  final List<String> recentSearches;
  final String selectedGenre;
  final List<String> genres;
  final Function(String) onSearch;
  final VoidCallback onClearRecent;
  final Function(String) onGenreSelected;
  
  const _RecentAndGenres({
    required this.recentSearches,
    required this.selectedGenre,
    required this.genres,
    required this.onSearch,
    required this.onClearRecent,
    required this.onGenreSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENT SEARCHES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: onClearRecent,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'CLEAR ALL',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...recentSearches.map((query) => GestureDetector(
                  onTap: () => onSearch(query),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.history,
                          size: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            query,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 20),
          ],
          
          const Text(
            'BROWSE BY GENRE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: genres.map((genre) {
              final isSelected = selectedGenre == genre;
              return GestureDetector(
                onTap: () => onGenreSelected(genre),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    genre,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.black : AppColors.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}