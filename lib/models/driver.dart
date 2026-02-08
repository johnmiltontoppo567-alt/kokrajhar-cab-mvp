class Driver {
  final String name;
  final bool online;
  final int distance;

  Driver({
    required this.name,
    required this.online,
    required this.distance,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      name: json['name'],
      online: json['online'],
      distance: json['distance'],
    );
  }
}
