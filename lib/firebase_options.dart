import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAFp8evNfndGZeZnR6ve9jrBbLKtI2YERk',
    appId: '1:449259807974:web:7715af5ff834178b96c727',
    messagingSenderId: '449259807974',
    projectId: 'douaya-139af',
    authDomain: 'douaya-139af.firebaseapp.com',
    storageBucket: 'douaya-139af.firebasestorage.app',
    measurementId: 'G-MTEVJD789L',
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDorhwd2bAyurFKMhcUcIBlAdqGQAUYSdQ',
    appId: '1:449259807974:android:82756f9a6806435096c727',
    messagingSenderId: '449259807974',
    projectId: 'douaya-139af',
    storageBucket: 'douaya-139af.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC6WR75UPfG_avC5naZTV98ls9gqiz9oVo',
    appId: '1:449259807974:ios:00265f54aafba5b396c727',
    messagingSenderId: '449259807974',
    projectId: 'douaya-139af',
    storageBucket: 'douaya-139af.firebasestorage.app',
    iosBundleId: 'com.example.dwayaApp',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC6WR75UPfG_avC5naZTV98ls9gqiz9oVo',
    appId: '1:449259807974:ios:00265f54aafba5b396c727',
    messagingSenderId: '449259807974',
    projectId: 'douaya-139af',
    storageBucket: 'douaya-139af.firebasestorage.app',
    iosBundleId: 'com.example.dwayaApp',
  );
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAFp8evNfndGZeZnR6ve9jrBbLKtI2YERk',
    appId: '1:449259807974:web:72c59391e39dc78196c727',
    messagingSenderId: '449259807974',
    projectId: 'douaya-139af',
    authDomain: 'douaya-139af.firebaseapp.com',
    storageBucket: 'douaya-139af.firebasestorage.app',
    measurementId: 'G-VV1VZ50C3N',
  );
}