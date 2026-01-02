enum Game { ty1, ty2, ty3 }

class LaunchOptions {
  final bool direct;
  final Game? game;
  final bool injectCodes;
  final List<String>? modsOverride;

  const LaunchOptions({required this.direct, this.game, required this.injectCodes, this.modsOverride});
}

LaunchOptions parseArgs(List<String> args) {
  bool direct = false;
  bool injectCodes = false;
  Game? game;
  List<String>? mods;

  for (int i = 0; i < args.length; i++) {
    final arg = args[i];

    switch (arg) {
      case '--direct':
        direct = true;
        if (i + 1 >= args.length) {
          throw ArgumentError('--direct requires a game (ty1, ty2, ty3)');
        }
        game = _parseGame(args[++i]);
        break;

      case '--codes':
        injectCodes = true;
        break;

      case '--mods':
        if (i + 1 >= args.length) {
          throw ArgumentError('--mods requires a comma-separated list');
        }
        mods = args[++i].split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        break;
    }
  }

  return LaunchOptions(direct: direct, game: game, injectCodes: injectCodes, modsOverride: mods);
}

Game _parseGame(String value) {
  switch (value.toLowerCase()) {
    case 'ty1':
      return Game.ty1;
    case 'ty2':
      return Game.ty2;
    case 'ty3':
      return Game.ty3;
    default:
      throw ArgumentError('Unknown game: $value');
  }
}
