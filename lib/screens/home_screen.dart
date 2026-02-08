import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/cab_api.dart';
import '../services/socket_service.dart';
import '../models/driver.dart';
import '../core/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controllers
  final pickupController = TextEditingController();
  final dropController = TextEditingController();
  GoogleMapController? _mapController;

  // State Variables
  List<Driver> drivers = [];
  Driver? activeDriver;
  String? currentTripId;
  String tripState = "IDLE";
  bool loading = false;
  String status = AppText.ready;

  // Map State
  Set<Marker> _markers = {};
  static const LatLng _kokrajharCenter = LatLng(26.40, 90.27);

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    SocketService.disconnect();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    setState(() => loading = true);
    _initSocketListeners(null);
    try {
      if (kDebugMode) await CabApi.resetDrivers();
      await _syncState();
    } catch (_) {
      setState(() => status = AppText.serviceError);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _syncState() async {
    try {
      final driversData = await CabApi.getDrivers();
      final trip = await CabApi.getTripStatus();

      setState(() {
        drivers = driversData;
        tripState = trip["state"] ?? "IDLE";
        currentTripId = trip["tripId"];
        
        // Map markers for nearby drivers
        _updateNearbyDriverMarkers();

        final driverName = trip["driverName"];
        activeDriver = (driverName == null || drivers.isEmpty)
            ? null
            : drivers.firstWhere((d) => d.name == driverName, orElse: () => drivers.first);
      });

      if (currentTripId != null && tripState != "COMPLETED") {
        SocketService.joinTrip(currentTripId!);
      }
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

  void _initSocketListeners(String? tripId) {
    SocketService.init();

    // 1. Global Driver List Updates
    SocketService.onEvent("drivers_updated", (data) {
      if (mounted) {
        setState(() {
          drivers = (data as List).map((e) => Driver.fromJson(e)).toList();
          _updateNearbyDriverMarkers();
        });
      }
    });

    // 2. Private Trip State Updates
    SocketService.onEvent("trip_update", (updatedRide) {
      if (mounted) {
        setState(() {
          tripState = updatedRide["state"];
          status = "Trip is now $tripState";
          if (tripState == "COMPLETED") {
            currentTripId = null;
            activeDriver = null;
            _markers.removeWhere((m) => m.markerId.value == "active_driver");
          }
        });
      }
    });

    // 3. Real-time Location Updates (Moving Car)
    SocketService.onEvent("driver_location", (data) {
      if (mounted) {
        double lat = data['lat'];
        double lng = data['lng'];
        _updateActiveDriverMarker(lat, lng);
      }
    });

    if (tripId != null) SocketService.joinTrip(tripId);
  }

  void _updateNearbyDriverMarkers() {
    // Show nearby drivers as smaller grey icons when idle
    if (tripState != "IDLE") return;
    setState(() {
      _markers = drivers.where((d) => d.online).map((d) {
        return Marker(
          markerId: MarkerId(d.name),
          position: _kokrajharCenter, // In a real app, use d.lat/d.lng
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          infoWindow: InfoWindow(title: d.name),
        );
      }).toSet();
    });
  }

  void _updateActiveDriverMarker(double lat, double lng) {
    LatLng newPos = LatLng(lat, lng);
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId("active_driver"),
          position: newPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: activeDriver?.name ?? "Your Driver"),
        ),
      );
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(newPos));
  }

  bool get canFindDriver => !loading && tripState == "IDLE";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kokrajhar Cab 🚕"), backgroundColor: Colors.yellow[700]),
      body: Column(
        children: [
          // MAP SECTION
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(target: _kokrajharCenter, zoom: 14),
              onMapCreated: (controller) => _mapController = controller,
              markers: _markers,
              myLocationButtonEnabled: false,
            ),
          ),
          
          // UI PANEL SECTION
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (canFindDriver) ...[
                      TextField(controller: pickupController, decoration: const InputDecoration(labelText: "Pickup", prefixIcon: Icon(Icons.circle, size: 12, color: Colors.green))),
                      TextField(controller: dropController, decoration: const InputDecoration(labelText: "Drop", prefixIcon: Icon(Icons.square, size: 12, color: Colors.red))),
                      const SizedBox(height: 10),
                      ElevatedButton(onPressed: _onFindDriver, child: const Text("Book Now")),
                    ] else ...[
                      Text("Status: $status", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text("Driver: ${activeDriver?.name ?? 'Assigning...'}", style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 10),
                      if (tripState == "ASSIGNED") ElevatedButton(onPressed: _onStartTrip, child: const Text("Simulator: Start Trip")),
                      if (tripState == "IN_PROGRESS") ElevatedButton(onPressed: _onCompleteTrip, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text("Simulator: End Trip")),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Actions
  Future<void> _onFindDriver() async {
    if (pickupController.text.isEmpty || dropController.text.isEmpty) return;
    setState(() { loading = true; status = "Booking..."; });
    try {
      final tripData = await CabApi.bookRide(pickupController.text, dropController.text);
      currentTripId = tripData["tripId"];
      SocketService.joinTrip(currentTripId!);
      await _syncState();
    } catch (e) {
      setState(() => status = "No Drivers Found");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _onStartTrip() async => await CabApi.startTrip(currentTripId!);
  Future<void> _onCompleteTrip() async => await CabApi.completeTrip(currentTripId!);
}