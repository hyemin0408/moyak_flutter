import 'dart:convert';

import 'package:flutter/services.dart';

/// Minimal operational journal. No tokens, names, products or payment details.
class OrderRecoveryRecord {
  const OrderRecoveryRecord({this.orderId, required this.uncertain});
  final String? orderId;
  final bool uncertain;
  String encode() =>
      jsonEncode({'v': 1, 'order_id': orderId, 'uncertain': uncertain});
  factory OrderRecoveryRecord.decode(String value) {
    final j = jsonDecode(value);
    if (j is! Map ||
        j['v'] != 1 ||
        j['uncertain'] is! bool ||
        (j['order_id'] != null &&
            (j['order_id'] is! String || (j['order_id'] as String).isEmpty))) {
      throw const FormatException('Invalid recovery journal');
    }
    return OrderRecoveryRecord(
      orderId: j['order_id'] as String?,
      uncertain: j['uncertain'] as bool,
    );
  }
}

abstract interface class OrderRecoveryStore {
  Future<OrderRecoveryRecord?> read(String key);
  Future<void> write(String key, OrderRecoveryRecord? record);
}

/// Injected in isolated tests. Normal Android launch uses the durable store.
class MemoryOrderRecoveryStore implements OrderRecoveryStore {
  final Map<String, String> _values = {};
  @override
  Future<OrderRecoveryRecord?> read(String key) async =>
      _values[key] == null ? null : OrderRecoveryRecord.decode(_values[key]!);
  @override
  Future<void> write(String key, OrderRecoveryRecord? record) async {
    if (record == null) {
      _values.remove(key);
    } else {
      _values[key] = record.encode();
    }
  }
}

/// Android SharedPreferences.commit completes before any order POST is sent.
/// Unsupported platforms fail closed instead of silently losing recovery state.
class PlatformOrderRecoveryStore implements OrderRecoveryStore {
  const PlatformOrderRecoveryStore();
  static const _channel = MethodChannel('moyak/order_recovery');
  @override
  Future<OrderRecoveryRecord?> read(String key) async {
    final value = await _channel.invokeMethod<String>('read', {'key': key});
    return value == null ? null : OrderRecoveryRecord.decode(value);
  }

  @override
  Future<void> write(String key, OrderRecoveryRecord? record) async {
    final ok = await _channel.invokeMethod<bool>('write', {
      'key': key,
      'value': record?.encode(),
    });
    if (ok != true) throw StateError('Recovery journal write failed');
  }
}
