import 'dart:io';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../screens/artist_profile_screen.dart';

class TrackCard extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onFavorite;
  final bool showFavoriteButton;
  
  const TrackCard({
    super.key,
    required this.song,
    this.onTap,
    this.onPlay,
    this.onFavorite,
    this.showFavoriteButton = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Cover Art
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 44,
                height: 44,
                color: AppColors.primary.withOpacity(0.3),
                child: _buildCoverArt(),
              ),
            ),
            const SizedBox(width: 10),
            // Track Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Artist Name with click
                  GestureDetector(
                    onTap: () async {
                      if (song.artistId != null) {
                        final db = DatabaseHelper();
                        final artist = await db.getArtistById(song.artistId!);
                        if (artist != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ArtistProfileScreen(artist: artist),
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      song.artistName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        size: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${Helpers.formatNumber(song.playCount)} plays',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.timer_outlined,
                        size: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        Helpers.formatDuration(Duration(seconds: song.duration)),
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Favorite Button
            if (showFavoriteButton)
              IconButton(
                onPressed: onFavorite,
                icon: Icon(
                  song.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: song.isFavorite ? AppColors.primary : AppColors.onSurfaceVariant,
                  size: 16,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            // Play Button
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: onPlay,
                icon: const Icon(
                  Icons.play_arrow,
                  color: Colors.black,
                  size: 16,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCoverArt() {
    if (song.coverArt != null && File(song.coverArt!).existsSync()) {
      return Image.file(
        File(song.coverArt!),
        width: 44,
        height: 44,
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
}