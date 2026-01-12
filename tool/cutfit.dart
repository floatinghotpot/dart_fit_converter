import 'dart:io';
import 'package:fit_converter/fit_converter.dart';

void main(List<String> args) async {
  if (args.length != 4) {
    print(
        'Usage: dart tool/cutfit.dart <input.fit> <output.fit> <startOffsetSeconds> <endOffsetSeconds>');
    print(
        'Example: dart tool/cutfit.dart activity.fit cut.fit 0 600 (cuts the first 10 minutes)');
    exit(1);
  }

  final inputPath = args[0];
  final outputPath = args[1];
  final startOffset = int.tryParse(args[2]);
  final endOffset = int.tryParse(args[3]);

  if (startOffset == null || endOffset == null) {
    print('Error: Offset values must be integers.');
    exit(1);
  }

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    print('Error: Input file "$inputPath" does not exist.');
    exit(1);
  }

  final converter = FitConverter();

  try {
    final bytes = await inputFile.readAsBytes();
    final result = await converter.cut_fit(bytes, startOffset, endOffset);
    if (result.isEmpty) {
      print(
          'Warning: No records found in the specified range. Output file was not created.');
    } else {
      await File(outputPath).writeAsBytes(result);
      print('Successfully cut "$inputPath" and saved to "$outputPath"');
    }
  } catch (e) {
    print('Error during cutting: $e');
    exit(1);
  }
}
