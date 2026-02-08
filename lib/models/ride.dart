class Ride {
  final String pickup;
  final String drop;
  final String driver;
  final String time;

  Ride({
    required this.pickup,
    required this.drop,
    required this.driver,
    required this.time,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      pickup: json['pickup'],
      drop: json['drop'],
      driver: json['driver'],
      time: json['time'],
    );
  }
}
