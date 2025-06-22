import 'package:flutter/material.dart';
import 'package:ty1_mod_manager/theme.dart';

class MMAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const MMAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 150,
      title: Text(title, style: const TextStyle(fontFamily: 'SF Slapstick Comic', fontSize: 27)),
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage("resource/env_c4.png"), fit: BoxFit.cover),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, AppColors.mainBack],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
