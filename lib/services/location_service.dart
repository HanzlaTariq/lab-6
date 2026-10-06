import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Permission check/request karke current position return karta hai.
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location service band hai. GPS on karein.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission deny ho gayi.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permission permanently deny hai. App settings se allow karein.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// users/{uid} document me latest location save/update karta hai.
  Future<void> saveLocation({
    required String uid,
    required double latitude,
    required double longitude,
  }) async {
    await _db.collection('users').doc(uid).set({
      'userId': uid,
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
