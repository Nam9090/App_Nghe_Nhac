import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class FileStorageService {
  static final FileStorageService _instance = FileStorageService._internal();
  factory FileStorageService() => _instance;
  FileStorageService._internal();

  // Lấy thư mục ứng dụng
  Future<Directory> getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  // Lấy thư mục nhạc
  Future<Directory> getMusicDirectory() async {
    final appDir = await getAppDirectory();
    final musicDir = Directory(path.join(appDir.path, 'music'));
    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }
    return musicDir;
  }

  // Lấy thư mục ảnh
  Future<Directory> getImagesDirectory() async {
    final appDir = await getAppDirectory();
    final imagesDir = Directory(path.join(appDir.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  // Xin quyền truy cập storage
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  // Chọn file nhạc từ máy
  Future<File?> pickAudioFile() async {
    try {
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        return null;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      print('Error picking audio: $e');
      return null;
    }
  }

  // Chọn ảnh từ máy
  Future<File?> pickImage() async {
    try {
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        return null;
      }

      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Lưu file nhạc vào thư mục app
  Future<String?> saveAudioFile(File sourceFile) async {
    try {
      final musicDir = await getMusicDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(sourceFile.path)}';
      final destinationFile = File(path.join(musicDir.path, fileName));
      
      await sourceFile.copy(destinationFile.path);
      
      if (await destinationFile.exists()) {
        print('✅ Audio saved: ${destinationFile.path}');
        return destinationFile.path;
      } else {
        print('❌ Failed to save audio');
        return null;
      }
    } catch (e) {
      print('❌ Error saving audio: $e');
      return null;
    }
  }

  // Lưu ảnh vào thư mục app
  Future<String?> saveImageFile(File sourceFile) async {
    try {
      final imagesDir = await getImagesDirectory();
      final fileName = 'playlist_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destinationFile = File(path.join(imagesDir.path, fileName));
      
      await sourceFile.copy(destinationFile.path);
      
      if (await destinationFile.exists()) {
        print('✅ Image saved: ${destinationFile.path}');
        print('📁 File size: ${await destinationFile.length()} bytes');
        return destinationFile.path;
      } else {
        print('❌ Failed to save image - file does not exist');
        return null;
      }
    } catch (e) {
      print('❌ Error saving image: $e');
      return null;
    }
  }

  // Lấy thời lượng file nhạc (tạm thời trả về giá trị mặc định)
  Future<int> getAudioDuration(String filePath) async {
    return 180;
  }

  // Xóa file
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('✅ File deleted: $filePath');
        return true;
      }
      print('⚠️ File not found: $filePath');
      return false;
    } catch (e) {
      print('❌ Error deleting file: $e');
      return false;
    }
  }

  // Lấy danh sách file nhạc đã lưu
  Future<List<File>> getSavedAudioFiles() async {
    final musicDir = await getMusicDirectory();
    final List<File> files = [];
    
    try {
      final dir = Directory(musicDir.path);
      final List<FileSystemEntity> entities = await dir.list().toList();
      
      for (var entity in entities) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase();
          if (['.mp3', '.m4a', '.wav', '.aac', '.flac'].contains(extension)) {
            files.add(entity);
          }
        }
      }
      print('📁 Found ${files.length} audio files');
    } catch (e) {
      print('❌ Error listing audio files: $e');
    }
    
    return files;
  }

  // Lấy danh sách file ảnh đã lưu
  Future<List<File>> getSavedImageFiles() async {
    final imagesDir = await getImagesDirectory();
    final List<File> files = [];
    
    try {
      final dir = Directory(imagesDir.path);
      final List<FileSystemEntity> entities = await dir.list().toList();
      
      for (var entity in entities) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase();
          if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension)) {
            files.add(entity);
          }
        }
      }
      print('📁 Found ${files.length} image files');
    } catch (e) {
      print('❌ Error listing image files: $e');
    }
    
    return files;
  }

  // Xóa tất cả file trong thư mục nhạc
  Future<int> clearMusicDirectory() async {
    final musicDir = await getMusicDirectory();
    int deletedCount = 0;
    
    try {
      final files = await getSavedAudioFiles();
      for (var file in files) {
        if (await deleteFile(file.path)) {
          deletedCount++;
        }
      }
      print('🗑️ Deleted $deletedCount audio files');
    } catch (e) {
      print('❌ Error clearing music directory: $e');
    }
    
    return deletedCount;
  }

  // Xóa tất cả file trong thư mục ảnh
  Future<int> clearImagesDirectory() async {
    final imagesDir = await getImagesDirectory();
    int deletedCount = 0;
    
    try {
      final files = await getSavedImageFiles();
      for (var file in files) {
        if (await deleteFile(file.path)) {
          deletedCount++;
        }
      }
      print('🗑️ Deleted $deletedCount image files');
    } catch (e) {
      print('❌ Error clearing images directory: $e');
    }
    
    return deletedCount;
  }

  // Lấy tổng dung lượng thư mục (bytes)
  Future<int> getTotalStorageSize() async {
    int totalSize = 0;
    
    try {
      final musicFiles = await getSavedAudioFiles();
      for (var file in musicFiles) {
        totalSize += await file.length();
      }
      
      final imageFiles = await getSavedImageFiles();
      for (var file in imageFiles) {
        totalSize += await file.length();
      }
    } catch (e) {
      print('❌ Error calculating storage size: $e');
    }
    
    return totalSize;
  }

  // Lấy dung lượng đã sử dụng (MB)
  Future<double> getUsedStorageMB() async {
    final size = await getTotalStorageSize();
    return size / (1024 * 1024);
  }
}