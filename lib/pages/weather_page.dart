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

  // ---------------- Animation state ----------------
  // เก็บสี gradient ปัจจุบันไว้ให้ AnimatedContainer lerp ไป-มา
  List<Color> _bgColors = const [Color(0xFF2196F3), Color(0xFF3F51B5)];

  // ช่วยเลือกสีตามสภาพอากาศ
  List<Color> _colorsFor(String cond) {
    cond = cond.toLowerCase();
    if (cond.contains("thunder")) {
      return const [Color(0xFF0F172A), Color(0xFF334155)]; // เข้มฟ้าคราม
    }
    if (cond.contains("rain") || cond.contains("drizzle") || cond.contains("shower")) {
      return const [Color(0xFF4F46E5), Color(0xFF0EA5E9)]; // ม่วงน้ำเงิน → ฟ้า
    }
    if (cond.contains("snow")) {
      return const [Color(0xFF93C5FD), Color(0xFFFFFFFF)]; // ฟ้าอ่อน → ขาว
    }
    if (cond.contains("mist") || cond.contains("fog") || cond.contains("haze")) {
      return const [Color(0xFF94A3B8), Color(0xFF64748B)]; // เทาอมฟ้า
    }
    if (cond.contains("cloud")) {
      return const [Color(0xFF60A5FA), Color(0xFF1E40AF)]; // ฟ้า → น้ำเงินเข้ม
    }
    // clear / default
    return const [Color(0xFFFFA000), Color(0xFF1976D2)]; // ส้มอุ่น → น้ำเงินใส
  }

  // Lottie ตามสภาพอากาศ
  String _assetFor(String cond) {
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

  // ---------------- Search handlers ----------------
  Future<void> _searchByCity() async {
    setState(() { _loading = true; _error = null; });
    try {
      final w = await _svc.getByCityCountry(_cityCtl.text, _selectedCountry, unit: _unit);
      _applyWeather(w);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally { setState(() => _loading = false); }
  }

  Future<void> _searchByZip() async {
    setState(() { _loading = true; _error = null; });
    try {
      final w = await _svc.getByZipCountry(_zipCtl.text, _selectedCountry, unit: _unit);
      _applyWeather(w);
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
      _applyWeather(w);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally { setState(() => _loading = false); }
  }

  // เมื่อได้ผลลัพธ์ใหม่ อัปเดตทั้งข้อมูลและสีพื้นหลัง
  void _applyWeather(Weather w) {
    final nextColors = _colorsFor(w.mainCondition);
    setState(() {
      _weather = w;
      _bgColors = nextColors;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unitSymbol = _unit.symbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Weather App"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
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
            // ชื่อเมือง
            TextField(controller: _cityCtl, decoration: const InputDecoration(labelText: "City")),
            ElevatedButton(onPressed: _searchByCity, child: const Text("Search by City")),
            const Divider(),
            // Zip
            TextField(controller: _zipCtl, decoration: const InputDecoration(labelText: "Zip Code")),
            ElevatedButton(onPressed: _searchByZip, child: const Text("Search by Zip")),
            const Divider(),
            // Lat/Lon
            TextField(controller: _latCtl, decoration: const InputDecoration(labelText: "Latitude")),
            TextField(controller: _lonCtl, decoration: const InputDecoration(labelText: "Longitude")),
            ElevatedButton(onPressed: _searchByLatLon, child: const Text("Search by Lat/Lon")),
          ],
        ),
      ),

      // ---------------- 🎞️ Animated background ----------------
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _bgColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: _loading
              ? const CircularProgressIndicator(color: Colors.white)
              : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text("Error: $_error",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 16)),
                    )
                  : _weather == null
                      ? const Text("กรุณาเลือกวิธีค้นหาจาก Drawer",
                          style: TextStyle(color: Colors.white))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Lottie (เปลี่ยนพร้อมกัน)
                            Lottie.asset(
                              _assetFor(_weather!.mainCondition),
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
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 6),

                            // ---------------- 🔢 Temperature with AnimatedSwitcher
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder: (child, anim) => SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, .2),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOutCubic,
                                )),
                                child: FadeTransition(opacity: anim, child: child),
                              ),
                              child: Text(
                                "${_weather!.temperature.toStringAsFixed(1)} $unitSymbol",
                                key: ValueKey("${_weather!.temperature}$_unit"),
                                style: GoogleFonts.michroma(
                                  fontSize: 42,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              _weather!.mainCondition,
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ],
                        ),
        ),
      ),
    );
  }
}
