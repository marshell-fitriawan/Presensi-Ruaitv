import 'package:camera/camera.dart';

class CameraService {
  Future<XFile> takeSelfie(CameraController controller) {
    return controller.takePicture();
  }
}
