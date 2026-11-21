import 'dart:convert';

import 'package:file_picker/file_picker.dart';

/// A picked text file.
class PickedTextFile {
  const PickedTextFile(this.name, this.text);

  final String name;
  final String text;
}

/// Lets the admin choose a question file. Faked in the tests.
abstract interface class FilePickerService {
  /// Returns `null` when the user cancels. Throws [FormatException] if the
  /// file is not UTF-8 text.
  Future<PickedTextFile?> pickMarkdown();
}

class PlatformFilePickerService implements FilePickerService {
  @override
  Future<PickedTextFile?> pickMarkdown() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['md', 'txt'],
    );
    if (files.isEmpty) return null;
    final file = files.first;
    final bytes = await file.readAsBytes();
    return PickedTextFile(file.name, utf8.decode(bytes));
  }
}
