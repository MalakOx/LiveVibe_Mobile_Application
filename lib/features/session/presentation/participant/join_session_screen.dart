import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/pulse_button.dart';
import '../../domain/providers/session_provider.dart';

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

  Future<void> _joinSession(String code) async {
    if (_nameController.text.trim().isEmpty) {
      context.showErrorSnackBar('Please enter your name first');
      return;
    }

    final controller = ref.read(participantControllerProvider.notifier);
    try {
      await controller.joinSession(
        code: code.trim().toUpperCase(),
        name: _nameController.text.trim(),
        avatar: _selectedAvatar,
      );

      if (mounted) {
        context.pushReplacement('/session/waiting/${code.trim().toUpperCase()}');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(participantControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      body: AnimatedGradientBg(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: context.textPrimary),
                  onPressed: () => context.pop(),
                ).animate().fadeIn(),

                const SizedBox(height: 16),

                Text(
                  'Join Session',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.2, end: 0),

                const SizedBox(height: 24),

                // Avatar & Name Row
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

                // Tab bar
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
                      // CODE TAB
                      Column(
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
                                  buildCounter: (_, {required currentLength,
                                    required isFocused,
                                    required maxLength}) => null,
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
                            icon: const Icon(Icons.login_rounded,
                                color: Colors.white, size: 20),
                            onPressed: isLoading
                                ? null
                                : () => _joinSession(_codeController.text),
                          ).animate(delay: 500.ms).fadeIn(),
                        ],
                      ),

                      // QR TAB
                      _buildQRScanner(isLoading),
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
                      
                      // Extract code from URL if it's a full URL
                      if (code.contains('code=')) {
                        final uri = Uri.tryParse(code);
                        if (uri != null) {
                          code = uri.queryParameters['code'] ?? code;
                        }
                      }
                      
                      // Only process 6-character codes
                      if (code.length == 6 && code != _scannedCode) {
                        _scannedCode = code;
                        _joinSession(code);
                      }
                    }
                  },
                ),
              ),
              // Scanning overlay with reticle
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
              // Corner indicators
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
                        top: BorderSide(
                          color: AppColors.primary,
                          width: 3,
                        ),
                        left: BorderSide(
                          color: AppColors.primary,
                          width: 3,
                        ),
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