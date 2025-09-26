class Weather {
  final String cityName;
  final double temperature;
  final String mainCondition;

  // ใช้เลือก Sun/Moon ตามเวลาท้องถิ่นของเมืองนั้น
  final int sunrise;         // unix seconds (UTC)
  final int sunset;          // unix seconds (UTC)
  final int timezoneOffset;  // seconds from UTC

  Weather({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.sunrise,
    required this.sunset,
    required this.timezoneOffset,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    final sys = (json['sys'] ?? {}) as Map<String, dynamic>;
    return Weather(
      cityName: (json['name'] ?? '-') as String,
      temperature: (json['main']['temp'] as num).toDouble(),
      mainCondition: (json['weather']?[0]?['main'] ?? '-').toString(),
      sunrise: (sys['sunrise'] ?? 0) as int,
      sunset: (sys['sunset'] ?? 0) as int,
      timezoneOffset: (json['timezone'] ?? 0) as int,
    );
  }

  /// true ถ้าตอนนี้ (ตามเวลาท้องถิ่นของเมืองนั้น) อยู่ระหว่างพระอาทิตย์ขึ้น–ตก
  bool get isDayAtLocation {
    final nowLocal =
        DateTime.now().toUtc().add(Duration(seconds: timezoneOffset));
    final sunriseLocal = DateTime.fromMillisecondsSinceEpoch(sunrise * 1000, isUtc: true)
        .add(Duration(seconds: timezoneOffset));
    final sunsetLocal = DateTime.fromMillisecondsSinceEpoch(sunset * 1000, isUtc: true)
        .add(Duration(seconds: timezoneOffset));
    return nowLocal.isAfter(sunriseLocal) && nowLocal.isBefore(sunsetLocal);
  }
}
