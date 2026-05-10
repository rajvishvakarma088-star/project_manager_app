import 'package:flutter/material.dart';

import '../theme.dart';

class TopBarButton extends StatelessWidget {
  const TopBarButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: context.appSurface,
        shape: BoxShape.circle,
        border: Border.all(color: context.appBorder.withOpacity(0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.16 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: context.appTextPrimary, size: 21),
    );

    return GestureDetector(onTap: onTap, child: button);
  }
}
