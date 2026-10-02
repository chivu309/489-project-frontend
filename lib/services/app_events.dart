import 'package:flutter/foundation.dart';

/// Simple app-wide signals so pages kept alive in the bottom nav
/// know when to reload their data.
class AppEvents {
  /// Bumped whenever the skin profile changes (e.g. after a scan),
  /// so the Profile tab reloads.
  static final ValueNotifier<int> skinProfileVersion = ValueNotifier<int>(0);
}