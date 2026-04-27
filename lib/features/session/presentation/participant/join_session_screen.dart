import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/page_container.dart';
import '../../../../shared/widgets/pulse_button.dart';
import '../../../../shared/widgets/standard_app_bar.dart';

class JoinSessionScreen extends ConsumerStatefulWidget {
  const JoinSessionScreen({super.key});

  @override
  ConsumerState<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends ConsumerState<JoinSessionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedAvatar = '';
  String? _scannedCode;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedAvatar = IdGenerator.generateAvatarEmoji();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _joinSession(String rawCode) async {
    final name = _nameController.text.trim();
    final code = rawCode.trim().toUpperCase();

    if (name.isEmpty) {
      context.showErrorSnackBar('Please enter your name first');
      return;
    }

    if (code.length != 6) {
      context.showErrorSnackBar('Please enter a valid 6-character code');
      return;
    }

    setState(() => _isJoining = true);

    if (!mounted) return;

    final encodedName = Uri.encodeComponent(name);
    final encodedAvatar = Uri.encodeComponent(_selectedAvatar);
    context.go('/session/waiting/$code?name=$encodedName&avatar=$encodedAvatar');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isJoining;

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Join Session',
        onBackPressed: () => context.pop(),
      ),
      body: AnimatedGradientBg(
        child: SafeArea(
          top: false,
          child: PageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedAvatar = IdGenerator.generateAvatarEmoji();
                        }),
                        child: Column(
                          children: [
                            Text(
                              _selectedAvatar,
                              style: const TextStyle(fontSize: 40),
                            ),
                            Text(
                              'tap to change',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 9,
                                color: context.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Your name...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            fillColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 200.ms).fadeIn(),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: context.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.bgElevated),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: AppColors.gradientSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelColor: context.textMuted,
                    labelColor: Colors.white,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Enter Code'),
                      Tab(text: 'Scan QR'),
                    ],
                  ),
                ).animate(delay: 300.ms).fadeIn(),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCodeTab(context, isLoading),
                      _buildScannerTab(context, isLoading),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeTab(BuildContext context, bool isLoading) {
    return Column(
      children: [
        GlassCard(
          child: Column(
            children: [
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 8,
                ),
                decoration: const InputDecoration(
                  hintText: 'XXXXXX',
                  hintStyle: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white54,
                    letterSpacing: 8,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLength: 6,
                buildCounter: (
                  _, {
                  required int currentLength,
                  required bool isFocused,
                  required int? maxLength,
                }) =>
                    null,
              ),
              Divider(color: context.bgElevated),
              const SizedBox(height: 4),
              Text(
                'Ask your host for the 6-digit code',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: context.textMuted,
                ),
              ),
            ],
          ),
        ).animate(delay: 400.ms).fadeIn(),
        const Spacer(),
        PulseButton(
          label: 'Join Session',
          gradient: AppColors.gradientSecondary,
          isLoading: isLoading,
          icon: const Icon(Icons.login_rounded, color: Colors.white, size: 20),
          onPressed: isLoading ? null : () => _joinSession(_codeController.text),
        ).animate(delay: 500.ms).fadeIn(),
      ],
    );
  }

  Widget _buildScannerTab(BuildContext context, bool isLoading) {
    return _buildQRScanner(isLoading);
  }

  Widget _buildQRScanner(bool isLoading) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: MobileScanner(
                  onDetect: (capture) {
                    final barcode = capture.barcodes.firstOrNull;
                    if (barcode?.rawValue != null && !isLoading) {
                      var code = barcode!.rawValue!.trim();

                      if (code.contains('code=')) {
                        final uri = Uri.tryParse(code);
                        if (uri != null) {
                          code = uri.queryParameters['code'] ?? code;
                        }
                      }

                      if (code.length == 6 && code != _scannedCode) {
                        _scannedCode = code;
                        _joinSession(code);
                      }
                    }
                  },
                ),
              ),
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.6),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              ...List.generate(4, (index) {
                final top = index < 2;
                final left = index % 2 == 0;
                return Positioned(
                  top: top ? 20 : null,
                  bottom: !top ? 20 : null,
                  left: left ? 20 : null,
                  right: !left ? 20 : null,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.primary, width: 3),
                        left: BorderSide(color: AppColors.primary, width: 3),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ).animate(delay: 400.ms).fadeIn(),
        const SizedBox(height: 16),
        Text(
          'Point camera at the QR code',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Keep QR code well-lit and centered',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            color: context.textMuted,
          ),
        ),
      ],
    );
  }
}
