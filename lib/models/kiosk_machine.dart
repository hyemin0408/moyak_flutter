import 'moyak_api_models.dart';

/// Map UUID and kiosk code are different identifiers. Orders use code only.
class KioskMachine {
  const KioskMachine({
    required this.code,
    required this.name,
    required this.address,
  });
  final String code, name, address;

  factory KioskMachine.fromJson(Object? value) {
    final json = apiObject(value);
    final code = apiString(json, 'code').trim();
    final name = apiString(json, 'name').trim();
    if (code.isEmpty || name.isEmpty) {
      throw const FormatException('Missing machine code or name');
    }
    return KioskMachine(
      code: code,
      name: name,
      address: apiString(json, 'address'),
    );
  }

  Map<String, String> toJson() => {
    'code': code,
    'name': name,
    'address': address,
  };
}
