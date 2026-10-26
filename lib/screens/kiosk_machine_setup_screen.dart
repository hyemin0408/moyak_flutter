import 'package:flutter/material.dart';

import '../models/kiosk_machine.dart';
import '../services/moyak_api_client.dart';
import '../services/service_result.dart';

/// Installation-only screen; never changes a machine during an active purchase.
class KioskMachineSetupScreen extends StatefulWidget {
  const KioskMachineSetupScreen({
    super.key,
    required this.api,
    required this.onSelected,
    this.currentMachineCode,
  });
  final MoyakApiClient api;
  final Future<void> Function(KioskMachine) onSelected;
  final String? currentMachineCode;
  @override
  State<KioskMachineSetupScreen> createState() =>
      _KioskMachineSetupScreenState();
}

class _KioskMachineSetupScreenState extends State<KioskMachineSetupScreen> {
  List<KioskMachine> _machines = const [];
  String? _code, _error;
  bool _loading = true, _saving = false;
  @override
  void initState() {
    super.initState();
    _code = widget.currentMachineCode;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.api.kioskMachines();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case ServiceSuccess<List<KioskMachine>>():
          _machines = result.value;
          if (_machines.isEmpty) _error = '등록된 자판기 위치가 없습니다. 관리자에게 문의해 주세요.';
        case ServiceFailure<List<KioskMachine>>():
          _error = result.error.message;
      }
    });
  }

  Future<void> _save() async {
    if (_saving || _code == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSelected(_machines.singleWhere((m) => m.code == _code));
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is StateError
              ? error.message.toString()
              : '기기 설정을 저장하지 못했습니다. 다시 시도해 주세요.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: widget.currentMachineCode == null
          ? null
          : AppBar(
              title: const Text('설치 기기 변경'),
              backgroundColor: const Color(0xFFFFFDE7),
              automaticallyImplyLeading: !_saving,
            ),
      backgroundColor: const Color(0xFFFFFDE7),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '모약 · 설치 기기 설정',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF593D0D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.currentMachineCode == null
                        ? '설치 담당자용 최초 설정입니다.\n이 키오스크가 설치된 자판기 위치를 선택해 주세요.'
                        : '설치 담당자용 설정입니다.\n현재 기기: ${widget.currentMachineCode}\n변경할 자판기 위치를 선택해 주세요.',
                  ),
                  const SizedBox(height: 24),
                  if (_loading)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('자판기 위치를 불러오고 있습니다. 첫 접속은 약 1분 걸릴 수 있습니다.'),
                      ],
                    ),
                  if (!_loading) ...[
                    for (final machine in _machines)
                      Card(
                        color: Colors.white,
                        child: ListTile(
                          title: Text(machine.name),
                          subtitle: Text(
                            '${machine.address}\n기기 코드: ${machine.code}',
                          ),
                          isThreeLine: true,
                          trailing: Icon(
                            _code == machine.code
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: const Color(0xFF927014),
                          ),
                          onTap: _saving
                              ? null
                              : () => setState(() => _code = machine.code),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      '위치 목록은 지도 API 기준입니다. 주문용 기기 등록 및 테스트 사용 승인은 별도 확인이 필요합니다. 선택만으로 주문·QR 요청은 실행하지 않습니다.',
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD54F),
                        foregroundColor: const Color(0xFF593D0D),
                      ),
                      onPressed: _code == null || _saving ? null : _save,
                      child: Text(_saving ? '저장 중…' : '선택한 자판기로 설정'),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    if (_machines.isEmpty && !_loading)
                      TextButton(
                        onPressed: _load,
                        child: const Text('다시 불러오기'),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
