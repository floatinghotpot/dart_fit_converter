import 'package:test/test.dart';
import 'package:fit_converter/fit_converter.dart';

void main() {
  group('FitConverter', () {
    final converter = FitConverter();

    test('should exist', () {
      expect(converter, isNotNull);
    });
  });
}
