import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ty1_mod_manager/providers/code_provider.dart';

class GameProvider extends ChangeNotifier {
  String _selectedGame = 'Ty 1';
  String get selectedGame => _selectedGame;

  final Map<String, String> _bannerImages = {
    'Ty 1': 'resource/Ty1_Env.png',
    'Ty 2': 'resource/Ty2_Env.png',
    'Ty 3': 'resource/Ty3_Env.png',
  };

  String get bannerImage => _bannerImages[_selectedGame] ?? 'resource/Ty1_Env.png';

  CodeProvider? _codeProvider;
  GameProvider(this._codeProvider) {
    _loadSelectedGame();
  }

  void setCodeProvider(CodeProvider provider) {
    _codeProvider = provider;
  }

  Future<void> _loadSelectedGame() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedGame = prefs.getString('selected_game') ?? 'Ty 1';
    notifyListeners();
  }

  Future<void> setGame(String game) async {
    _selectedGame = game;
    _codeProvider?.loadCodes(game);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_game', game);
  }
}
