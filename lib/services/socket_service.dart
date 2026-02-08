import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/cab_api.dart';

class SocketService {
  static IO.Socket? _socket;

  // Initialize the socket connection globally
  static void init() {
    if (_socket != null) return;

    _socket = IO.io(CabApi.baseUrl, 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .build()
    );

    _socket!.onConnect((_) => print('Connected to Socket.io Server'));
  }

  // Join a specific trip room
  static void joinTrip(String tripId) {
    _socket?.emit('join_trip', tripId);
  }

  // Listen for specific events (trip updates or global driver updates)
  static void onEvent(String eventName, Function(dynamic) handler) {
    _socket?.on(eventName, handler);
  }

// Listen for the car moving
  static void onLocationUpdate(Function(double lat, double lng) onLocation) {
    _socket?.on('driver_location', (data) {
      onLocation(data['lat'], data['lng']);
    });
  }
  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}