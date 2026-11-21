import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Collapses runs of whitespace and trims, so that re-formatting a question
/// file does not change the question keys.
String normalizeForKey(String plainText) =>
    plainText.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Stable question key: the first 16 hex characters of the SHA-256 of the
/// correct option's normalised plain text (see docs/question-format.md).
String questionKey(String correctPlainText) => sha256
    .convert(utf8.encode(normalizeForKey(correctPlainText)))
    .toString()
    .substring(0, 16);
