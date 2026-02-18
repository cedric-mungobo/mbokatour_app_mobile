import 'package:signals_flutter/signals_flutter.dart';

class MediaSettingsService {
  MediaSettingsService._();

  static final isMuted = signal(true);

  static bool toggleMute() {
    isMuted.value = !isMuted.value;
    return isMuted.value;
  }
}
