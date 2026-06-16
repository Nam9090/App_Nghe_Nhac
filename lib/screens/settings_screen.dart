import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../providers/song_provider.dart';
import '../services/file_storage_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final FileStorageService _fileStorage = FileStorageService();
  
  bool _notificationsEnabled = true;
  bool _autoDownload = false;
  bool _highQualityStreaming = true;
  double _storageUsed = 0;
  int _songsCount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }
  
  Future<void> _loadStorageInfo() async {
    final songs = await _db.getAllSongs();
    final downloaded = await _db.getDownloadedSongs();
    
    double totalBytes = 0;
    for (var song in songs) {
      final file = File(song.filePath);
      if (await file.exists()) {
        totalBytes += await file.length();
      }
    }
    
    setState(() {
      _storageUsed = totalBytes / (1024 * 1024);
      _songsCount = songs.length;
    });
  }
  
  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: const Text('Clear Cache'),
        content: const Text('This will remove all downloaded songs. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CLEAR', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final downloaded = await _db.getDownloadedSongs();
      for (var song in downloaded) {
        await _db.removeDownload(song.id!);
      }
      
      await _loadStorageInfo();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader(title: 'ACCOUNT'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Profile',
            subtitle: 'View and edit your profile',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Privacy',
            subtitle: 'Manage your privacy settings',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          
          const _SectionHeader(title: 'PLAYBACK'),
          const SizedBox(height: 8),
          _SettingsSwitch(
            icon: Icons.volume_up,
            title: 'High Quality Streaming',
            value: _highQualityStreaming,
            onChanged: (value) {
              setState(() {
                _highQualityStreaming = value;
              });
            },
          ),
          _SettingsSwitch(
            icon: Icons.download,
            title: 'Auto Download',
            subtitle: 'Automatically download liked songs',
            value: _autoDownload,
            onChanged: (value) {
              setState(() {
                _autoDownload = value;
              });
            },
          ),
          const SizedBox(height: 24),
          
          const _SectionHeader(title: 'NOTIFICATIONS'),
          const SizedBox(height: 8),
          _SettingsSwitch(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          const SizedBox(height: 24),
          
          const _SectionHeader(title: 'STORAGE'),
          const SizedBox(height: 8),
          _StorageInfo(
            used: _storageUsed,
            songsCount: _songsCount,
          ),
          _SettingsTile(
            icon: Icons.cleaning_services,
            title: 'Clear Cache',
            subtitle: 'Remove downloaded songs',
            onTap: _clearCache,
            textColor: AppColors.error,
          ),
          const SizedBox(height: 24),
          
          const _SectionHeader(title: 'ABOUT'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
            onTap: null,
          ),
          _SettingsTile(
            icon: Icons.code,
            title: 'Open Source Licenses',
            onTap: () {},
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  
  const _SectionHeader({required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? textColor;
  
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.textColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.onSurfaceVariant),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor ?? AppColors.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            )
          : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant)
          : null,
      onTap: onTap,
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  
  const _SettingsSwitch({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.onSurfaceVariant),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}

class _StorageInfo extends StatelessWidget {
  final double used;
  final int songsCount;
  
  const _StorageInfo({
    required this.used,
    required this.songsCount,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Storage Used',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                '${used.toStringAsFixed(1)} MB',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: used / 500,
            backgroundColor: AppColors.surfaceContainerHighest,
            color: AppColors.primary,
            minHeight: 4,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Songs',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                '$songsCount songs',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}