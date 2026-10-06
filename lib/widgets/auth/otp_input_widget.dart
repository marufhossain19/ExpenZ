import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

/// Reusable 6-digit OTP input with auto-focus, paste support, and animations.
/// Uses a hidden TextField overlay to reliably capture paste events.
class OtpInputWidget extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  final VoidCallback? onChanged;
  final int length;

  const OtpInputWidget({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.length = 6,
  });

  @override
  State<OtpInputWidget> createState() => OtpInputWidgetState();
}

class OtpInputWidgetState extends State<OtpInputWidget>
    with SingleTickerProviderStateMixin {
  late TextEditingController _hiddenController;
  late FocusNode _hiddenFocusNode;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  String get otp => _hiddenController.text.padRight(widget.length).substring(0, widget.length).trim();

  @override
  void initState() {
    super.initState();
    _hiddenController = TextEditingController();
    _hiddenFocusNode = FocusNode();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Auto-focus the hidden field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hiddenFocusNode.requestFocus();
    });

    _hiddenController.addListener(_onHiddenChanged);
  }

  @override
  void dispose() {
    _hiddenController.removeListener(_onHiddenChanged);
    _hiddenController.dispose();
    _hiddenFocusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onHiddenChanged() {
    // Enforce max length and digits only
    String text = _hiddenController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > widget.length) {
      text = text.substring(0, widget.length);
    }
    if (text != _hiddenController.text) {
      _hiddenController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    setState(() {});
    widget.onChanged?.call();

    // Auto-submit when all digits entered
    if (text.length == widget.length) {
      _hiddenFocusNode.unfocus();
      widget.onCompleted(text);
    }
  }

  /// Clear all OTP fields and refocus.
  void clear() {
    _hiddenController.clear();
    _hiddenFocusNode.requestFocus();
  }

  /// Trigger a shake animation to indicate error.
  void shake() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentText = _hiddenController.text;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final dx = _shakeController.isAnimating
            ? _shakeAnimation.value *
                ((_shakeController.value * 10).toInt().isEven ? 1 : -1)
            : 0.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => _hiddenFocusNode.requestFocus(),
        child: Stack(
          children: [
            // Visual boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                widget.length,
                (i) => _buildBox(i, isDark, currentText),
              ),
            ),
            // Hidden TextField overlay — captures all input & paste
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _hiddenController,
                  focusNode: _hiddenFocusNode,
                  keyboardType: TextInputType.number,
                  maxLength: widget.length,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  enableInteractiveSelection: true,
                  // Allow selecting all and pasting
                  style: const TextStyle(
                    color: Colors.transparent,
                    height: 0.01,
                    fontSize: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBox(int index, bool isDark, String currentText) {
    final hasValue = index < currentText.length;
    final isActive = index == currentText.length && _hiddenFocusNode.hasFocus;
    final char = hasValue ? currentText[index] : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppColors.primary
              : hasValue
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: hasValue || isActive ? 2 : 1.5,
        ),
        boxShadow: hasValue
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: hasValue
              ? Text(
                  char,
                  key: ValueKey('$index-$char'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                )
              : isActive
                  ? Container(
                      key: const ValueKey('cursor'),
                      width: 2,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ),
    );
  }
}
