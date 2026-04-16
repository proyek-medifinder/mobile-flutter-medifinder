import 'package:flutter/material.dart';
import 'package:medifinder/page/app_shell.dart';

class Home extends StatelessWidget {
  final int initialIndex;

  const Home({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return AppShell(initialIndex: initialIndex);
  }
}
