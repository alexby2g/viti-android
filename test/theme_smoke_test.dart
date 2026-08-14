import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viti/core/theme/viti_theme.dart';

void main() {
  test('VITI usa tema oscuro como base nativa', () {
    final theme = VitiTheme.dark();
    expect(theme.brightness, Brightness.dark);
    expect(theme.useMaterial3, isTrue);
  });
}
