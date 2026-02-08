import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/driver.dart';

class CabApi {
  // Static userId for MVP. In a real app, this comes from Login/Auth.
  static const String currentUserId = "user_kokrajhar_001";

  static String get baseUrl {
    if (kIsWeb) return "http://localhost:3000";
    if (Platform.isAndroid) return "http://192.168.29.134:3000";
    return "http://localhost:3000";
  }

  // GET /drivers
  static Future<List<Driver>> getDrivers() async {
    final res = await http.get(Uri.parse("$baseUrl/drivers"));
    if (res.statusCode != 200) throw Exception("Failed to load drivers");
    final List data = jsonDecode(res.body);
    return data.map((e) => Driver.fromJson(e)).toList();
  }

  // POST /book (Now sends userId)
  static Future<Map<String, dynamic>> bookRide(String pickup, String drop) async {
    final res = await http.post(
      Uri.parse("$baseUrl/book"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "pickup": pickup,
        "drop": drop,
        "userId": currentUserId, // Added userId
      }),
    );

    final body = jsonDecode(res.body);

    if (res.statusCode == 200) return body; // Returns the new Trip object
    if (res.statusCode == 409) throw Exception("TRIP_ACTIVE");
    if (res.statusCode == 404) throw Exception("NO_DRIVERS");
    throw Exception("UNKNOWN_ERROR");
  }

  // GET /trip-status/:userId
  static Future<Map<String, dynamic>> getTripStatus() async {
    final res = await http.get(Uri.parse("$baseUrl/trip-status/$currentUserId"));
    if (res.statusCode != 200) throw Exception("Failed to fetch trip status");
    return jsonDecode(res.body);
  }

  // PATCH /trip/:tripId (Updated to match REST style)
  static Future<void> updateTripStatus(String tripId, String newState) async {
    final res = await http.patch(
      Uri.parse("$baseUrl/trip/$tripId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"newState": newState}),
    );

    if (res.statusCode != 200) throw Exception("Failed to update trip to $newState");
  }

  // Helper methods for UI convenience
  static Future<void> startTrip(String tripId) => updateTripStatus(tripId, "IN_PROGRESS");
  static Future<void> completeTrip(String tripId) => updateTripStatus(tripId, "COMPLETED");

  static Future<void> resetDrivers() async {
    final res = await http.post(Uri.parse("$baseUrl/reset"));
    if (res.statusCode != 200) throw Exception("Failed to reset system");
  }
}