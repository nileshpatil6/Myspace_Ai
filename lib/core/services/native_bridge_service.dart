import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../constants/channel_constants.dart';

class NativeBridgeService {
  NativeBridgeService._();

  static final NativeBridgeService instance = NativeBridgeService._();

  static const MethodChannel _triggerChannel =
      MethodChannel(ChannelConstants.triggerChannel);
  static const EventChannel _powerEventChannel =
      EventChannel(ChannelConstants.powerButtonEvents);
  static const EventChannel _screenshotEventChannel =
      EventChannel(ChannelConstants.screenshotEvents);

  Stream<String>? _powerEventStream;
  Stream<String>? _screenshotEventStream;

  /// Stream of power button trigger events (VOICE_TRIGGER or SCREENSHOT_TRIGGER).
  Stream<String> get powerButtonEvents {
    _powerEventStream ??= _powerEventChannel
        .receiveBroadcastStream()
        .map((event) => event.toString())
        .handleError((e) {
      debugPrint('Power event stream error: $e');
    });
    return _powerEventStream!;
  }

  /// Stream of new screenshot file paths detected by the native FileObserver.
  Stream<String> get screenshotEvents {
    _screenshotEventStream ??= _screenshotEventChannel
        .receiveBroadcastStream()
        .map((event) => event.toString())
        .handleError((e) {
      debugPrint('Screenshot event stream error: $e');
    });
    return _screenshotEventStream!;
  }

  Future<void> startService() async {
    try {
      await _triggerChannel.invokeMethod(ChannelConstants.startService);
    } catch (e) {
      debugPrint('startService failed: $e');
    }
  }

  Future<void> stopService() async {
    try {
      await _triggerChannel.invokeMethod(ChannelConstants.stopService);
    } catch (e) {
      debugPrint('stopService failed: $e');
    }
  }

  Future<bool> isServiceRunning() async {
    try {
      final result = await _triggerChannel
          .invokeMethod<bool>(ChannelConstants.isServiceRunning);
      return result ?? false;
    } catch (e) {
      debugPrint('isServiceRunning failed: $e');
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _triggerChannel
          .invokeMethod(ChannelConstants.openAccessibilitySettings);
    } catch (e) {
      debugPrint('openAccessibilitySettings failed: $e');
    }
  }

  Future<bool> hasOverlayPermission() async {
    try {
      final result = await _triggerChannel
          .invokeMethod<bool>(ChannelConstants.hasOverlayPermission);
      return result ?? false;
    } catch (e) {
      debugPrint('hasOverlayPermission failed: $e');
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _triggerChannel
          .invokeMethod(ChannelConstants.requestOverlayPermission);
    } catch (e) {
      debugPrint('requestOverlayPermission failed: $e');
    }
  }

  Future<void> showFloatingButton() async {
    try {
      await _triggerChannel.invokeMethod(ChannelConstants.showFloatingButton);
    } catch (e) {
      debugPrint('showFloatingButton failed: $e');
    }
  }

  Future<void> hideFloatingButton() async {
    try {
      await _triggerChannel.invokeMethod(ChannelConstants.hideFloatingButton);
    } catch (e) {
      debugPrint('hideFloatingButton failed: $e');
    }
  }
}
