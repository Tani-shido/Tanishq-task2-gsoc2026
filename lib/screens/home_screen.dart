import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/lg_connection.dart';
import '../kml_generator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LGConnection _lg = LGConnection();
  final TextEditingController _ipController = TextEditingController();
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString("lg_ip") ?? "192.168.1.1";
    });
  }

  void _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("lg_ip", _ipController.text);
    // You might want to save username/pass/port here too if you make UI for them
    await prefs.setString("lg_username", "lg");
    await prefs.setString("lg_password", "lqgalaxy");
    await prefs.setString("lg_port", "22");

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Settings saved.")));
  }

  // Helper: Find the web port (81, 80, or 8080)
  Future<int?> _findWorkingPort(String ip) async {
    List<int> portsToCheck = [81, 80, 8080];
    for (int port in portsToCheck) {
      try {
        final socket = await Socket.connect(
          ip,
          port,
          timeout: const Duration(milliseconds: 500),
        );
        socket.destroy();
        return port;
      } catch (e) {
        // Continue to next port
      }
    }
    return null;
  }

  // --- CORE FEATURE: INITIALIZATION ---
  // This sets up the "Master Network Link" so we can have layers
  void _initializeLgRig() async {
    String rigIp = _ipController.text;
    int? validPort = await _findWorkingPort(rigIp);

    if (validPort == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Could not find working Web Port (80, 81, 8080). Check LG connection.",
          ),
        ),
      );
      return;
    }

    // Call the new method in LGConnection
    await _lg.setupNetworkLink(validPort);

    setState(() {
      _isConnected = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Rig Initialized! Master Link set on port $validPort"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LG Controller"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- SETTINGS SECTION ---
            const Text(
              "Settings",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(labelText: "LG IP Address"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text("Save Settings"),
            ),

            const Divider(height: 30, thickness: 2),

            // --- INITIALIZATION SECTION ---
            const Text(
              "Step 1: Connection",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: _initializeLgRig,
              child: const Text("INITIALIZE RIG (Run This First)"),
            ),
            const SizedBox(height: 20),

            // --- FEATURES SECTION ---
            const Text(
              "Step 2: Features",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // FEATURE 1: SHOW LOGO
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text("Show LG Logo (Overlay)"),
              onPressed: () async {
                // Link to the image URL provided
                String logoKml = KmlGenerator.logoScreenOverlay(
                  "https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEgXmdNgBTXup6bdWew5RzgCmC9pPb7rK487CpiscWB2S8OlhwFHmeeACHIIjx4B5-Iv-t95mNUx0JhB_oATG3-Tq1gs8Uj0-Xb9Njye6rHtKKsnJQJlzZqJxMDnj_2TXX3eA5x6VSgc8aw/s320-rw/LOGO+LIQUID+GALAXY-sq1000-+OKnoline.png",
                  1.0,
                );
                await _lg.uploadLogo(logoKml);
              },
            ),

            // FEATURE 2: PYRAMID & FLY TO
            ElevatedButton.icon(
              icon: const Icon(Icons.landscape),
              label: const Text("Show 3D Pyramid & Fly To"),
              onPressed: () async {
                // 1. Send the Geometry (Pyramid)
                String pyramidKml = KmlGenerator.pyramidGenaration(
                  23.2599,
                  77.4126,
                  0.005,
                ); // Bhopal
                await _lg.uploadPyramid(pyramidKml);

                // 2. Wait a moment for KML to load on the rig
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Shape sent... flying in 2 seconds."),
                  ),
                );
                await Future.delayed(const Duration(seconds: 2));

                // 3. Send FlyTo Command (Driver)
                // 5000m range, 45 degree tilt
                await _lg.flyTo(23.2599, 77.4126, 5000, 45, 0);
              },
            ),

            // FEATURE 3: FLY TO HOME CITY
            ElevatedButton.icon(
              icon: const Icon(Icons.flight_takeoff),
              label: const Text("Fly To Bhopal (Home City)"),
              onPressed: () async {
                await _lg.flyTo(
                  23.2599,
                  77.4126,
                  10000,
                  0,
                  0,
                ); // Higher view (10km), looking straight down
              },
            ),

            const Divider(height: 30),

            // --- CLEANING SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: () async => await _lg.cleanLogo(),
                    child: const Text("Clean Logo"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async => await _lg.cleanKml(),
                    child: const Text("Clean Shapes"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
