import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final List<Map<String, String>> _countries = const [
    {"code": "TH", "name": "Thailand"},
    {"code": "US", "name": "USA"},
    {"code": "GB", "name": "UK"},
    {"code": "JP", "name": "Japan"},
    {"code": "AU", "name": "Australia"},
  ];
  String _selectedCountry = "TH";

  final _cityCtl = TextEditingController();
  final _zipCtl  = TextEditingController();
  final _latCtl  = TextEditingController();
  final _lonCtl  = TextEditingController();

  String _iconFor(String cond) {
    cond = cond.toLowerCase();
    if (cond.contains("thunder")) return "assets/lottie/Weather-storm.json";
    if (cond.contains("rain") || cond.contains("drizzle") || cond.contains("shower")) {
      return "assets/lottie/Weather-storm&showers(day).json";
    }
    if (cond.contains("snow")) return "assets/lottie/Weather-snow sunny.json";
    if (cond.contains("mist") || cond.contains("fog") || cond.contains("haze")) {
      return "assets/lottie/Weather-mist.json";
    }
    if (cond.contains("cloud")) return "assets/lottie/Weather-partly cloudy.json";
    return "assets/lottie/clear-day.json";
  }

  bool get _isDayNow {
    if (_weather == null) {
      final h = DateTime.now().hour;
      return h >= 6 && h < 18;
    }
    return _weather!.isDayAtLocation;
  }

  Future<void> _searchByCity() async {
    setState(() { _loading = true; _error = null; });
    try {
      final w = await _svc.getByCityCountry(_cityCtl.text, _selectedCountry, unit: _unit);
      setState(() => _weather = w);
      if (Navigator.canPop(context)) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally { setState(() => _loading = false); }
  }

  Future<void> _searchByZip() async {
    setState(() { _loading = true; _error = null; });
    try {
      final w = await _svc.getByZipCountry(_zipCtl.text, _selectedCountry, unit: _unit);
      setState(() => _weather = w);
      if (Navigator.canPop(context)) Navigator.pop(context);
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
      if (Navigator.canPop(context)) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDay = _isDayNow;
    final bg      = isDay ? Colors.white : Colors.black;
    final onBg    = isDay ? Colors.black87 : Colors.white;
    final onBgSub = isDay ? Colors.black54 : Colors.white70;
    final unitSymbol = _unit.symbol;

    return Scaffold(
      backgroundColor: bg,

      // ✅ ใช้ AppBar ของ Scaffold เพื่อให้ปุ่ม hamburger เปิด drawer ได้อัตโนมัติ
      appBar: AppBar(
        title: Text('Weather App', style: TextStyle(color: onBg)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: onBg), // สีไอคอนเมนู
        systemOverlayStyle: isDay ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      ),

      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const DrawerHeader(child: Text("Search Settings", style: TextStyle(fontSize: 18))),
            DropdownButton<String>(
              value: _selectedCountry,
              isExpanded: true,
              items: _countries
                  .map((c) => DropdownMenuItem(value: c["code"], child: Text(c["name"]!)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCountry = v!),
            ),
            const SizedBox(height: 10),
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
            TextField(controller: _cityCtl, decoration: const InputDecoration(labelText: "City")),
            ElevatedButton(onPressed: _searchByCity, child: const Text("Search by City")),
            const Divider(),
            TextField(controller: _zipCtl, decoration: const InputDecoration(labelText: "Zip Code")),
            ElevatedButton(onPressed: _searchByZip, child: const Text("Search by Zip")),
            const Divider(),
            TextField(controller: _latCtl, decoration: const InputDecoration(labelText: "Latitude")),
            TextField(controller: _lonCtl, decoration: const InputDecoration(labelText: "Longitude")),
            ElevatedButton(onPressed: _searchByLatLon, child: const Text("Search by Lat/Lon")),
          ],
        ),
      ),

      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: bg,
        child: Center(
          child: _loading
              ? CircularProgressIndicator(color: onBg)
              : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text("Error: $_error",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: onBg, fontSize: 16)),
                    )
                  : _weather == null
                      ? Text("กรุณาเลือกวิธีค้นหาจากเมนู",
                          style: TextStyle(color: onBg))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              _iconFor(_weather!.mainCondition),
                              width: 200,
                              height: 200,
                              repeat: true,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _weather!.cityName,
                              style: GoogleFonts.michroma(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: onBg,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                "${_weather!.temperature.toStringAsFixed(1)} $unitSymbol",
                                key: ValueKey("${_weather!.temperature}$_unit"),
                                style: GoogleFonts.michroma(
                                  fontSize: 42,
                                  color: onBg,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _weather!.mainCondition,
                              style: TextStyle(fontSize: 18, color: onBgSub),
                            ),
                          ],
                        ),
        ),
      ),
    );
  }
}
