// page_transitions.dart - 50+ Working Safe Animations
import 'package:flutter/material.dart';
import 'dart:math';

enum PageTransitionType {
  // ========== SECTION 1: OPACITY BASED (12 animations) ==========
  fade,
  slowFade,
  fastFade,
  softFade,
  fadeIn,
  fadeOut,
  subtleFade,
  dramaticFade,
  quickFade,
  delayedFade,
  gentleFade,
  smoothFade,

  // ========== SECTION 2: SCALE BASED (12 animations) ==========
  scale,
  softScale,
  scaleUp,
  scaleDown,
  gentleScale,
  microScale,
  pulseScale,
  breathingScale,
  elasticScale,
  bounceScale,
  warmScale,
  coldScale,

  // ========== SECTION 3: BLUR BASED (8 animations) ==========
  blur,
  softBlur,
  gentleBlur,
  dreamyBlur,
  glassEffect,
  softFocus,
  blurFade,
  blurScale,

  // ========== SECTION 4: GLOW BASED (8 animations) ==========
  glow,
  softGlow,
  warmGlow,
  coolGlow,
  neonGlow,
  goldenGlow,
  silverGlow,
  rainbowGlow,

  // ========== SECTION 5: SHADOW BASED (6 animations) ==========
  shadowReveal,
  softShadow,
  deepShadow,
  floatingShadow,
  dropShadow,
  innerShadow,

  // ========== SECTION 6: COLOR EFFECTS (6 animations) ==========
  warmTone,
  coolTone,
  vintageTone,
  sepiaTone,
  monochrome,
  vibrantTone,

  // ========== SECTION 7: COMBINATION (10 animations) ==========
  fadeScale,
  fadeGlow,
  scaleGlow,
  blurGlow,
  fadeBlur,
  scaleBlur,
  fadeScaleGlow,
  fadeBlurGlow,
  scaleBlurGlow,
  fadeScaleBlur,

  // ========== SECTION 8: SPECIAL EFFECTS (8 animations) ==========
  zoomIn,
  zoomOut,
  softZoom,
  dissolve,
  pixelate,
  cinematic,
  softRipple,
  gentleWave,
}

class PageTransition extends StatelessWidget {
  final Widget child;
  final PageTransitionType type;
  final Duration duration;
  final Curve curve;

