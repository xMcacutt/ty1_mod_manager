import 'package:flutter/foundation.dart';
import 'package:ty1_mod_manager/models/code.dart';
import 'package:ty1_mod_manager/services/code_service.dart';

class CodeProvider with ChangeNotifier {
  late CodeService _codeService;

  void initialize(CodeService codeService) {
    _codeService = codeService;
  }

  List<Code> _codes = [];
  bool _isLoading = false;

  List<Code> get codes => _codes;
  bool get isLoading => _isLoading;

  Future<void> loadCodes() async {
    _isLoading = true;
    notifyListeners();
    _codes = await _codeService.loadCodeData();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleCodeActive(int index, bool value) async {
    _codes[index].isActive = value;
    await _codeService.saveActiveCodes(_codes);
    notifyListeners();
  }

  Future<void> updateCodeValue(int index, double value) async {
    _codes[index].value = value.round();
    await _codeService.saveActiveCodes(_codes);
    notifyListeners();
  }

  Future<void> applyActiveCodes() async {
    await _codeService.applyActiveCodes(_codes);
  }
}
