import 'dart:async';

import 'package:geolocator/geolocator.dart';

class UserLocationException implements Exception {
  final String message;

  const UserLocationException(this.message);

  @override
  String toString() => message;
}

class UserLocationService {
  Future<Position> getCurrentPosition() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw const UserLocationException(
        'La localisation est désactivée sur votre appareil.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const UserLocationException('Permission de localisation refusée.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const UserLocationException(
        'Permission refusée définitivement. Activez-la dans les paramètres.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } on TimeoutException {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      throw const UserLocationException(
        'Localisation trop lente. Reessayez en exterieur ou activez le GPS.',
      );
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      throw const UserLocationException('Impossible de recuperer la position.');
    }
  }
}
