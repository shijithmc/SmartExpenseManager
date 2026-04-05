import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientButton extends StatelessWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const GradientButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.isLoading = false,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: disabled
              ? LinearGradient(colors: [
                  AppTokens.primaryColor.withAlpha(128),
                  AppTokens.gradientEnd.withAlpha(128),
                ])
              : AppTokens.primaryGradient,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          boxShadow: disabled ? null : AppTokens.shadowLow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            onTap: disabled ? null : onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : child ??
                      Text(text ?? '',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }
}
