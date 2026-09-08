import 'package:flutter/material.dart';
import '../app_colors_ext.dart';

class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.theme, required this.visible});
  final LvTheme theme;
  final bool visible;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    if (!widget.visible) _ctrl.value = 1;
  }

  @override
  void didUpdateWidget(SplashOverlay old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      _ctrl.reverse(from: 1);
    } else if (!widget.visible && old.visible) {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && _ctrl.isCompleted) return const SizedBox.shrink();
    final t = widget.theme;
    return FadeTransition(
      opacity: ReverseAnimation(_fade),
      child: Container(
        color: t.bg,
        child: Stack(
          children: [
            Positioned(top: -120, left: -90, child: Container(
              width: 420, height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [t.accent.withValues(alpha: 0.26), Colors.transparent]),
              ),
            )),
            Positioned(bottom: -60, right: -140, child: Container(
              width: 340, height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [t.accent.withValues(alpha: 0.13), Colors.transparent]),
              ),
            )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App icon
                  Container(
                    width: 76, height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: t.accent),
                      boxShadow: [BoxShadow(color: t.accent.withValues(alpha: 0.24), blurRadius: 34)],
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: LvColors.accent300, width: 1.5),
                            ),
                            child: ClipOval(child: Container(color: t.bg)),
                          ),
                          Positioned(
                            bottom: 11, right: 12,
                            child: Container(
                              width: 5, height: 5,
                              decoration: BoxDecoration(color: t.accent, shape: BoxShape.circle),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Lịch Việt',
                      style: TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 44,
                          height: 1, letterSpacing: -1.3, color: t.text)),
                  const SizedBox(height: 11),
                  Text('Âm dương · Thời tiết · Tử vi',
                      style: TextStyle(fontSize: 13.5, color: t.muted)),
                  const SizedBox(height: 24),
                  Container(
                    width: 96, height: 1,
                    color: t.accent,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 40, right: 40, bottom: 44,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Phát triển bởi',
                        style: TextStyle(fontSize: 12, letterSpacing: 1.4, color: t.dim)),
                    const SizedBox(height: 4),
                    Text('GP DIGITAL',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, letterSpacing: 0.6, color: t.text)),
                  ]),
                  Text('v1.0', style: TextStyle(fontSize: 12, color: t.dim, fontFamily: 'monospace')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
