import '../constants/app_constants.dart';

/// Inicializacion de Firebase (opcional hasta ejecutar flutterfire configure).
abstract final class FirebaseBootstrap {
  static bool isReady = false;

  static Future<void> initialize() async {
    if (!AppConstants.useFirebase) return;

    // Tras `flutterfire configure`, descomente:
    //
    // import 'package:firebase_core/firebase_core.dart';
    // import '../../firebase_options.dart';
    //
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
    // isReady = true;

    isReady = false;
  }
}
