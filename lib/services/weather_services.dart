import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

enum TempUnit { celsius, fahrenheit, kelvin }

extension TempUnitX on TempUnit {
  String get apiUnits {
    switch (this) {
      case TempUnit.celsius: return 'metric';
      case TempUnit.fahrenheit: return 'imperial';
      case TempUnit.kelvin: return 'standard';
    }
  }

  String get symbol {
    switch (this) {
      case TempUnit.celsius: return '°C';
      case TempUnit.fahrenheit: return '°F';
      case TempUnit.kelvin: return 'K';
    }
  }
}

class WeatherServices {
  final String apiKey;
  WeatherServices(this.apiKey);

  static const _base = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Weather> _fetch(Uri uri) async {
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('HTTP_${res.statusCode}: ${res.body}');
    }
    return Weather.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Weather> getByCoords(double lat, double lon, {TempUnit unit = TempUnit.celsius}) {
    final uri = Uri.parse('$_base?lat=$lat&lon=$lon&appid=$apiKey&units=${unit.apiUnits}');
    return _fetch(uri);
  }

  Future<Weather> getByCityCountry(String city, String country, {TempUnit unit = TempUnit.celsius}) {
    final q = Uri.encodeQueryComponent('${city.trim()},${country.trim()}');
    final uri = Uri.parse('$_base?q=$q&appid=$apiKey&units=${unit.apiUnits}');
    return _fetch(uri);
  }

  Future<Weather> getByZipCountry(String zip, String country, {TempUnit unit = TempUnit.celsius}) {
    final q = Uri.encodeQueryComponent('${zip.trim()},${country.trim()}');
    final uri = Uri.parse('$_base?zip=$q&appid=$apiKey&units=${unit.apiUnits}');
    return _fetch(uri);
  }
}
