import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/add_edit_task_screen.dart';
import '../theme.dart';

class LiquidBottomNavBar extends StatelessWidget {
  const LiquidBottomNavBar({super.key, required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: context.appSurface.withOpacity(0.88),
            border: Border(
              top: BorderSide(
                color: context.appBorder.withOpacity(0.75),
                width: 1.5,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Item(
                icon: Icons.home_rounded,
                label: 'Home',
                active: activeIndex == 0,
                onTap: () => _go(context, '/home'),
              ),
              _Item(
                icon: Icons.format_list_bulleted_rounded,
                label: 'Tasks',
                active: activeIndex == 1,
                onTap: () => _go(context, '/tasks'),
              ),
              GestureDetector(
                onTap: () {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) showAddEditTaskSheet(context, user.uid);
                },
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.fabGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.30),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              _Item(
                icon: Icons.calendar_month_rounded,
                label: 'Calendar',
                active: activeIndex == 2,
                onTap: () => _go(context, '/calendar'),
              ),
              _Item(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                active: activeIndex == 3,
                onTap: () => _go(context, '/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.pushReplacementNamed(context, route);
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primaryDark : context.appTextMuted;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: active
              ? Border.all(
                  color: AppColors.primary.withOpacity(0.25),
                  width: 1.5,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
