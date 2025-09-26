import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

enum TempUnit { celsius, fahrenheit, kelvin }

extension TempUnitX on TempUnit {
  String get apiUnits {
    switch (this) {
      case TempUnit.celsius:
        return 'metric';
      case TempUnit.fahrenheit:
        return 'imperial';
      case TempUnit.kelvin:
        return 'standard';
    }
  }

  String get symbol {
    switch (this) {
      case TempUnit.celsius:
        return '°C';
      case TempUnit.fahrenheit:
        return '°F';
      case TempUnit.kelvin:
        return 'K';
    }
  }
}

class WeatherServices {
  final String apiKey;
  WeatherServices(this.apiKey);

  static const _base = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Weather> getByCoords(double lat, double lon, {TempUnit unit = TempUnit.celsius}) async {
    final uri = Uri.parse('$_base?lat=$lat&lon=$lon&appid=$apiKey&units=${unit.apiUnits}');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('OPENWEATHER_${res.statusCode}');
    }
    return Weather.fromJson(jsonDecode(res.body));
  }

  Future<Weather> getByCityCountry(String city, String countryCode, {TempUnit unit = TempUnit.celsius}) async {
    final q = Uri.encodeQueryComponent('${city.trim()},${countryCode.trim()}');
    final uri = Uri.parse('$_base?q=$q&appid=$apiKey&units=${unit.apiUnits}');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('CITY_NOT_FOUND');
    }
    return Weather.fromJson(jsonDecode(res.body));
  }

  Future<Weather> getByZipCountry(String zip, String countryCode, {TempUnit unit = TempUnit.celsius}) async {
    final q = Uri.encodeQueryComponent('${zip.trim()},${countryCode.trim()}');
    final uri = Uri.parse('$_base?zip=$q&appid=$apiKey&units=${unit.apiUnits}');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('ZIP_NOT_FOUND');
    }
    return Weather.fromJson(jsonDecode(res.body));
  }
}
