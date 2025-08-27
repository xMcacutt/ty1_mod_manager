import 'package:flutter/material.dart';
import 'package:ty1_mod_manager/providers/settings_provider.dart';
import 'package:ty1_mod_manager/services/settings_service.dart';

class DialogService {
  final GlobalKey<NavigatorState> navigatorKey;

  DialogService(this.navigatorKey);

  Future<void> showError(String title, String message) async {
    await showDialog(
      context: navigatorKey.currentContext!,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK"))],
          ),
    );
  }

  Future<void> showInfo(String title, String message) async {
    await showDialog(
      context: navigatorKey.currentContext!,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK"))],
          ),
    );
  }

  Future<bool> showConfirmation(
    String title,
    String message, {
    String confirmText = "Yes",
    String cancelText = "No",
  }) async {
    return await showDialog<bool>(
          context: navigatorKey.currentContext!,
          builder:
              (context) => AlertDialog(
                title: Text(title),
                content: Text(message),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(cancelText)),
                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(confirmText)),
                ],
              ),
        ) ??
        false;
  }

  Future<String?> showGameSelection() async {
    return await showDialog<String>(
      context: navigatorKey.currentContext!,
      builder:
          (context) => AlertDialog(
            title: const Text('Choose Your Game'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Ty 1'),
                  onTap: () {
                    Navigator.pop(context, 'Ty 1');
                  },
                ),
                ListTile(
                  title: const Text('Ty 2'),
                  onTap: () {
                    Navigator.pop(context, 'Ty 2');
                  },
                ),
                ListTile(
                  title: const Text('Ty 3'),
                  onTap: () {
                    Navigator.pop(context, 'Ty 3');
                  },
                ),
              ],
            ),
          ),
    );
  }

  void showSetup(String game, SettingsProvider settingsProvider) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder:
          (context) => AlertDialog(
            title: const Text('No modded directory is set for this game!'),
            content: Text('Do you want me to automatically set up your modded $game directory?'),
            actions: [
              TextButton(
                onPressed: () {
                  settingsProvider.completeSetup(game: game, autoComplete: false, tyDirectoryPath: null);
                  Navigator.of(context).pop();
                },
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  showDialog(
                    context: navigatorKey.currentContext!,
                    barrierDismissible: false,
                    builder:
                        (context) => const AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Setting up modded directory...'),
                            ],
                          ),
                        ),
                  );

                  final result = await settingsProvider.pickDirectory();
                  if (result != null) {
                    await settingsProvider.completeSetup(game: game, autoComplete: true, tyDirectoryPath: result);
                  }

                  Navigator.of(navigatorKey.currentContext!).pop();

                  Navigator.of(context).pop();
                },
                child: const Text('Yes'),
              ),
            ],
          ),
    );
  }
}
