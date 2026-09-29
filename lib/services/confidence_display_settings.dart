import 'package:flutter/foundation.dart';

/// Whether to show confidence as a number or an approved phrase
/// ("Fairly confident"). Shared across the app for this session, so it can
/// be switched between participants during user testing.
class ConfidenceDisplaySettings {
  static final ValueNotifier<bool> showNumeric = ValueNotifier<bool>(false);
}