import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/auth_service.dart';
import '../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _loading = false;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(30.3753, 69.3451), // Pakistan
    zoom: 5,
  );

  Future<void> _getCurrentLocation() async {
    setState(() => _loading = true);
    try {
      final position = await _locationService.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      // Camera move + marker
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: latLng, zoom: 16)),
      );
      setState(() {
        _markers
          ..clear()
          ..add(Marker(
            markerId: const MarkerId('current_location'),
            position: latLng,
            infoWindow: const InfoWindow(title: 'Meri Location'),
          ));
      });

      // Firestore me save/update
      final user = _authService.currentUser;
      if (user != null) {
        await _locationService.saveLocation(
          uid: user.uid,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location Firebase me save ho gayi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _authService.signOut(),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        markers: _markers,
        onMapCreated: (controller) => _mapController = controller,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _getCurrentLocation,
        child: _loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
