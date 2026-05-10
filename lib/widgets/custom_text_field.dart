import 'package:flutter/material.dart';

import '../theme.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.leadingIcon,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final IconData? leadingIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _hidden = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: context.appTextMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _hidden,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          onChanged: widget.onChanged,
          style: TextStyle(
            color: context.appTextPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(color: context.appTextMuted),
            prefixIcon: widget.leadingIcon == null
                ? null
                : Icon(widget.leadingIcon, color: AppColors.primary),
            suffixIcon: widget.obscureText
                ? IconButton(
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: context.appTextMuted,
                    ),
                  )
                : null,
            filled: true,
            fillColor: hasError
                ? AppColors.error.withOpacity(0.04)
                : context.appSurface.withOpacity(0.72),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError
                    ? AppColors.error.withOpacity(0.5)
                    : context.appBorder.withOpacity(0.8),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError
                    ? AppColors.error.withOpacity(0.5)
                    : AppColors.primary.withOpacity(0.55),
                width: 1.5,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
