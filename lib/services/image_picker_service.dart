import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 갤러리에서 이미지 여러 개 선택
  Future<List<XFile>> pickImagesFromGallery() async {
    return await _picker.pickMultiImage(imageQuality: 70);
  }

  // 카메라로 사진 찍기
  Future<XFile?> pickImageFromCamera() async {
    return await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
  }

  // 선택된 이미지들을 Firebase Storage에 업로드하고 URL 목록 반환
  Future<List<String>> uploadImages(
      {required List<XFile> images, required String shelterId}) async {
    List<String> downloadUrls = [];
    try {
      for (var image in images) {
        final String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final Reference ref =
        _storage.ref().child('animal_photos/$shelterId/$fileName');

        final UploadTask uploadTask = ref.putFile(File(image.path));
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }
    } catch (e) {
      debugPrint('이미지 업로드 오류: $e');
    }
    return downloadUrls;
  }
}