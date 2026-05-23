// page_transitions.dart - Fixed version
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

enum PageTransitionType {
  // Basic transitions
  slideFromRight,
  slideFromLeft,
  fade,
  scale,
  rotate,
  slideUp,
  slideDown,
  
  // PowerPoint style transitions
  zoomIn,
  zoomOut,
  flipX,
  flipY,
  fadeScale,
  slideFade,
  rotateScale,
  bounce,
}

class PageTransition extends StatelessWidget {
  final Widget child;
  final PageTransitionType type;
  final Duration duration;
  final Curve curve;

  const PageTransition({
    super.key,
    required this.child,
    this.type = PageTransitionType.slideFromRight,
    this.duration = const Duration(milliseconds: 500),
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
    final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
    
    switch (type) {
      // ========== BASIC TRANSITIONS ==========
      case PageTransitionType.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
        
      case PageTransitionType.slideFromLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
        
      case PageTransitionType.fade:
        return FadeTransition(opacity: curvedAnimation, child: child);
        
      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
          child: child,
        );
        
      case PageTransitionType.rotate:
        return RotationTransition(
          turns: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
          child: child,
        );
        
      case PageTransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
        
      case PageTransitionType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      
      // ========== POWERPOINT STYLE TRANSITIONS ==========
      
      case PageTransitionType.zoomIn:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
        
      case PageTransitionType.zoomOut:
        return ScaleTransition(
          scale: Tween<double>(begin: 1.5, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
        
      case PageTransitionType.flipX:
        return AnimatedBuilder(
          animation: curvedAnimation,
          builder: (context, child) {
            final double angle = curvedAnimation.value * 3.14159;
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              alignment: Alignment.center,
              child: Opacity(
                opacity: curvedAnimation.value,
                child: child,
              ),
            );
          },
          child: child,
        );
        
      case PageTransitionType.flipY:
        return AnimatedBuilder(
          animation: curvedAnimation,
          builder: (context, child) {
            final double angle = curvedAnimation.value * 3.14159;
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(angle),
              alignment: Alignment.center,
              child: Opacity(
                opacity: curvedAnimation.value,
                child: child,
              ),
            );
          },
          child: child,
        );
        
      case PageTransitionType.fadeScale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(opacity: curvedAnimation, child: child),
        );
        
      case PageTransitionType.slideFade:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.5, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(opacity: curvedAnimation, child: child),
        );
        
      case PageTransitionType.rotateScale:
        return Transform.rotate(
          angle: -0.5 * (1 - curvedAnimation.value),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.7, end: 1.0).animate(curvedAnimation),
            child: FadeTransition(opacity: curvedAnimation, child: child),
          ),
        );
        
      case PageTransitionType.bounce:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.3, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.bounceOut),
          ),
          child: child,
        );
    }
  }
}

// Navigation helper functions
class NavigationHelper {
  static Future<T?> push<T>(BuildContext context, Widget page, {
    PageTransitionType transitionType = PageTransitionType.slideFromRight,
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOutCubic,
  }) {
    return Navigator.push<T>(
      context,
      PageRouteBuilder(
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return _getTransition(animation, child, transitionType, curve);
        },
      ),
    );
  }

  static Widget _getTransition(
    Animation<double> animation, 
    Widget child, 
    PageTransitionType type,
    Curve curve,
  ) {
    final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
    
    switch (type) {
      case PageTransitionType.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
        
      case PageTransitionType.fade:
        return FadeTransition(opacity: curvedAnimation, child: child);
        
      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: child,
        );
        
      case PageTransitionType.zoomIn:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(opacity: curvedAnimation, child: child),
        );
        
      case PageTransitionType.flipX:
        return AnimatedBuilder(
          animation: curvedAnimation,
          builder: (context, child) {
            final double angle = curvedAnimation.value * 3.14159;
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              alignment: Alignment.center,
              child: Opacity(opacity: curvedAnimation.value, child: child),
            );
          },
          child: child,
        );
        
      case PageTransitionType.bounce:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.3, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.bounceOut),
          ),
          child: child,
        );
        
      default:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
    }
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

  @override
  Widget build(BuildContext context) {
    return PageTransition(
      type: transitionType,
      duration: duration,
      child: child,
    );
  }
}