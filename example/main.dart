import 'dart:io';
import 'package:fit_converter/fit_converter.dart';

void main() async {
  final converter = FitConverter();

  // 1. Load an existing FIT file
  final fitPath = 'data/activity_20251108_072127.fit';
  if (!File(fitPath).existsSync()) {
    print('Please ensure data files exist in data/ directory');
    return;
  }

  final fitBytes = await File(fitPath).readAsBytes();
  print('Loaded FIT file: $fitPath (${fitBytes.length} bytes)');

  // 2. FIT Brief Info
  print('\n--- FIT Brief Info ---');
  final brief = await converter.fit_to_brief(fitBytes);
  print(brief);

  // 3. FIT to GPX
  print('\n--- FIT to GPX ---');
  final gpxString = await converter.fit_to_gpx(fitBytes);
  print('GPX generated, length: ${gpxString.length}');

  // 4. FIT to TCX
  print('\n--- FIT to TCX ---');
  final tcxString = await converter.fit_to_tcx(fitBytes);
  print('TCX generated, length: ${tcxString.length}');

  // 5. GPX to TCX
  print('\n--- GPX to TCX ---');
  final gpxToTcx = await converter.gpx_to_tcx(gpxString);
  print('Converted GPX to TCX, length: ${gpxToTcx.length}');

  // 6. Merge FIT Files
  print('\n--- Merge FIT Files ---');
  final fitPath2 = 'data/activity_20251129_101802.fit';
  if (File(fitPath2).existsSync()) {
    final fitBytes2 = await File(fitPath2).readAsBytes();
    final mergedBytes = await converter.merge_fit([fitBytes, fitBytes2]);
    print(
        'Merged two FIT files. Original sizes: ${fitBytes.length}, ${fitBytes2.length}. Merged size: ${mergedBytes.length}');
  }

  // 7. Cut FIT File (Example: first 10 minutes)
  print('\n--- Cut FIT File ---');
  final startOffset = 0;
  final endOffset = 600; // 10 minutes
  final cutBytes = await converter.cut_fit(fitBytes, startOffset, endOffset);
  if (cutBytes.isNotEmpty) {
    print('Cut FIT file generated. Cut size: ${cutBytes.length}');
  } else {
    print('No records found in the specified time range for cutting demo.');
  }
}
