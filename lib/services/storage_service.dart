import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageService {
  Future<File> getFileForVersion(String versionId) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$versionId.mp3');
  }

  Future<bool> isDownloaded(String versionId) async {
    return (await getFileForVersion(versionId)).exists();
  }

  Future<void> deleteFile(String versionId) async {
    final file = await getFileForVersion(versionId);
    if (await file.exists()) await file.delete();
  }
}
