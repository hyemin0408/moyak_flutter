/// Wire models checked against moyak-backend/src/api/routes (2026-10-21).
/// Independent of design-only products, approval examples and kiosk UI state.
Map<String, dynamic> apiObject(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected object');
  }
  return value;
}

String apiString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('Expected string: $key');
  return value;
}

List<T> apiList<T>(Object? value, T Function(Object?) parse) {
  if (value is! List) throw const FormatException('Expected list');
  return List.unmodifiable(value.map(parse));
}

int apiInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int || value < 0) throw FormatException('Invalid $key');
  return value;
}

class KioskProduct {
  KioskProduct.fromJson(Object? value) {
    final j = apiObject(value);
    id = apiString(j, 'id');
    if (id.isEmpty) throw const FormatException('Empty product id');
    itemSeq = apiString(j, 'item_seq');
    name = apiString(j, 'item_name');
    company = apiString(j, 'company');
    category = apiString(j, 'category');
    badge = j['badge'] == null ? '' : apiString(j, 'badge');
    price = apiInt(j, 'price');
    stock = apiInt(j, 'stock');
  }
  late final String id, itemSeq, name, company, category, badge;
  late final int price, stock;
}

class KioskOrderLine {
  KioskOrderLine.fromJson(Object? value) {
    final j = apiObject(value);
    name = apiString(j, 'item_name');
    price = apiInt(j, 'unit_price');
    quantity = apiInt(j, 'quantity');
    if (quantity == 0) throw const FormatException('Empty order quantity');
  }
  late final String name;
  late final int price, quantity;
}

class KioskOrder {
  KioskOrder.fromJson(Object? value) {
    final j = apiObject(value);
    id = apiString(j, 'id');
    machineId = apiString(j, 'machine_id');
    status = apiString(j, 'status');
    if (!{'cart', 'paid', 'dispensed', 'cancelled'}.contains(status)) {
      throw const FormatException('Unknown order status');
    }
    createdAt = _orderDate(j['created_at']);
    paidAt = _orderDate(j['paid_at']);
    dispensedAt = _orderDate(j['dispensed_at']);
    total = apiInt(j, 'total_amount');
    lines = apiList(j['items'], KioskOrderLine.fromJson);
    if (id.isEmpty ||
        lines.isEmpty ||
        lines.fold<int>(0, (sum, l) => sum + l.price * l.quantity) != total) {
      throw const FormatException('Invalid order total');
    }
  }
  late final String id, machineId, status;
  late final int total;
  late final List<KioskOrderLine> lines;
  late final DateTime? createdAt, paidAt, dispensedAt;
  static DateTime? _orderDate(Object? value) {
    if (value == null) return null;
    if (value is! String) throw const FormatException('Invalid order date');
    return DateTime.parse(
      RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(value) ? value : '${value}Z',
    ).toUtc();
  }
}

class KioskQr {
  KioskQr.fromJson(Object? value) {
    final j = apiObject(value);
    machineId = apiString(j, 'machine_id');
    token = apiString(j, 'qr_token');
    final expiry = apiString(j, 'qr_token_expires_at');
    // Backend uses naive UTC datetime values in some responses.
    expiresAt = DateTime.parse(
      RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(expiry) ? expiry : '${expiry}Z',
    ).toUtc();
    svg = apiString(j, 'qr_svg');
    if (token.isEmpty || !svg.contains('<svg')) {
      throw const FormatException('Invalid QR');
    }
  }
  late final String machineId, token, svg;
  late final DateTime expiresAt;
}

class KioskSession {
  KioskSession.fromJson(Object? value) {
    final j = apiObject(value);
    machineId = apiString(j, 'machine_id');
    if (j['paired'] is! bool) throw const FormatException('Invalid pairing');
    paired = j['paired'] as bool;
    userId = j['user_id'] == null ? null : apiString(j, 'user_id');
    if (paired &&
        (j['user_id'] is! String || (j['user_id'] as String).isEmpty)) {
      throw const FormatException('Missing linked user');
    }
    displayName = j['user_display_name'] == null
        ? null
        : apiString(j, 'user_display_name');
    purchase = j['purchase'] == null
        ? null
        : Map.unmodifiable(apiObject(j['purchase']));
    if (purchase != null) {
      apiString(purchase!, 'id');
      apiString(purchase!, 'drug_item_name');
      apiString(purchase!, 'status');
    }
  }
  late final String machineId;
  late final String? userId;
  late final bool paired;
  late final String? displayName;
  late final Map<String, dynamic>? purchase;
  // get_machine_session returns only PENDING approvals; never revive other states.
  bool get hasPendingPurchase => paired && purchase?['status'] == 'pending';
}

