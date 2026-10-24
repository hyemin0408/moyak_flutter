import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/models/moyak_api_models.dart';
import 'package:moyak_flutter/services/moyak_api_client.dart';
import 'package:moyak_flutter/services/service_result.dart';

// Explicit opt-in: network tests must never sign up, pay, dispense, or create consultations.
void main() {
  test(
    'Live Render health, UTF-8 drug search and invalid-token rejection',
    () async {
      final api = MoyakApiClient();
      addTearDown(api.close);
      expect(await api.health(), isA<ServiceSuccess<bool>>());
      final drugs = await api.searchDrugs('타이레놀');
      expect(drugs, isA<ServiceSuccess<List<MoyakDrug>>>());
      expect(
        (drugs as ServiceSuccess<List<MoyakDrug>>).value.any(
          (drug) => drug.name.contains('타이레놀'),
        ),
        isTrue,
      );
      final profile = await api.currentUser('invalid-live-check-token');
      expect(profile, isA<ServiceFailure<MoyakUser>>());
      expect(
        (profile as ServiceFailure<MoyakUser>).error.code,
        ServiceErrorCode.unauthorized,
      );
    },
    skip: !const bool.fromEnvironment('MOYAK_LIVE_API_TEST'),
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
