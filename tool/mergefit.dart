import 'dart:io';
import 'dart:typed_data';
import 'package:fit_converter/fit_converter.dart';

void main(List<String> args) async {
  if (args.length < 3) {
    print(
        'Usage: dart tool/mergefit.dart <output.fit> <input1.fit> <input2.fit> [input3.fit ...]');
    exit(1);
  }

  final outputPath = args[0];
  final inputPaths = args.sublist(1);

  final converter = FitConverter();
  final List<Uint8List> fitFiles = [];

  for (final path in inputPaths) {
    final file = File(path);
    if (!file.existsSync()) {
      print('Error: Input file "$path" does not exist.');
      exit(1);
    }
    fitFiles.add(await file.readAsBytes());
  }

  try {
    print('Merging ${fitFiles.length} files...');
    final result = await converter.merge_fit(fitFiles);
    await File(outputPath).writeAsBytes(result);
    print('Successfully merged files into "$outputPath"');
  } catch (e) {
    print('Error during merge: $e');
    exit(1);
  }
}
