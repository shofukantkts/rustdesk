import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/mobile/pages/remote_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final peerPlatform in <String?>[
    null,
    kPeerPlatformAndroid,
    kPeerPlatformWindows,
    kPeerPlatformMacOS,
    kPeerPlatformLinux,
  ]) {
    test('iOS opens the panel for ${peerPlatform ?? 'unknown'} peers', () {
      expect(
        supportsRemoteKeyboardPanel(
          isIOS: true,
          peerPlatform: peerPlatform,
        ),
        isTrue,
      );
    });
  }

  test('Android keeps the legacy keyboard path', () {
    expect(
      supportsRemoteKeyboardPanel(
        isIOS: false,
        peerPlatform: kPeerPlatformWindows,
      ),
      isFalse,
    );
  });
}
