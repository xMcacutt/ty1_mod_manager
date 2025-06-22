import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

typedef VirtualProtectExC =
    Int32 Function(
      IntPtr hProcess,
      Pointer lpAddress,
      Uint64 dwSize,
      Uint32 flNewProtect,
      Pointer<Uint32> lpflOldProtect,
    );

typedef VirtualProtectExDart =
    int Function(int hProcess, Pointer lpAddress, int dwSize, int flNewProtect, Pointer<Uint32> lpflOldProtect);

class MemoryEditor {
  static DynamicLibrary? kernel32;
  static late final DynamicLibrary psapi;
  static late int moduleBase;
  static late int hProcess;

  static void init(int pid) {
    if (kernel32 != null) return;
    kernel32 = DynamicLibrary.open('kernel32.dll');
    psapi = DynamicLibrary.open('psapi.dll');
  }

  static Future<void> waitForProcessToStart(int pid) async {
    while (true) {
      hProcess = OpenProcess(PROCESS_ALL_ACCESS, 0, pid);
      if (hProcess != 0) {
        // Process is now open, you can proceed
        await Future.delayed(Duration(milliseconds: 1000));
        getModuleBaseAddress();
        break;
      }
      // Wait for a moment before checking again
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  static void deinit() {
    CloseHandle(hProcess);
  }

  static void virtualProtect(Pointer<Uint32> addr, int numBytes) {
    final VirtualProtectExDart VirtualProtectEx = kernel32!.lookupFunction<VirtualProtectExC, VirtualProtectExDart>(
      'VirtualProtectEx',
    );
    final oldProtection = calloc<Uint32>();
    VirtualProtectEx(hProcess, addr, numBytes, PAGE_EXECUTE_READWRITE, oldProtection);
    calloc.free(oldProtection);
  }

  static void getModuleBaseAddress() {
    final hMods = calloc<IntPtr>(1024);
    final bytesNeeded = calloc<Uint32>();

    final result = EnumProcessModules(hProcess, hMods, 4 * 1024, bytesNeeded);

    if (result == 0) {
      calloc.free(hMods);
      calloc.free(bytesNeeded);
      throw Exception('Unable to enumerate process modules');
    }

    final baseAddress = hMods[0];
    calloc.free(hMods);
    calloc.free(bytesNeeded);
    moduleBase = baseAddress;
  }
}