/// Pharmacist approval, separate from the OTC product/order identifiers.
class KioskApprovedPurchase {
  KioskApprovedPurchase.fromJson(Object? value) {
    final j = apiObject(value);
    id = apiString(j, 'id');
    userId = apiString(j, 'user_id');
    itemSeq = apiString(j, 'drug_item_seq');
    name = apiString(j, 'drug_item_name');
    status = apiString(j, 'status');
    price = j['price'] == null ? null : apiInt(j, 'price');
    // Older deployments omit quantity; newer responses price the entire line.
    quantity = j.containsKey('quantity') ? apiInt(j, 'quantity') : 1;
    if (quantity < 1) throw const FormatException('Invalid approved quantity');
    final expiry = apiString(j, 'expires_at');
    expiresAt = DateTime.parse(
      RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(expiry) ? expiry : '${expiry}Z',
    ).toUtc();
    if (id.isEmpty ||
        userId.isEmpty ||
        itemSeq.isEmpty ||
        name.isEmpty ||
        !{'pending', 'expired', 'dispensed', 'cancelled'}.contains(status)) {
      throw const FormatException('Invalid approved purchase');
    }
  }
  late final String id, userId, itemSeq, name, status;
  late final int? price;
  late final int quantity;
  late final DateTime expiresAt;
  bool get available =>
      status == 'pending' && DateTime.now().toUtc().isBefore(expiresAt);
}

class MoyakUser {
  const MoyakUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
  });
  final String id, role;
  final String? username, name;
  String get displayName => name ?? username ?? '회원';

  factory MoyakUser.fromJson(Object? value) {
    final json = apiObject(value);
    final username = json['username'];
    final name = json['name'];
    if ((username != null && username is! String) ||
        (name != null && name is! String)) {
      throw const FormatException('Invalid profile');
    }
    return MoyakUser(
      id: apiString(json, 'id'),
      username: username as String?,
      name: name as String?,
      role: apiString(json, 'role'),
    );
  }
}

class MoyakAuthSession {
  const MoyakAuthSession({
    required this.accessToken,
    required this.user,
    required this.expiresAt,
  });

  /// Memory only. Never log or put this token in a URL or plain preferences.
  final String accessToken;
  final MoyakUser user;
  final DateTime expiresAt;
  bool get isExpired => !DateTime.now().isBefore(expiresAt);

  factory MoyakAuthSession.fromJson(Object? value) {
    final json = apiObject(value);
    final token = apiString(json, 'access_token');
    final type = apiString(json, 'token_type');
    final ttl = json['expires_in'];
    if (token.isEmpty ||
        type.toLowerCase() != 'bearer' ||
        ttl is! int ||
        ttl <= 0 ||
        ttl > 30 * 86400) {
      throw const FormatException('Invalid authentication response');
    }
    return MoyakAuthSession(
      accessToken: token,
      user: MoyakUser.fromJson(json['user']),
      expiresAt: DateTime.now().add(Duration(seconds: ttl)),
    );
  }
}

class MoyakDrug {
  const MoyakDrug({
    required this.itemSeq,
    required this.name,
    required this.company,
  });
  final String itemSeq, name, company;
  factory MoyakDrug.fromJson(Object? value) {
    final json = apiObject(value);
    return MoyakDrug(
      itemSeq: apiString(json, 'item_seq'),
      name: apiString(json, 'item_name'),
      company: apiString(json, 'company'),
    );
  }
}

class MoyakChatMessage {
  const MoyakChatMessage({required this.role, required this.content});
  final String role, content;
  Map<String, String> toJson() => {'role': role, 'content': content};
}

class MoyakEvidence {
  const MoyakEvidence({
    required this.itemName,
    required this.field,
    required this.fieldLabel,
    required this.text,
  });
  final String itemName, field, fieldLabel, text;
  factory MoyakEvidence.fromJson(Object? value) {
    final json = apiObject(value);
    return MoyakEvidence(
      itemName: apiString(json, 'item_name'),
      field: apiString(json, 'field'),
      fieldLabel: apiString(json, 'field_label'),
      text: apiString(json, 'text'),
    );
  }
}

class MoyakRecommendation {
  const MoyakRecommendation({
    required this.rank,
    required this.name,
    required this.reason,
    required this.ingredient,
    required this.caution,
  });
  final int rank;
  final String name, reason, ingredient, caution;
  factory MoyakRecommendation.fromJson(Object? value) {
    final json = apiObject(value);
    final rank = json['rank'];
    if (rank is! int) throw const FormatException('Invalid rank');
    return MoyakRecommendation(
      rank: rank,
      name: apiString(json, 'item_name'),
      reason: apiString(json, 'reason'),
      ingredient: apiString(json, 'ingredient'),
      caution: apiString(json, 'caution'),
    );
  }
}

class MoyakChatAnswer {
  MoyakChatAnswer({
    required this.answer,
    required Iterable<String> sources,
    required Iterable<MoyakEvidence> evidence,
    required Iterable<MoyakRecommendation> recommendations,
  }) : sources = List.unmodifiable(sources),
       evidence = List.unmodifiable(evidence),
       recommendations = List.unmodifiable(recommendations);
  final String answer;
  final List<String> sources;
  final List<MoyakEvidence> evidence;
  final List<MoyakRecommendation> recommendations;
  factory MoyakChatAnswer.fromJson(Object? value) {
    final json = apiObject(value);
    return MoyakChatAnswer(
      answer: apiString(json, 'answer'),
      sources: apiList(json['sources'], (v) {
        if (v is! String) throw const FormatException('Invalid source');
        return v;
      }),
      evidence: apiList(json['evidence'], MoyakEvidence.fromJson),
      recommendations: apiList(
        json['recommendations'] ?? [],
        MoyakRecommendation.fromJson,
      ),
    );
  }
}
