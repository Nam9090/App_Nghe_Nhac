import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/song.dart';

class MiniPlayer extends StatelessWidget {
  final Song? currentSong;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onFavorite;
  
  const MiniPlayer({
    super.key,
    this.currentSong,
    required this.isPlaying,
    required this.onTap,
    required this.onPlayPause,
    required this.onNext,
    required this.onFavorite,
  });
  
  @override
  Widget build(BuildContext context) {
    if (currentSong == null) return const SizedBox.shrink();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surfaceContainerHighest,
              AppColors.surfaceContainerHigh,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          border: Border(
            top: BorderSide(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Album Art
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                color: AppColors.primary.withOpacity(0.3),
                child: _buildCoverArt(),
              ),
            ),
            const SizedBox(width: 8),
            // Track Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentSong!.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currentSong!.artistName,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Favorite Button
            IconButton(
              onPressed: onFavorite,
              icon: Icon(
                currentSong!.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: currentSong!.isFavorite ? AppColors.primary : AppColors.onSurfaceVariant,
                size: 16,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            // Play/Pause Button
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: onPlayPause,
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
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
            // Next Button
            IconButton(
              onPressed: onNext,
              icon: const Icon(
                Icons.skip_next,
                color: AppColors.onSurface,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCoverArt() {
    if (currentSong!.coverArt != null && File(currentSong!.coverArt!).existsSync()) {
      return Image.file(
        File(currentSong!.coverArt!),
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.music_note,
          size: 18,
          color: AppColors.onSurfaceVariant,
        ),
      );
    }
    return const Icon(
      Icons.music_note,
      size: 18,
      color: AppColors.onSurfaceVariant,
    );
  }
}