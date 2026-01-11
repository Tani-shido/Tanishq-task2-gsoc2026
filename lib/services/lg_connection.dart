import 'package:dartssh2/dartssh2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../kml_generator.dart';

class LGConnection {
  SSHClient? _client;

  // 1. CONNECT TO RIG
  Future<bool> connect() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String username = prefs.getString("lg_username") ?? "lg";
      String password = prefs.getString("lg_password") ?? "lqgalaxy";
      String ip = prefs.getString("lg_ip") ?? "192.168.1.1";
      int port = int.parse(prefs.getString("lg_port") ?? "22");

      final socket = await SSHSocket.connect(ip, port);

      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      print("Connected to Liquid Galaxy at $ip");
      return true;
    } catch (e) {
      print("Failed to connect: $e");
      return false;
    }
  }

  // 2. SEND COMMAND (The Workhorse)
  Future<void> sendCommand(String command) async {
    // Check connection first
    if (_client == null || _client!.isClosed) {
      bool connected = await connect();
      if (!connected) {
        print("Cannot send command: Not connected.");
        return;
      }
    }

    try {
      // Run the command on the LG rig
      await _client!.run(command);
    } catch (e) {
      print("Error executing command: $e");
    }
  }

  // 3. INITIALIZE RIG (The "Brain" of your Architecture)
  // This sets up the rig to look for TWO files: logo.kml and content.kml
  Future<void> setupNetworkLink(int webPort) async {
    // This master KML tells Earth to listen to our 2 channels
    String masterKml =
        '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <NetworkLink>
      <name>Logo Layer</name>
      <Link>
        <href>http://localhost:$webPort/logo.kml</href>
        <refreshMode>onInterval</refreshMode>
        <refreshInterval>1</refreshInterval>
      </Link>
    </NetworkLink>
    <NetworkLink>
      <name>Content Layer</name>
      <Link>
        <href>http://localhost:$webPort/content.kml</href>
        <refreshMode>onInterval</refreshMode>
        <refreshInterval>1</refreshInterval>
      </Link>
    </NetworkLink>
  </Document>
</kml>
    ''';

    // 1. Create the Master file
    await sendCommand("echo '$masterKml' > /var/www/html/master.kml");
    // 2. Point the Rig to the Master file
    await sendCommand(
      "echo 'http://localhost:$webPort/master.kml' > /var/www/html/kmls.txt",
    );

    // 3. Create empty files so the rig doesn't show errors
    await cleanLogo();
    await cleanKml();
  }

  // 4. FLY TO (Camera Movement)
  // Uses query.txt driver for smooth motion
  Future<void> flyTo(
    double lat,
    double lng,
    double range,
    double tilt,
    double heading,
  ) async {
    String query =
        "flytoview=<LookAt><longitude>$lng</longitude><latitude>$lat</latitude><range>$range</range><tilt>$tilt</tilt><heading>$heading</heading><gx:altitudeMode>relativeToGround</gx:altitudeMode></LookAt>";
    await sendCommand("echo '$query' > /tmp/query.txt");
  }

  // 5. UPLOAD LOGO (Updates only the logo file)
  Future<void> uploadLogo(String kml) async {
    await sendCommand("echo '$kml' > /var/www/html/logo.kml");
  }

  // 6. UPLOAD CONTENT (Updates only the pyramid/shapes)
  Future<void> uploadPyramid(String kml) async {
    await sendCommand("echo '$kml' > /var/www/html/content.kml");
  }

  // 7. CLEAN LOGO
  Future<void> cleanLogo() async {
    // Assuming you have a 'blankKml' method in KmlGenerator
    await sendCommand(
      "echo '${KmlGenerator.blankKml('logo')}' > /var/www/html/logo.kml",
    );
  }

  // 8. CLEAN CONTENT
  Future<void> cleanKml() async {
    await sendCommand(
      "echo '${KmlGenerator.blankKml('content')}' > /var/www/html/content.kml",
    );
  }

  // 9. DISCONNECT
  void disconnect() {
    _client?.close();
    print("Disconnected.");
  }
}
