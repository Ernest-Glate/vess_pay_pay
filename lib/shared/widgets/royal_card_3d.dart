import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/glass_container.dart';
import '../../features/profile/data/settings_provider.dart';

class RoyalCard3D extends ConsumerStatefulWidget {
  final String balance;
  final String currency;

  const RoyalCard3D({
    super.key,
    required this.balance,
    required this.currency,
  });

  @override
  ConsumerState<RoyalCard3D> createState() => _RoyalCard3DState();
}

class _RoyalCard3DState extends ConsumerState<RoyalCard3D> with SingleTickerProviderStateMixin {
  double _rotateX = 0;
  double _rotateY = 0;
  
  late AnimationController _resetController;
  late Animation<double> _animationX;
  late Animation<double> _animationY;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _resetController.addListener(() {
      setState(() {
        _rotateX = _animationX.value;
        _rotateY = _animationY.value;
      });
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (_resetController.isAnimating) _resetController.stop();
    
    setState(() {
      // Calculate rotation based on cursor position relative to center
      _rotateX += details.delta.dy * 0.005;
      _rotateY -= details.delta.dx * 0.005;
      
      // Add limits to rotation
      _rotateX = _rotateX.clamp(-0.3, 0.3);
      _rotateY = _rotateY.clamp(-0.3, 0.3);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _animationX = Tween<double>(begin: _rotateX, end: 0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.elasticOut),
    );
    _animationY = Tween<double>(begin: _rotateY, end: 0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.elasticOut),
    );
    _resetController.forward(from: 0);
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHidden = ref.watch(settingsProvider).isBalanceHidden;
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanUpdate: (details) => _onPanUpdate(details, constraints.biggest),
          onPanEnd: _onPanEnd,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateX(_rotateX)
              ..rotateY(_rotateY),
            alignment: FractionalOffset.center,
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.royalGold.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: GlassContainer(
                borderRadius: 24,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.royalGold.withValues(alpha: 0.2),
                    AppColors.forestDepths.withValues(alpha: 0.8),
                    AppColors.black.withValues(alpha: 0.9),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'TOTAL BALANCE',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.royalGold.withValues(alpha: 0.6),
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => ref.read(settingsProvider.notifier).toggleBalanceVisibility(),
                                  child: Icon(
                                    isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    color: AppColors.royalGold.withValues(alpha: 0.4),
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  widget.currency,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.royalGold,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    isHidden ? '••••••' : widget.balance,
                                    key: ValueKey(isHidden),
                                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                      color: AppColors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white.withValues(alpha: 0.1),
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.white),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CARD HOLDER',
                              style: TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1),
                            ),
                            Text(
                              'ALEXANDER VESSPAY',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Mastercard-logo.svg/1280px-Mastercard-logo.svg.png',
                          height: 30,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.credit_card, color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
