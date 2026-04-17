class ChannelConstants {
  ChannelConstants._();

  // ─── Method channels ──────────────────────────────────────────────────────
  static const String triggerChannel = 'com.myspace.ai/trigger';

  // ─── Event channels ───────────────────────────────────────────────────────
  static const String powerButtonEvents = 'com.myspace.ai/power_events';
  static const String screenshotEvents = 'com.myspace.ai/screenshot_events';

  // ─── Trigger channel method names ─────────────────────────────────────────
  static const String startService = 'startService';
  static const String stopService = 'stopService';
  static const String isServiceRunning = 'isServiceRunning';
  static const String openAccessibilitySettings = 'openAccessibilitySettings';
  static const String requestOverlayPermission = 'requestOverlayPermission';
  static const String hasOverlayPermission = 'hasOverlayPermission';
  static const String showFloatingButton = 'showFloatingButton';
  static const String hideFloatingButton = 'hideFloatingButton';

  // ─── Event values ─────────────────────────────────────────────────────────
  static const String voiceTrigger = 'VOICE_TRIGGER';
  static const String screenshotTrigger = 'SCREENSHOT_TRIGGER';
}
