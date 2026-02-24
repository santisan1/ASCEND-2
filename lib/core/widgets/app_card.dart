import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum CardVariant { elevated, outlined, gradient }

class AppCard extends StatelessWidget {
  final Widget child;
  final CardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.variant = CardVariant.elevated,
    this.onTap,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPadding = padding ?? const EdgeInsets.all(20);
    final defaultMargin =
        margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

    switch (variant) {
      case CardVariant.elevated:
        return Container(
          width: width,
          height: height,
          margin: defaultMargin,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark, width: 1),
            boxShadow: AppColors.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(padding: defaultPadding, child: child),
            ),
          ),
        );

      case CardVariant.outlined:
        return Container(
          width: width,
          height: height,
          margin: defaultMargin,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(padding: defaultPadding, child: child),
            ),
          ),
        );

      case CardVariant.gradient:
        return Container(
          width: width,
          height: height,
          margin: defaultMargin,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(padding: defaultPadding, child: child),
            ),
          ),
        );
    }
  }
}
