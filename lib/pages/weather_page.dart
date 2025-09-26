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
  final _svc = WeatherServices("2455e0e548eb74bef9136e56e7715895"); // API key

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

  // -------- gradient พื้นหลังชั้นล่าง (เปลี่ยนตามสภาพอากาศ) --------
  List<Color> _bgColors = const [Color(0xFF2196F3), Color(0xFF3F51B5)];
  List<Color> _colorsFor(String cond) {
    cond = cond.toLowerCase();
    if (cond.contains("thunder")) return const [Color(0xFF0F172A), Color(0xFF334155)];
    if (cond.contains("rain") || cond.contains("drizzle") || cond.contains("shower")) {
      return const [Color(0xFF4F46E5), Color(0xFF0EA5E9)];
    }
    if (cond.contains("snow")) return const [Color(0xFF93C5FD), Color(0xFFFFFFFF)];
    if (cond.contains("mist") || cond.contains("fog") || cond.contains("haze")) {
      return const [Color(0xFF94A3B8), Color(0xFF64748B)];
    }
    if (cond.contains("cloud")) return const [Color(0xFF60A5FA), Color(0xFF1E40AF)];
    return const [Color(0xFFFFA000), Color(0xFF1976D2)]; // clear/default
  }

  // -------- ไอคอนสภาพอากาศตรงกลาง --------
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

  // -------- Lottie พื้นหลัง Sun/Moon (เต็มจอ) --------
  String get _dayBg => 'assets/lottie/Sun Rising.json';
  String get _nightBg => 'assets/lottie/Moon Animation.json';
  bool get _isDayNow {
    if (_weather == null) {
      final h = DateTime.now().hour; // fallback ชั่วคราวก่อนมีข้อมูลเมือง
      return h >= 6 && h < 18;
    }
    return _weather!.isDayAtLocation;
  }
  String get _bgLottie => _isDayNow ? _dayBg : _nightBg;

  // -------- ค้นหา --------
  Future<void> _searchByCity() async {
    setState(() { _loading = true; _error = null; });
    try {
      final w = await _svc.getByCityCountry(_cityCtl.text, _selectedCountry, unit: _unit);
      _applyWeather(w);
      if (Navigator.canPop(context)) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally { setState(() => _loading = false); }
  }

  Future<void> _searchByZip() async {
    setState(() { _loading = true; _error = null; });
    try {
      final w = await _svc.getByZipCountry(_zipCtl.text, _selectedCountry, unit: _unit);
      _applyWeather(w);
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
      _applyWeather(w);
      if (Navigator.canPop(context)) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally { setState(() => _loading = false); }
  }

  void _applyWeather(Weather w) {
    setState(() {
      _weather = w;
      _bgColors = _colorsFor(w.mainCondition); // อัปเดตสี gradient
    });
  }

  @override
  Widget build(BuildContext context) {
    final unitSymbol = _unit.symbol;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Weather App"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
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

      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1) gradient ชั้นล่าง
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _bgColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 2) Lottie พื้นหลัง Sun/Moon แบบเต็มจอ
          IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: SizedBox.expand(
                key: ValueKey(_bgLottie),
                child: Lottie.asset(
                  _bgLottie,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  repeat: true,
                ),
              ),
            ),
          ),

          // 3) ฟิล์มบางๆ ให้อ่านตัวหนังสือชัด
          Container(color: Colors.black.withOpacity(0.10)),

          // 4) เนื้อหา
          Center(
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          "Error: $_error",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      )
                    : _weather == null
                        ? const Text("กรุณาเลือกวิธีค้นหาจาก Drawer",
                            style: TextStyle(color: Colors.white))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                              ),
                              const SizedBox(height: 6),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
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
        ],
      ),
    );
  }
}
