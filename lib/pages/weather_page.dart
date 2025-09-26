import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../models/weather_model.dart';
import '../services/weather_services.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _svc = WeatherServices("2455e0e548eb74bef9136e56e7715895");

  Weather? _weather;
  bool _loading = false;
  String? _error;

  TempUnit _unit = TempUnit.celsius;

  // รายชื่อประเทศให้เลือก
  final List<Map<String, String>> _countries = const [
    {"code": "TH", "name": "Thailand"},
    {"code": "US", "name": "USA"},
    {"code": "GB", "name": "UK"},
    {"code": "JP", "name": "Japan"},
    {"code": "AU", "name": "Australia"},
  ];
  String _selectedCountry = "TH";

  // controllers
  final _cityCtl = TextEditingController();
  final _zipCtl = TextEditingController();
  final _latCtl = TextEditingController();
  final _lonCtl = TextEditingController();

  Future<void> _searchByCity() async {
    setState(() { _loading = true; _error = null; });
    try {
      final w = await _svc.getByCityCountry(_cityCtl.text, _selectedCountry, unit: _unit);
      setState(() => _weather = w);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally { setState(() => _loading = false); }
  }

  Future<void> _searchByZip() async {
    setState(() { _loading = true; _error = null; });
    try {
      final w = await _svc.getByZipCountry(_zipCtl.text, _selectedCountry, unit: _unit);
      setState(() => _weather = w);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally { setState(() => _loading = false); }
  }

  Future<void> _searchByLatLon() async {
    final lat = double.tryParse(_latCtl.text);
    final lon = double.tryParse(_lonCtl.text);
    if (lat == null || lon == null) {
      setState(() => _error = "กรอกพิกัดไม่ถูกต้อง");
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final w = await _svc.getByCoords(lat, lon, unit: _unit);
      setState(() => _weather = w);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally { setState(() => _loading = false); }
  }

  String _assetFor(String cond) {
    cond = cond.toLowerCase();
    if (cond.contains("rain")) return "assets/lottie/Weather-storm&showers(day).json";
    if (cond.contains("cloud")) return "assets/lottie/Weather-partly cloudy.json";
    if (cond.contains("snow")) return "assets/lottie/Weather-snow sunny.json";
    return "assets/lottie/clear-day.json";
  }

  @override
  Widget build(BuildContext context) {
    final unitSymbol = _unit.symbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Weather App"),
        backgroundColor: Colors.blue,
      ),
      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const DrawerHeader(
              child: Text("Search Settings", style: TextStyle(fontSize: 18)),
            ),
            // เลือกประเทศ
            DropdownButton<String>(
              value: _selectedCountry,
              isExpanded: true,
              items: _countries.map((c) {
                return DropdownMenuItem(
                  value: c["code"],
                  child: Text(c["name"]!),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCountry = v!),
            ),
            const SizedBox(height: 10),
            // เลือกหน่วย
            DropdownButton<TempUnit>(
              value: _unit,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: TempUnit.celsius, child: Text("Celsius (°C)")),
                DropdownMenuItem(value: TempUnit.fahrenheit, child: Text("Fahrenheit (°F)")),
                DropdownMenuItem(value: TempUnit.kelvin, child: Text("Kelvin (K)")),
              ],
              onChanged: (v) => setState(() => _unit = v!),
            ),
            const Divider(),

            // ฟอร์มกรอกชื่อเมือง
            TextField(controller: _cityCtl, decoration: const InputDecoration(labelText: "City")),
            ElevatedButton(onPressed: _searchByCity, child: const Text("Search by City")),

            const Divider(),
            // ฟอร์ม Zip
            TextField(controller: _zipCtl, decoration: const InputDecoration(labelText: "Zip Code")),
            ElevatedButton(onPressed: _searchByZip, child: const Text("Search by Zip")),

            const Divider(),
            // ฟอร์ม Lat/Lon
            TextField(controller: _latCtl, decoration: const InputDecoration(labelText: "Latitude")),
            TextField(controller: _lonCtl, decoration: const InputDecoration(labelText: "Longitude")),
            ElevatedButton(onPressed: _searchByLatLon, child: const Text("Search by Lat/Lon")),
          ],
        ),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _error != null
                ? Text("Error: $_error", style: const TextStyle(color: Colors.red))
                : _weather == null
                    ? const Text("กรุณาเลือกวิธีค้นหาจาก Drawer")
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            _assetFor(_weather!.mainCondition),
                            width: 180,
                            height: 180,
                          ),
                          Text(
                            _weather!.cityName,
                            style: GoogleFonts.michroma(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${_weather!.temperature.toStringAsFixed(1)} $unitSymbol",
                            style: GoogleFonts.michroma(fontSize: 40, color: Colors.blue),
                          ),
                          Text(
                            _weather!.mainCondition,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
      ),
    );
  }
}
