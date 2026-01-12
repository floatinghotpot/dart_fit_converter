import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:fit_converter/fit_converter.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart tool/brief.dart <file_path>');
    print('Supports: .fit, .gpx, .tcx');
    exit(1);
  }

  final filePath = args[0];
  final file = File(filePath);
  if (!file.existsSync()) {
    print('Error: File "$filePath" does not exist.');
    exit(1);
  }

  final ext = p.extension(filePath).toLowerCase();
  final converter = FitConverter();

  try {
    Uint8List fitBytes;

    if (ext == '.fit') {
      fitBytes = await file.readAsBytes();
    } else if (ext == '.gpx') {
      print('Converting GPX to temporary FIT in memory...');
      final gpxContent = await file.readAsString();
      fitBytes = await converter.gpx_to_fit(gpxContent);
    } else if (ext == '.tcx') {
      print('Converting TCX to temporary FIT in memory...');
      final tcxContent = await file.readAsString();
      fitBytes = await converter.tcx_to_fit(tcxContent);
    } else {
      print('Error: Unsupported file extension "$ext".');
      exit(1);
    }

    if (fitBytes.isEmpty) {
      print('Error: Resulting FIT data is empty.');
      exit(1);
    }

    final brief = await converter.fit_to_brief(fitBytes);
    print('\n--- File Brief Info ---');
    print('Source: $filePath');
    print(brief);
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
