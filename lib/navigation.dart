import 'package:flutter/material.dart';

Future<void> goBackOrHome(BuildContext context) async {
  final didPop = await Navigator.maybePop(context);
  if (!didPop && context.mounted) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => route.settings.name == '/',
    );
  }
}
