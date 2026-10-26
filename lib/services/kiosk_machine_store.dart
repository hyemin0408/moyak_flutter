import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/kiosk_machine.dart';

/// Installation setting, scoped to the server. Contains no member or QR data.
class KioskMachineStore {
  const KioskMachineStore();
  static const _channel = MethodChannel('moyak/order_recovery');
  String _key(String server) => 'installation_machine_v1:$server';

  Future<KioskMachine?> read(String server) async {
    final value = await _channel.invokeMethod<String>('read', {
      'key': _key(server),
    });
    return value == null ? null : KioskMachine.fromJson(jsonDecode(value));
  }

  Future<void> write(String server, KioskMachine machine) async {
    final ok = await _channel.invokeMethod<bool>('write', {
      'key': _key(server),
      'value': jsonEncode(machine.toJson()),
    });
    if (ok != true) throw StateError('Machine setting could not be saved');
  }
}
