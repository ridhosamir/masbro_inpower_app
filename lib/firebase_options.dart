
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
    apiKey: 'AIzaSyDyS1Ms3CxD07VxaimdF4sC5qbiLfzN0rA',
    appId: '1:197775411969:web:40078b1dc5bd7dffebe900',
    messagingSenderId: '197775411969',
    projectId: 'test-4fa2a',
    authDomain: 'test-4fa2a.firebaseapp.com',
    storageBucket: 'test-4fa2a.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD3ZM2lo0FvsszS5CLDC8JM5ZFmGMCrAoo',
    appId: '1:197775411969:android:b2b87609dbfc42b3ebe900',
    messagingSenderId: '197775411969',
    projectId: 'test-4fa2a',
    storageBucket: 'test-4fa2a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD2CkPtcHLvKxb2B8wyIjqadD014dAUHNM',
    appId: '1:197775411969:ios:0337dad5810c6bd9ebe900',
    messagingSenderId: '197775411969',
    projectId: 'test-4fa2a',
    storageBucket: 'test-4fa2a.firebasestorage.app',
    iosBundleId: 'com.example.lontarApplication',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD2CkPtcHLvKxb2B8wyIjqadD014dAUHNM',
    appId: '1:197775411969:ios:0337dad5810c6bd9ebe900',
    messagingSenderId: '197775411969',
    projectId: 'test-4fa2a',
    storageBucket: 'test-4fa2a.firebasestorage.app',
    iosBundleId: 'com.example.lontarApplication',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDyS1Ms3CxD07VxaimdF4sC5qbiLfzN0rA',
    appId: '1:197775411969:web:637f5af1c7fb1b93ebe900',
    messagingSenderId: '197775411969',
    projectId: 'test-4fa2a',
    authDomain: 'test-4fa2a.firebaseapp.com',
    storageBucket: 'test-4fa2a.firebasestorage.app',
  );
}
