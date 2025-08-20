import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ty1_mod_manager/providers/game_provider.dart';
import 'package:ty1_mod_manager/providers/mod_provider.dart';
import 'package:ty1_mod_manager/services/launcher_service.dart';
import 'package:ty1_mod_manager/services/settings_service.dart';
import 'package:ty1_mod_manager/theme.dart';

Widget buildBottomNavBar(
  BuildContext context,
  ModProvider modProvider,
  LauncherService launcherService,
  SettingsService settingsService,
) {
  return BottomAppBar(
    color: AppColors.mainBack,
    child: Container(
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStyledButton(
            context: context,
            label: 'Add Custom',
            icon: Icons.folder_open_rounded,
            onPressed: () async {
              final result = await settingsService.pickDirectory(context);
              if (result != null) {
                await modProvider.completeSetup(autoComplete: true, tyDirectoryPath: result);
                await modProvider.loadMods();
              } else {
                await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("No Directory Selected"),
                      content: const Text("Please select a valid directory."),
                      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Ok"))],
                    );
                  },
                );
              }
            },
          ),
          Consumer<GameProvider>(
            builder: (context, gameProvider, child) {
              return _buildStyledDropdown(
                value: gameProvider.selectedGame,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    final gameId = newValue;
                    gameProvider.setGame(gameId);
                    modProvider.loadMods();
                  }
                },
              );
            },
          ),
          _buildStyledButton(
            context: context,
            label: 'Launch Game',
            icon: Icons.play_arrow_rounded,
            onPressed: () {
              final gameProvider = Provider.of<GameProvider>(context, listen: false);
              final selectedGameLabel = gameProvider.selectedGame;
              launcherService.launchGame(context, modProvider.selectedMods, selectedGame: selectedGameLabel);
            },
          ),
        ],
      ),
    ),
  );
}

Widget _buildStyledButton({
  required BuildContext context,
  required String label,
  required IconData icon,
  required VoidCallback onPressed,
}) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 28, color: AppColors.mainAccent),
    label: Text(label, style: const TextStyle(fontFamily: 'SF Slapstick Comic', fontSize: 20)),
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.altBack,
      foregroundColor: AppColors.mainText,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

Widget _buildStyledDropdown({required String value, required ValueChanged<String?> onChanged}) {
  final options = [
    {'label': 'Ty 1', 'icon': 'resource/Ty1.ico'},
    {'label': 'Ty 2', 'icon': 'resource/Ty2.ico'},
    {'label': 'Ty 3', 'icon': 'resource/Ty3.ico'},
  ];
  final controller = MenuController();
  final menuChildren =
      options.asMap().entries.map<Widget>((entry) {
        final index = entry.key;
        final option = entry.value;
        return Column(
          children: [
            MenuItemButton(
              style: ButtonStyle(
                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
              ),
              onPressed: () {
                onChanged(option['label'] as String);
              },
              child: Row(
                children: [
                  Image.asset(option['icon'] as String, width: 32, height: 32),
                  const SizedBox(width: 8),
                  Text(
                    option['label'] as String,
                    style: const TextStyle(fontFamily: 'SF Slapstick Comic', fontSize: 18, color: AppColors.mainText),
                  ),
                ],
              ),
            ),
            if (index < options.length - 1) const SizedBox(height: 2),
          ],
        );
      }).toList();

  return MenuAnchor(
    controller: controller,
    style: MenuStyle(
      backgroundColor: WidgetStateProperty.all(AppColors.mainBack),
      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16, horizontal: 8)),
    ),
    menuChildren: menuChildren,
    child: GestureDetector(
      onTap: () => controller.isOpen ? controller.close() : controller.open(),
      child: Container(
        decoration: BoxDecoration(color: AppColors.altBack, borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(8),
        width: 120,
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // centers inside Expanded
                children: [
                  Image.asset(options.firstWhere((o) => o['label'] == value)['icon'] as String, width: 32, height: 32),
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: const TextStyle(fontFamily: 'SF Slapstick Comic', fontSize: 18, color: AppColors.mainText),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, color: AppColors.mainAccent, size: 28),
          ],
        ),
      ),
    ),
  );
}
