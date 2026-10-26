import 'widgets/kiosk_viewport.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'screens/kiosk_home_router.dart';
import 'screens/kiosk_machine_setup_screen.dart';
import 'models/kiosk_machine.dart';
import 'services/kiosk_machine_store.dart';
import 'services/kiosk_backend.dart';
import 'services/moyak_api_client.dart';
import 'services/order_recovery_store.dart';

void main() => runApp(const KioskApplication());

/// Normal launch always uses the real backend path. MyApp alone remains a
/// dependency-free design preview for existing isolated widget tests.
class KioskApplication extends StatefulWidget {
  const KioskApplication({super.key, this.api});
  final MoyakApiClient? api;
  @override
  State<KioskApplication> createState() => _KioskApplicationState();
}

class _KioskApplicationState extends State<KioskApplication> {
  late MoyakApiClient _api = widget.api ?? MoyakApiClient();
  final _machineStore = const KioskMachineStore();
  KioskBackend? _backend;
  bool _loadingMachine = true;
  String? _machineError;

  @override
  void initState() {
    super.initState();
    _loadMachine();
  }

  Future<void> _loadMachine() async {
    setState(() {
      _loadingMachine = true;
      _machineError = null;
    });
    try {
      final machine = await _machineStore.read(_api.recoveryNamespace);
      if (!mounted) return;
      if (machine != null) _configure(machine);
    } catch (_) {
      if (!mounted) return;
      _machineError = '저장된 기기 설정을 읽지 못했습니다. 다시 시도해 주세요.';
    }
    if (mounted) setState(() => _loadingMachine = false);
  }

  void _configure(KioskMachine machine) {
    _backend = KioskBackend(
      api: _api,
      machineId: machine.code,
      environment: const String.fromEnvironment('MOYAK_TEST_ENVIRONMENT'),
      allowMutations: const bool.fromEnvironment(
        'MOYAK_ALLOW_SERVER_MUTATIONS',
      ),
      recoveryStore: const PlatformOrderRecoveryStore(),
    );
  }

  Future<void> _selectMachine(KioskMachine machine) async {
    final previous = _backend;
    if (previous != null) {
      final reason = await previous.machineChangeError(
        targetMachineId: machine.code,
      );
      if (reason != null) throw StateError(reason);
    }
    await _machineStore.write(_api.recoveryNamespace, machine);
    if (!mounted) return;
    if (previous != null) {
      final server = _api.recoveryNamespace;
      previous.invalidateSessionReads();
      _api.close();
      _api = MoyakApiClient(baseUrl: server);
    }
    setState(() => _configure(machine));
  }

  Future<void> _openMachineSettings(BuildContext context) async {
    final backend = _backend!;
    if (Navigator.of(context).canPop()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매 화면을 종료하고 시작 화면으로 돌아온 뒤 변경해 주세요.')),
      );
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('설치 담당자용 기기 설정'),
        content: Text(
          '현재 기기: ${backend.machineId}\n설치 위치를 변경하시겠습니까? 기기 변경은 관리자 또는 설치 담당자가 진행해 주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('기기 설정 열기'),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;
    final reason = await backend.machineChangeError();
    if (!context.mounted) return;
    if (reason != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(reason)));
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KioskMachineSetupScreen(
          api: _api,
          currentMachineCode: backend.machineId,
          onSelected: _selectMachine,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backend = _backend;
    if (backend != null) {
      return KioskBackendScope(
        backend: backend,
        onMachineSetup: _openMachineSettings,
        child: MyApp(
          key: ValueKey(backend),
          onMachineSetup: _openMachineSettings,
        ),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFD54F)),
      ),
      home: _loadingMachine || _machineError != null
          ? Scaffold(
              backgroundColor: KioskStartScreen.backgroundColor,
              body: Center(
                child: _loadingMachine
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_machineError!),
                          TextButton(
                            onPressed: _loadMachine,
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
              ),
            )
          : KioskMachineSetupScreen(api: _api, onSelected: _selectMachine),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.onMachineSetup});
  final Future<void> Function(BuildContext)? onMachineSetup;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MOYAK',
    debugShowCheckedModeBanner: false,
    navigatorObservers: [kioskRouteObserver],
    theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
    home: KioskStartScreen(onMachineSetup: onMachineSetup),
  );
}

class KioskStartScreen extends StatelessWidget {
  const KioskStartScreen({super.key, this.onStart, this.onMachineSetup});

  final VoidCallback? onStart;
  final Future<void> Function(BuildContext)? onMachineSetup;
  static const backgroundColor = Color(0xFFFFFDE7);
  static const textColor = Color(0xFF593D0D);

  void _handleStart(BuildContext context) {
    if (onStart != null) {
      onStart!();
      return;
    }
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const KioskHomeRouter()));
  }

  @override
  Widget build(BuildContext context) {
    // The source is 1536x1024. The visible character body spans x=449..1196;
    final machineSetup =
        onMachineSetup ??
        context
            .dependOnInheritedWidgetOfExactType<KioskBackendScope>()
            ?.onMachineSetup;
    // the greeting on its left is separate from the body's visual center.
    const characterWidth = 1150.0;
    const characterCenterX = (449 + 1196) / 2;
    const characterLeft = 540 - characterCenterX * characterWidth / 1536;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: KioskViewport(
          child: KioskCanvas(
            centerContent: true,
            clipBehavior: Clip.hardEdge,
            children: [
              if (machineSetup != null)
                Positioned(
                  right: 40,
                  bottom: 30,
                  child: TextButton.icon(
                    onPressed: () => machineSetup(context),
                    icon: const Icon(Icons.settings_outlined, color: textColor),
                    label: const Text(
                      '기기 설정',
                      style: TextStyle(color: textColor, fontSize: 24),
                    ),
                  ),
                ),
              Positioned(
                left: 134,
                top: 275,
                width: 812,
                height: 264,
                child: SvgPicture.asset(
                  'assets/moyak_logo.svg',
                  semanticsLabel: 'MOYAK',
                ),
              ),
              Positioned(
                left: 367,
                top: 565,
                width: 346,
                height: 98,
                child: Image.asset(
                  'assets/moyak_subtitle.png',
                  semanticLabel: '모두의 약',
                ),
              ),
              Positioned(
                left: characterLeft,
                top: 735,
                width: characterWidth,
                height: 767,
                child: Image.asset(
                  'assets/moyak_character.png',
                  fit: BoxFit.cover,
                  semanticLabel: '안녕! 모약이야! MOYAK 캐릭터',
                ),
              ),
              Positioned(
                left: 220,
                top: 1570,
                width: 640,
                height: 140,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    borderRadius: BorderRadius.circular(45),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        offset: Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 210,
                top: 1564,
                width: 660,
                height: 160,
                child: ExcludeSemantics(
                  child: SvgPicture.asset('assets/start_button.svg'),
                ),
              ),
              Positioned(
                left: 220,
                top: 1570,
                width: 640,
                height: 140,
                child: Semantics(
                  button: true,
                  label: '터치해주세요',
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(45),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: const ValueKey('kiosk-start-button'),
                      onTap: () => _handleStart(context),
                      splashColor: textColor.withValues(alpha: 0.12),
                      child: Center(
                        child: ExcludeSemantics(
                          child: Text(
                            '터치해주세요',
                            style: TextStyle(
                              color: textColor,
                              fontFamily: 'MenuKorean',
                              fontSize: 56,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
