import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:ty1_mod_manager/services/ffi_win32.dart';
import 'package:win32/win32.dart';

class Code {
  final String name;
  final String description;
  final List<CodeData> codes;
  bool isActive;

  Code({
    required this.name,
    required this.description,
    required this.codes,
    this.isActive = false,
  });

  static Code fromJson(dynamic codeInfo) {
    final name = codeInfo['name'] ?? '';
    final description = codeInfo['description'] ?? '';
    final codes =
        (codeInfo['codes'] as List<dynamic>)
            .map((codeJson) => CodeData.fromJson(codeJson))
            .toList();

    return Code(name: name, description: description, codes: codes);
  }

  void applyCode() {
    for (var code in codes) {
      code.applyCodeChange();
    }
  }
}

class CodeData {
  final String address;
  final String bytes;

  CodeData({required this.address, required this.bytes});

  static CodeData fromJson(Map<String, dynamic> codeInfo) {
    return CodeData(
      address: codeInfo['address'] ?? '',
      bytes: codeInfo['bytes'] ?? '',
    );
  }

  int getAddressAsInt() {
    return int.parse(address, radix: 16);
  }

  void applyCodeChange() {
    print('Applying code at address: $address with bytes: $bytes');

    // Convert bytes to a pointer buffer
    final byteList =
        bytes.split(' ').map((e) => int.parse(e, radix: 16)).toList();
    final buffer = malloc<Uint8>(byteList.length);

    for (int i = 0; i < byteList.length; i++) {
      buffer[i] = byteList[i];
    }

    var addr = MemoryEditor.moduleBase + int.parse(address, radix: 16);
    MemoryEditor.virtualProtect(
      Pointer<Uint32>.fromAddress(addr),
      byteList.length,
    );
    final bytesWritten = calloc<IntPtr>();
    final writeSuccess = WriteProcessMemory(
      MemoryEditor.hProcess,
      Pointer<Uint32>.fromAddress(addr),
      buffer,
      byteList.length,
      bytesWritten,
    );

    if (writeSuccess == 0) {
      print('Failed to apply code.');
    } else {
      print('Successfully applied code!');
    }

    calloc.free(bytesWritten);
    calloc.free(buffer);
  }
}
