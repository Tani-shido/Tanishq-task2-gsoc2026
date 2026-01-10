import 'package:dartssh2/dartssh2.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LGConnection {
  SSHClient? _client;

  // Connection Funtion
  Future<bool> connect() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String username = prefs.getString("lg_username") ?? "lg";
      String password = prefs.getString("lg_password") ?? "lqgalaxy";
      String ip = prefs.getString("lg_ip") ?? "192.168.1.1";
      int port = int.parse(prefs.getString("lg_port") ?? "22");
      int numberOfRigs = int.parse(prefs.getString("lg_numberOfRigs") ?? "3");

      final socket = await SSHSocket.connect(ip, port);

      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      print("Connected to Liquid Galaxy with ip: $ip");
      return true;
    } catch (e) {
      print("Failed to connect with LG rig: $e");
      return false;
    }
  }

  // Connected to the rig
  // Now, We will be sending confidentials to the rig with sendcommand function

  Future<void> sendCommand(String command) async {
    if (_client == null || _client!.isClosed) {
      bool connected = await connect();
      print("Conecting...");

      if (!connected) {
        print("Unable to connect.");
        return;
      }
    }

    try {
      await _client!.run(command);
      print("Sucess! Command sent: $command");
    } catch (e) {
      print("Falied! Command not sent: $e");
    }
  }

  void disconnect() {
    _client?.close();
    print("Disconnected from LG rig.");
  }
}