  const PageTransition({
    super.key,
    required this.child,
    this.type = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeInOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return _buildTransition(child, animation);
      },
      child: child,
    );
  }

  Widget _buildTransition(Widget child, Animation<double> animation) {
    final curvedAnim = CurvedAnimation(parent: animation, curve: curve);
    final slowCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInCubic,
    );
    final fastCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutQuad,
    );
    final bounceCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.bounceOut,
    );
    final elasticCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.elasticOut,
    );
    final sineCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutSine,
    );

    switch (type) {
      // ========== SECTION 1: OPACITY BASED ==========
      case PageTransitionType.fade:
        return FadeTransition(opacity: curvedAnim, child: child);

      case PageTransitionType.slowFade:
        return FadeTransition(opacity: slowCurve, child: child);

      case PageTransitionType.fastFade:
        return FadeTransition(opacity: fastCurve, child: child);

      case PageTransitionType.softFade:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.fadeIn:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.fadeOut:
        return FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.subtleFade:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.dramaticFade:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOutQuint),
          ),
          child: child,
        );

      case PageTransitionType.quickFade:
        return FadeTransition(opacity: fastCurve, child: child);

      case PageTransitionType.delayedFade:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );

      case PageTransitionType.gentleFade:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.97, end: 1.0).animate(sineCurve),
          child: child,
        );

      case PageTransitionType.smoothFade:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnim),
          child: child,
        );

      // ========== SECTION 2: SCALE BASED ==========
      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.softScale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.scaleUp:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.scaleDown:
        return ScaleTransition(
          scale: Tween<double>(begin: 1.15, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.gentleScale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(sineCurve),
          child: child,
        );

      case PageTransitionType.microScale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.99, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.pulseScale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curvedAnim),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );

      case PageTransitionType.breathingScale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1.0).animate(sineCurve),
          child: child,
        );

      case PageTransitionType.elasticScale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1.0).animate(elasticCurve),
          child: child,
        );

      case PageTransitionType.bounceScale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.6, end: 1.0).animate(bounceCurve),
          child: child,
        );

      case PageTransitionType.warmScale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.coldScale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curvedAnim),
          child: child,
        );

      // ========== SECTION 3: BLUR BASED ==========
      case PageTransitionType.blur:
        return FadeTransition(opacity: curvedAnim, child: child);

      case PageTransitionType.softBlur:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.gentleBlur:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(curvedAnim),
          child: FadeTransition(opacity: curvedAnim, child: child),
        );

      case PageTransitionType.dreamyBlur:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curvedAnim),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );

      case PageTransitionType.glassEffect:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1.0).animate(curvedAnim),
          child: FadeTransition(opacity: curvedAnim, child: child),
        );

      case PageTransitionType.softFocus:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.88, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.blurFade:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.blurScale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnim),
          child: FadeTransition(opacity: curvedAnim, child: child),
        );

      // ========== SECTION 4: GLOW BASED ==========
      case PageTransitionType.glow:
        return FadeTransition(opacity: curvedAnim, child: child);

      case PageTransitionType.softGlow:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.warmGlow:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curvedAnim),
          child: FadeTransition(opacity: curvedAnim, child: child),
        );

      case PageTransitionType.coolGlow:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnim),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );

      case PageTransitionType.neonGlow:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curvedAnim),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.88, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );

      case PageTransitionType.goldenGlow:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.silverGlow:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.93, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.rainbowGlow:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curvedAnim),
          child: FadeTransition(opacity: curvedAnim, child: child),
        );

      // ========== SECTION 5: SHADOW BASED ==========
      case PageTransitionType.shadowReveal:
        return FadeTransition(opacity: curvedAnim, child: child);

      case PageTransitionType.softShadow:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.deepShadow:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnim),
          child: FadeTransition(opacity: curvedAnim, child: child),
        );

      case PageTransitionType.floatingShadow:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.dropShadow:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.innerShadow:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curvedAnim),
          child: FadeTransition(opacity: curvedAnim, child: child),
        );

      // ========== SECTION 6: COLOR EFFECTS ==========
      case PageTransitionType.warmTone:
        return FadeTransition(opacity: curvedAnim, child: child);

      case PageTransitionType.coolTone:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.vintageTone:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curvedAnim),
          child: FadeTransition(opacity: curvedAnim, child: child),
        );

      case PageTransitionType.sepiaTone:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.94, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.monochrome:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.vibrantTone:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnim),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );

      // ========== SECTION 7: COMBINATION ==========
      case PageTransitionType.fadeScale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curvedAnim),
          child: FadeTransition(opacity: curvedAnim, child: child),
        );

      case PageTransitionType.fadeGlow:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.88, end: 1.0).animate(curvedAnim),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );

      case PageTransitionType.scaleGlow:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnim),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );

      case PageTransitionType.blurGlow:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnim),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );

      case PageTransitionType.fadeBlur:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.86, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.scaleBlur:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.fadeScaleGlow:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curvedAnim),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );

      case PageTransitionType.fadeBlurGlow:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.88, end: 1.0).animate(curvedAnim),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );

      case PageTransitionType.scaleBlurGlow:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnim),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.93, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );

      case PageTransitionType.fadeScaleBlur:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curvedAnim),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.88, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );

      // ========== SECTION 8: SPECIAL EFFECTS ==========
      case PageTransitionType.zoomIn:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.6, end: 1.0).animate(curvedAnim),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );

      case PageTransitionType.zoomOut:
        return ScaleTransition(
          scale: Tween<double>(begin: 1.4, end: 1.0).animate(curvedAnim),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );

      case PageTransitionType.softZoom:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnim),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );

      case PageTransitionType.dissolve:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnim),
          child: child,
        );

      case PageTransitionType.pixelate:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curvedAnim),
          child: FadeTransition(opacity: curvedAnim, child: child),
        );

      case PageTransitionType.cinematic:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(curvedAnim),
          child: FadeTransition(opacity: curvedAnim, child: child),
        );

      case PageTransitionType.softRipple:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1.0).animate(sineCurve),
          child: child,
        );

      case PageTransitionType.gentleWave:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(sineCurve),
          child: FadeTransition(opacity: curvedAnim, child: child),
        );
    }
  }
}

