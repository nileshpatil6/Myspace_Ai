import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class OrangeButton extends StatefulWidget {
  const OrangeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
    this.height = 52,
    this.fontSize = 15,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;
  final double height;
  final double fontSize;

  @override
  State<OrangeButton> createState() => _OrangeButtonState();
}

class _OrangeButtonState extends State<OrangeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => _scaleController.forward(),
      onTapUp: isDisabled
          ? null
          : (_) {
              _scaleController.reverse();
              widget.onPressed?.call();
            },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          height: widget.height,
          width: widget.expanded ? double.infinity : null,
          padding: widget.icon != null
              ? const EdgeInsets.symmetric(horizontal: 24)
              : const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            gradient: isDisabled
                ? null
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFF8C54), Color(0xFFFF5A1A)],
                  ),
            color: isDisabled ? AppColors.darkSurfaceElevated : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.orange.withAlpha(77),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else ...[
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w600,
                    color: isDisabled ? AppColors.darkTextDisabled : Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OrangeIconButton extends StatelessWidget {
  const OrangeIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 52,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF8C54), Color(0xFFFF5A1A)],
          ),
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withAlpha(77),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.4),
      ),
    );
  }
}
