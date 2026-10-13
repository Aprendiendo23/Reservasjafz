// File generated using FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCnZ42nbyZLLNLk097L71P4P9EZs491EAg',
    appId: '1:353355509945:web:4de77525a432b731682b68',
    messagingSenderId: '353355509945',
    projectId: 'recursostic-18bb8',
    authDomain: 'recursostic-18bb8.firebaseapp.com',
    storageBucket: 'recursostic-18bb8.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCnZ42nbyZLLNLk097L71P4P9EZs491EAg',
    appId: '1:353355509945:android:4de77525a432b731682b68',
    messagingSenderId: '353355509945',
    projectId: 'recursostic-18bb8',
    storageBucket: 'recursostic-18bb8.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCnZ42nbyZLLNLk097L71P4P9EZs491EAg',
    appId: '1:353355509945:ios:4de77525a432b731682b68',
    messagingSenderId: '353355509945',
    projectId: 'recursostic-18bb8',
    storageBucket: 'recursostic-18bb8.firebasestorage.app',
    iosBundleId: 'com.recursostic.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCnZ42nbyZLLNLk097L71P4P9EZs491EAg',
    appId: '1:353355509945:macos:4de77525a432b731682b68',
    messagingSenderId: '353355509945',
    projectId: 'recursostic-18bb8',
    storageBucket: 'recursostic-18bb8.firebasestorage.app',
    iosBundleId: 'com.recursostic.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCnZ42nbyZLLNLk097L71P4P9EZs491EAg',
    appId: '1:353355509945:web:4de77525a432b731682b68',
    messagingSenderId: '353355509945',
    projectId: 'recursostic-18bb8',
    authDomain: 'recursostic-18bb8.firebaseapp.com',
    storageBucket: 'recursostic-18bb8.firebasestorage.app',
  );

  // Para Linux de escritorio usamos la misma configuración que web/windows,
  // ya que comparten el mismo proyecto Firebase.
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyCnZ42nbyZLLNLk097L71P4P9EZs491EAg',
    appId: '1:353355509945:web:4de77525a432b731682b68',
    messagingSenderId: '353355509945',
    projectId: 'recursostic-18bb8',
    authDomain: 'recursostic-18bb8.firebaseapp.com',
    storageBucket: 'recursostic-18bb8.firebasestorage.app',
  );
}

