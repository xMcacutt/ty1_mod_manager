import 'package:flutter/material.dart';
import 'package:ty1_mod_manager/theme.dart';

class MMAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  MMAppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 150,
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'SF Slapstick Comic', // Custom font name
          fontSize: 27, // Optional: Adjust the font size
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("resource/env_c4.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent, // Transparent at the bottom
                AppColors.mainBack, // Fade effect at the top
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(100);
}
