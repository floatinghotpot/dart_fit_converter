import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:fit_converter/fit_converter.dart';

void main(List<String> args) async {
  if (args.length < 2) {
    print('Usage: dart tool/convert.dart <input_file> <output_file>');
    print('Example: dart tool/convert.dart track.fit track.gpx');
    exit(1);
  }

  final inputPath = args[0];
  final outputPath = args[1];

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    print('Error: Input file "$inputPath" does not exist.');
    exit(1);
  }

  final inputExt = p.extension(inputPath).toLowerCase();
  final outputExt = p.extension(outputPath).toLowerCase();

  final converter = FitConverter();

  try {
    if (inputExt == '.fit') {
      final bytes = await inputFile.readAsBytes();
      if (outputExt == '.gpx') {
        final result = await converter.fit_to_gpx(bytes);
        await File(outputPath).writeAsString(result);
      } else if (outputExt == '.tcx') {
        final result = await converter.fit_to_tcx(bytes);
        await File(outputPath).writeAsString(result);
      } else if (outputExt == '.txt') {
        final result = await converter.fit_to_brief(bytes);
        await File(outputPath).writeAsString(result);
      } else {
        _unsupported(inputExt, outputExt);
      }
    } else if (inputExt == '.gpx') {
      final content = await inputFile.readAsString();
      if (outputExt == '.fit') {
        final result = await converter.gpx_to_fit(content);
        await File(outputPath).writeAsBytes(result);
      } else if (outputExt == '.tcx') {
        final result = await converter.gpx_to_tcx(content);
        await File(outputPath).writeAsString(result);
      } else {
        _unsupported(inputExt, outputExt);
      }
    } else if (inputExt == '.tcx') {
      final content = await inputFile.readAsString();
      if (outputExt == '.fit') {
        final result = await converter.tcx_to_fit(content);
        await File(outputPath).writeAsBytes(result);
      } else if (outputExt == '.gpx') {
        final result = await converter.tcx_to_gpx(content);
        await File(outputPath).writeAsString(result);
      } else {
        _unsupported(inputExt, outputExt);
      }
    } else {
      print(
          'Error: Unsupported input format "$inputExt". Supported: .fit, .gpx, .tcx');
      exit(1);
    }

    print('Successfully converted "$inputPath" to "$outputPath"');
  } catch (e) {
    print('Error during conversion: $e');
    exit(1);
  }
}

void _unsupported(String from, String to) {
  print('Error: Conversion from $from to $to is not supported or the same.');
  exit(1);
}
