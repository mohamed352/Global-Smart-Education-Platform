import 'dart:io';
import 'dart:math' as math;
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';

/// خدمة محسّنة للتعامل مع الملفات الوسائط (صور، فيديو، صوت)
@lazySingleton
class MediaService {
  MediaService();

  /// حفظ الصورة إلى التخزين التطبيقي
  Future<String?> saveImageLocally(File imageFile, String fileName) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagePath = '${appDir.path}/lessons/images';
      final Directory imageDir = Directory(imagePath);

      if (!imageDir.existsSync()) {
        imageDir.createSync(recursive: true);
      }

      final File savedImage = await imageFile.copy('$imagePath/$fileName');
      log.i('Image saved to: ${savedImage.path}');
      return savedImage.path;
    } catch (e) {
      log.e('Failed to save image', error: e);
    }
    return null;
  }

  /// حفظ الفيديو إلى التخزين التطبيقي
  Future<String?> saveVideoLocally(File videoFile, String fileName) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String videoPath = '${appDir.path}/lessons/videos';
      final Directory videoDir = Directory(videoPath);

      if (!videoDir.existsSync()) {
        videoDir.createSync(recursive: true);
      }

      final File savedVideo = await videoFile.copy('$videoPath/$fileName');
      log.i('Video saved to: ${savedVideo.path}');
      return savedVideo.path;
    } catch (e) {
      log.e('Failed to save video', error: e);
    }
    return null;
  }

  /// الحصول على حجم الملف
  Future<int> getFileSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      log.e('Failed to get file size', error: e);
      return 0;
    }
  }

  /// تنسيق حجم الملف للعرض
  String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (math.log(bytes) / math.log(1024)).floor();
    if (i >= suffixes.length) i = suffixes.length - 1;
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// حذف ملف
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        log.i('File deleted: $filePath');
        return true;
      }
    } catch (e) {
      log.e('Failed to delete file', error: e);
    }
    return false;
  }

  /// التحقق من وجود ملف
  Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      log.e('Failed to check file existence', error: e);
    }
    return false;
  }

  /// نسخ ملف
  Future<String?> copyFile(String sourcePath, String destinationFileName) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        log.e('Source file does not exist: $sourcePath');
        return null;
      }

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String destDirectory = '${appDir.path}/lessons/files';
      final Directory destDir = Directory(destDirectory);

      if (!destDir.existsSync()) {
        destDir.createSync(recursive: true);
      }

      final String destinationPath = '$destDirectory/$destinationFileName';
      final destFile = await sourceFile.copy(destinationPath);
      log.i('File copied to: $destinationPath');
      return destFile.path;
    } catch (e) {
      log.e('Failed to copy file', error: e);
    }
    return null;
  }

  /// الحصول على قائمة الملفات المحفوظة
  Future<List<FileSystemEntity>> getSavedFiles(String subDirectory) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory dir = Directory('${appDir.path}/lessons/$subDirectory');

      if (!dir.existsSync()) {
        return [];
      }

      return dir.listSync();
    } catch (e) {
      log.e('Failed to get saved files', error: e);
    }
    return [];
  }
}
