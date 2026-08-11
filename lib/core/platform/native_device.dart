import 'dart:io';
import 'dart:math';

class NativeDevice {
  const NativeDevice._();

  static String get platform {
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  static String get displayName {
    final host = Platform.localHostname.trim();
    if (host.isNotEmpty && host.toLowerCase() != 'localhost') return host;
    return 'VITI ${platform.toUpperCase()}';
  }

  static String randomId() {
    final random = Random.secure();
    return List<int>.generate(24, (_) => random.nextInt(256))
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