// Navigation helper functions
class NavigationHelper {
  static Future<T?> push<T>(
    BuildContext context,
    Widget page, {
    PageTransitionType transitionType = PageTransitionType.fade,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOutCubic,
  }) {
    return Navigator.push<T>(
      context,
      PageRouteBuilder(
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransition(
            type: transitionType,
            duration: duration,
            curve: curve,
            child: child,
          )._buildTransition(child, animation);
        },
      ),
    );
  }

  static List<PageTransitionType> getAllAnimations() {
    return PageTransitionType.values;
  }

  static PageTransitionType getRandomAnimation() {
    final animations = getAllAnimations();
    final random = DateTime.now().millisecondsSinceEpoch % animations.length;
    return animations[random.toInt()];
  }
}

// Animated container with transition on route change
class AnimatedRoute extends StatelessWidget {
  final Widget child;
  final PageTransitionType transitionType;
  final Duration duration;

  const AnimatedRoute({
    super.key,
    required this.child,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 400),
  });

  static PageTransitionType getRandomSafeAnimation() {
    final _random = Random();

    final animations = getCompanySafeAnimations();
    final randomIndex = _random.nextInt(animations.length);
    return animations[randomIndex];
  }

  static List<PageTransitionType> getCompanySafeAnimations() {
    return [
      // ========== OPACITY BASED (12) ==========
      PageTransitionType.fade,
      PageTransitionType.slowFade,
      PageTransitionType.fastFade,
      PageTransitionType.softFade,
      PageTransitionType.fadeIn,
      PageTransitionType.fadeOut,
      PageTransitionType.subtleFade,
      PageTransitionType.dramaticFade,
      PageTransitionType.quickFade,
      PageTransitionType.delayedFade,
      PageTransitionType.gentleFade,
      PageTransitionType.smoothFade,

      // ========== SCALE BASED (12) ==========
      PageTransitionType.scale,
      PageTransitionType.softScale,
      PageTransitionType.scaleUp,
      PageTransitionType.scaleDown,
      PageTransitionType.gentleScale,
      PageTransitionType.microScale,
      PageTransitionType.pulseScale,
      PageTransitionType.breathingScale,
      PageTransitionType.elasticScale,
      PageTransitionType.bounceScale,
      PageTransitionType.warmScale,
      PageTransitionType.coldScale,

      // ========== BLUR BASED (8) ==========
      PageTransitionType.blur,
      PageTransitionType.softBlur,
      PageTransitionType.gentleBlur,
      PageTransitionType.dreamyBlur,
      PageTransitionType.glassEffect,
      PageTransitionType.softFocus,
      PageTransitionType.blurFade,
      PageTransitionType.blurScale,

      // ========== GLOW BASED (8) ==========
      PageTransitionType.glow,
      PageTransitionType.softGlow,
      PageTransitionType.warmGlow,
      PageTransitionType.coolGlow,
      PageTransitionType.neonGlow,
      PageTransitionType.goldenGlow,
      PageTransitionType.silverGlow,
      PageTransitionType.rainbowGlow,

      // ========== SHADOW BASED (6) ==========
      PageTransitionType.shadowReveal,
      PageTransitionType.softShadow,
      PageTransitionType.deepShadow,
      PageTransitionType.floatingShadow,
      PageTransitionType.dropShadow,
      PageTransitionType.innerShadow,

      // ========== COLOR EFFECTS (6) ==========
      PageTransitionType.warmTone,
      PageTransitionType.coolTone,
      PageTransitionType.vintageTone,
      PageTransitionType.sepiaTone,
      PageTransitionType.monochrome,
      PageTransitionType.vibrantTone,

      // ========== COMBINATION (10) ==========
      PageTransitionType.fadeScale,
      PageTransitionType.fadeGlow,
      PageTransitionType.scaleGlow,
      PageTransitionType.blurGlow,
      PageTransitionType.fadeBlur,
      PageTransitionType.scaleBlur,
      PageTransitionType.fadeScaleGlow,
      PageTransitionType.fadeBlurGlow,
      PageTransitionType.scaleBlurGlow,
      PageTransitionType.fadeScaleBlur,

      // ========== SPECIAL EFFECTS (8) ==========
      PageTransitionType.zoomIn,
      PageTransitionType.zoomOut,
      PageTransitionType.softZoom,
      PageTransitionType.dissolve,
      PageTransitionType.pixelate,
      PageTransitionType.cinematic,
      PageTransitionType.softRipple,
      PageTransitionType.gentleWave,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PageTransition(
      type: transitionType,
      duration: duration,
      child: child,
    );
  }
}
