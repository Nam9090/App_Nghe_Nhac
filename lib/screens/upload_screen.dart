import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/song_provider.dart';
import '../providers/artist_provider.dart';
import '../services/file_storage_service.dart';
import '../utils/constants.dart';
import '../models/song.dart';
import '../models/artist.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final FileStorageService _fileStorage = FileStorageService();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _newArtistController = TextEditingController();
  final TextEditingController _artistBioController = TextEditingController();
  
  File? _selectedAudioFile;
  File? _selectedCoverImage;
  File? _selectedArtistAvatar;
  String? _selectedAudioFileName;
  
  int? _selectedArtistId;
  bool _isCreatingNewArtist = false;
  
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  int _audioDuration = 180;
  
  final List<String> _genres = [
    'Electronic', 'Hip Hop', 'Ambient', 'Techno', 
    'Phonk', 'Rock', 'Pop', 'Jazz', 'Classical', 'Lo-fi'
  ];
  String _selectedGenre = 'Electronic';
  
  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadArtists();
  }
  
  Future<void> _loadArtists() async {
    final artistProvider = Provider.of<ArtistProvider>(context, listen: false);
    await artistProvider.loadArtists();
  }
  
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.storage,
        Permission.photos,
        Permission.audio,
      ].request();
    }
  }
  
  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedAudioFile = File(result.files.single.path!);
          _selectedAudioFileName = result.files.single.name;
        });
        _showSnackBar('Audio file selected: ${result.files.single.name}', isError: false);
      } else {
        _showSnackBar('No file selected');
      }
    } catch (e) {
      _showSnackBar('Error picking audio: $e');
    }
  }
  
  Future<void> _pickCoverImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedCoverImage = File(image.path);
        });
        _showSnackBar('Cover image selected', isError: false);
      } else {
        _showSnackBar('No image selected');
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e');
    }
  }
  
  Future<void> _pickArtistAvatar() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedArtistAvatar = File(image.path);
        });
        _showSnackBar('Artist avatar selected', isError: false);
      } else {
        _showSnackBar('No image selected');
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e');
    }
  }
  
  Future<void> _createNewArtist() async {
    if (_newArtistController.text.trim().isEmpty) {
      _showSnackBar('Please enter artist name');
      return;
    }
    
    final artistProvider = Provider.of<ArtistProvider>(context, listen: false);
    String? savedAvatarPath;
    
    if (_selectedArtistAvatar != null) {
      savedAvatarPath = await _fileStorage.saveImageFile(_selectedArtistAvatar!);
    }
    
    final newArtist = await artistProvider.createArtist(
      _newArtistController.text.trim(),
      avatar: savedAvatarPath,
      bio: _artistBioController.text.trim(),
    );
    
    if (newArtist != null) {
      setState(() {
        _selectedArtistId = newArtist.id;
        _isCreatingNewArtist = false;
        _newArtistController.clear();
        _artistBioController.clear();
        _selectedArtistAvatar = null;
      });
      _showSnackBar('Artist created successfully!', isError: false);
    }
  }
  
  Future<void> _uploadSong() async {
    if (_selectedAudioFile == null) {
      _showSnackBar('Please select an audio file');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Please enter a title');
      return;
    }
    if (_selectedArtistId == null && !_isCreatingNewArtist) {
      _showSnackBar('Please select an artist or create a new one');
      return;
    }
    
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.2;
    });
    
    try {
      final savedAudioPath = await _fileStorage.saveAudioFile(_selectedAudioFile!);
      if (savedAudioPath == null) {
        throw Exception('Failed to save audio file');
      }
      
      setState(() => _uploadProgress = 0.5);
      
      String? savedImagePath;
      if (_selectedCoverImage != null) {
        savedImagePath = await _fileStorage.saveImageFile(_selectedCoverImage!);
      }
      
      setState(() => _uploadProgress = 0.8);
      
      final song = Song(
        title: _titleController.text.trim(),
        artistId: _selectedArtistId,
        filePath: savedAudioPath,
        coverArt: savedImagePath,
        duration: _audioDuration,
        genre: _selectedGenre,
        uploadDate: DateTime.now(),
      );
      
      final songProvider = Provider.of<SongProvider>(context, listen: false);
      await songProvider.addSong(song);
      
      setState(() => _uploadProgress = 1.0);
      
      _clearForm();
      _showSnackBar('Upload successful!', isError: false);
      
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context);
      });
      
    } catch (e) {
      _showSnackBar('Upload failed: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }
  
  void _clearForm() {
    _titleController.clear();
    setState(() {
      _selectedAudioFile = null;
      _selectedCoverImage = null;
      _selectedAudioFileName = null;
      _selectedArtistId = null;
      _selectedGenre = 'Electronic';
    });
  }
  
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Upload Track',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SHARE YOUR SOUND',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload your music to share with the world',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              
              _buildFilePicker(
                label: 'AUDIO FILE *',
                file: _selectedAudioFile,
                fileName: _selectedAudioFileName,
                onTap: _pickAudioFile,
                icon: Icons.audiotrack,
                hint: 'MP3, WAV, FLAC, M4A',
              ),
              const SizedBox(height: 24),
              
              _buildFilePicker(
                label: 'COVER ART',
                file: _selectedCoverImage,
                fileName: _selectedCoverImage?.path.split('/').last,
                onTap: _pickCoverImage,
                icon: Icons.image,
                hint: 'JPG, PNG (optional)',
                isImage: true,
              ),
              const SizedBox(height: 24),
              
              _buildTextField(
                label: 'TRACK TITLE *',
                controller: _titleController,
                hint: 'Name your masterpiece',
              ),
              const SizedBox(height: 20),
              
              if (!_isCreatingNewArtist)
                _buildArtistDropdown(),
              
              if (!_isCreatingNewArtist)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isCreatingNewArtist = true;
                      });
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('+ CREATE NEW ARTIST'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
              
              if (_isCreatingNewArtist)
                _buildNewArtistForm(),
              
              const SizedBox(height: 20),
              
              _buildGenreDropdown(),
              const SizedBox(height: 32),
              
              if (_isUploading) ...[
                _buildProgressBar(),
                const SizedBox(height: 20),
              ],
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadSong,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'PUBLISH TRACK',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Files will be stored locally on your device',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildArtistDropdown() {
    return Consumer<ArtistProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ARTIST *',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _selectedArtistId,
                  isExpanded: true,
                  hint: const Text(
                    'Select an artist',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                  dropdownColor: AppColors.surfaceContainerHigh,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.onSurface,
                  ),
                  items: [
                    if (provider.artists.isEmpty)
                      const DropdownMenuItem(
                        value: null,
                        child: Text('No artists yet. Create one!'),
                      ),
                    ...provider.artists.map((artist) {
                      return DropdownMenuItem(
                        value: artist.id,
                        child: Row(
                          children: [
                            if (artist.avatar != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  File(artist.avatar!),
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            else
                              const Icon(
                                Icons.person,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                artist.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedArtistId = value;
                    });
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildNewArtistForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'NEW ARTIST',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isCreatingNewArtist = false;
                    _newArtistController.clear();
                    _artistBioController.clear();
                    _selectedArtistAvatar = null;
                  });
                },
                icon: const Icon(Icons.close, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildTextField(
            label: 'ARTIST NAME *',
            controller: _newArtistController,
            hint: 'Enter artist name',
          ),
          const SizedBox(height: 12),
          
          _buildFilePicker(
            label: 'ARTIST AVATAR',
            file: _selectedArtistAvatar,
            fileName: _selectedArtistAvatar?.path.split('/').last,
            onTap: _pickArtistAvatar,
            icon: Icons.person,
            hint: 'JPG, PNG (optional)',
            isImage: true,
          ),
          const SizedBox(height: 12),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ARTIST BIO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _artistBioController,
                style: const TextStyle(color: AppColors.onSurface),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tell something about the artist...',
                  hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isCreatingNewArtist = false;
                      _newArtistController.clear();
                      _artistBioController.clear();
                      _selectedArtistAvatar = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceVariant,
                    side: const BorderSide(color: AppColors.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('CANCEL'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _createNewArtist,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('CREATE ARTIST'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilePicker({
    required String label,
    required File? file,
    String? fileName,
    required VoidCallback onTap,
    required IconData icon,
    required String hint,
    bool isImage = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: isImage ? 150 : 100,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: file != null
                ? (isImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          file,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            size: 48,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.audio_file,
                              size: 32,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              fileName ?? file.path.split('/').last,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap to change',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ))
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 32,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hint,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap to select',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildGenreDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GENRE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGenre,
              isExpanded: true,
              dropdownColor: AppColors.surfaceContainerHigh,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.onSurface,
              ),
              items: _genres.map((genre) {
                return DropdownMenuItem(
                  value: genre,
                  child: Text(genre),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedGenre = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Uploading...',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: AppColors.surfaceContainerHighest,
            color: AppColors.primary,
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}