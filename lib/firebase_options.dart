import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure by running the FlutterFire CLI.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure by running the FlutterFire CLI.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure by running the FlutterFire CLI.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for fuchsia - '
          'you can reconfigure by running the FlutterFire CLI.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCW-3YjVncUyCyV_WKqHlETaSMSe0syOO0',
    appId: '1:123962604856:android:11e6a20412419ab75e55cd',
    messagingSenderId: '123962604856',
    projectId: 'shoppilot-6c17a',
    storageBucket: 'shoppilot-6c17a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC3Lzm2yrFWzFCzR8fg_hecSQ1vvhizuQc',
    appId: '1:123962604856:ios:d3a86168781a718b5e55cd',
    messagingSenderId: '123962604856',
    projectId: 'shoppilot-6c17a',
    storageBucket: 'shoppilot-6c17a.firebasestorage.app',
    iosBundleId: 'com.example.shopPilot',
  );
}
