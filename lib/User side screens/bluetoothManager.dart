import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class BluetoothManager {
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;
  BluetoothDevice? connectedDevice;

 Future<void> connectToPrinter(BluetoothDevice device) async {
  try {
    print('Attempting to connect to ${device.name} (${device.address})');
    if (connectedDevice != device) {
      if (connectedDevice != null) {
        await printer.disconnect(); // Disconnect from current device if needed
        print('Disconnected from previous device');
      }
      await printer.connect(device); // Connect to the selected device
      connectedDevice = device; // Update connected device
      print('Connected to ${device.name} (${device.address})');
    }
  } catch (e) {
    print('Error connecting to printer: $e');
  }
}

Future<void> disconnectPrinter() async {
  try {
    print('Attempting to disconnect from ${connectedDevice?.name}');
    if (connectedDevice != null) {
      await printer.disconnect();
      print('Disconnected from ${connectedDevice?.name}');
      connectedDevice = null; // Update connected device
    }
  } catch (e) {
    print('Error disconnecting from printer: $e');
  }
}


  Future<List<BluetoothDevice>> getAvailableDevices() async {
    try {
      return await printer.getBondedDevices();
    } catch (e) {
      print('Error fetching available devices: $e');
      return [];
    }
  }

  bool isConnected() {
     print('Disconnected from ${connectedDevice?.name}');
    return connectedDevice != null;
  }
}
