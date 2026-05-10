import 'dart:typed_data';

class FaceRecognitionService {
  Future<bool> verifyFace(Uint8List imageBytes) async {
    throw UnimplementedError('Integrate AWS Rekognition search here.');
  }

  Future<String> enrollFace(Uint8List imageBytes) async {
    throw UnimplementedError('Integrate AWS Rekognition index here.');
  }
}
