import 'package:flutter/material.dart';
import 'package:my_project_name/constants/app_theme.dart';

class AnimatedProgressButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String defaultText;
  final String loadingText;
  final double? width;
  final double? height;

  const AnimatedProgressButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    required this.defaultText,
    this.loadingText = 'Loading',
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? 48.0,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          disabledBackgroundColor: AppColors.primaryColor.withOpacity(0.7),
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child:
              isLoading
                  ? Row(
                    key: const ValueKey('loading'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(loadingText),
                    ],
                  )
                  : Text(defaultText, key: const ValueKey('default')),
        ),
      ),
    );
  }
}
