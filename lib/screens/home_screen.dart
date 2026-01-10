import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/lg_connection.dart';
import 'dart:io';
import '../kml_generator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LGConnection _lg = LGConnection();
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // this will load ip from local storage
  void _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _ipController.text = prefs.getString("lg_ip") ?? "192.168.1.1";
    });
  }

  // This fn will save ip to local storage
  void _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString("lg_ip", _ipController.text);

    await prefs.setString("lg_username", "lg");
    await prefs.setString("lg_password", "lqgalaxy");
    await prefs.setString("lg_port", "22");

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Settings saved.")));
  }

  // This fn is for finding working web port
  Future<int?> _findWorkingPort(String ip) async {
    List<int> portsToCheck = [81, 80, 8080];

    for (int port in portsToCheck) {
      try {
        final socket = await Socket.connect(
          ip,
          port,
          timeout: Duration(milliseconds: 500),
        );
        socket.destroy();
        print("Port $port is working");
        return port;
      } catch (e) {
        print("Port $port is not working: $e");
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Liquid Galaxy Controller")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Settings",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _ipController,
              decoration: InputDecoration(labelText: "LG IP Address"),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text("Save Settings"),
            ),

            const Divider(height: 40, thickness: 2),

            const Text(
              "Controls",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
              ),
              // KML for Bhopal
              onPressed: () async {
                String rigIp = _ipController.text;

                int? validPort = await _findWorkingPort(rigIp);

                if (validPort == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Web Port [80, 81, 8080] not found."),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                String kml = KmlGenerator.createPin("Bhopal", 23.2599, 77.4126);

                await _lg.sendCommand("echo '$kml' > /var/www/html/kmls.kml");
                await _lg.sendCommand(
                  "echo 'http://localhost:$validPort/kmls.kml' > /var/www/html/kmls.txt",
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "KML for Bhopal sent to LG rig using port $validPort.",
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text("Send KML for Bhopal"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () async {
                await _lg.sendCommand("echo '' > /var/www/html/kmls.txt");
              },
              child: Text("Clear KML"),
            ),
          ],
        ),
      ),
    );
  }
}
