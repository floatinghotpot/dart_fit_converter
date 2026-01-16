import 'dart:io';
import 'dart:typed_data';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'package:fit_converter/fit_converter.dart' hide File;
import 'package:fit_sdk/fit_sdk.dart' as fit_sdk;

// ANSI colors for the 'detail' command
const String _reset = '\x1B[0m';
// const String _red = '\x1B[31m';
const String _green = '\x1B[32m';
const String _blue = '\x1B[34m';
const String _magenta = '\x1B[35m';
const String _cyan = '\x1B[36m';
// const String _gray = '\x1B[90m';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage information',
    )
    ..addCommand('brief')
    ..addCommand('convert')
    ..addCommand('cut')
    ..addCommand('detail')
    ..addCommand('merge');

  // convert options
  final convertParser = parser.commands['convert']!;
  convertParser.addOption(
    'output',
    abbr: 'o',
    help: 'Output file path',
    mandatory: true,
  );

  // cut options
  final cutParser = parser.commands['cut']!;
  cutParser.addOption(
    'output',
    abbr: 'o',
    help: 'Output file path',
    mandatory: true,
  );
  cutParser.addOption(
    'start',
    abbr: 's',
    help: 'Start offset in seconds',
    defaultsTo: '0',
  );
  cutParser.addOption(
    'end',
    abbr: 'e',
    help: 'End offset in seconds',
    mandatory: true,
  );

  // detail options
  final detailParser = parser.commands['detail']!;
  detailParser.addFlag(
    'definitions-only',
    negatable: false,
    help: 'Only show message definitions',
  );
  detailParser.addFlag(
    'no-fields',
    negatable: false,
    help: 'Show messages but hide field details',
  );
  detailParser.addOption(
    'filter',
    help: 'Only show specific global message number (e.g. 20 for record)',
  );

  // merge options
  final mergeParser = parser.commands['merge']!;
  mergeParser.addOption(
    'output',
    abbr: 'o',
    help: 'Output file path',
    mandatory: true,
  );

  if (arguments.isEmpty) {
    _printUsage(parser);
    return;
  }

  try {
    final results = parser.parse(arguments);

    if (results['help']) {
      _printUsage(parser);
      return;
    }

    final command = results.command;

    if (command == null) {
      _printUsage(parser);
      return;
    }

    switch (command.name) {
      case 'brief':
        await _handleBrief(command.rest);
        break;
      case 'convert':
        await _handleConvert(command);
        break;
      case 'cut':
        await _handleCut(command);
        break;
      case 'detail':
        await _handleDetail(command, command.rest);
        break;
      case 'merge':
        await _handleMerge(command);
        break;
      default:
        _printUsage(parser);
    }
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

void _printUsage(ArgParser parser) {
  print('Usage: dart tool/fit.dart <command> [arguments]');
  print('\nCommands:');
  print('  brief    Show a summary of a FIT, GPX, or TCX file');
  print('  convert  Convert between FIT, GPX, and TCX formats');
  print('  cut      Cut a portion of a FIT file (by time offset)');
  print('  detail   Show low-level FIT message details');
  print('  merge    Merge multiple FIT files into one');
  print(
    '\nRun "dart tool/fit.dart <command> --help" for more information on a command.',
  );
}

Future<void> _handleBrief(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart tool/fit.dart brief <file_path>');
    return;
  }

  final filePath = args[0];
  final file = File(filePath);
  if (!file.existsSync()) throw Exception('File "$filePath" does not exist.');

  final ext = p.extension(filePath).toLowerCase();
  final converter = FitConverter();

  Uint8List fitBytes;
  if (ext == '.fit') {
    fitBytes = await file.readAsBytes();
  } else if (ext == '.gpx') {
    fitBytes = await converter.gpxToFit(await file.readAsString());
  } else if (ext == '.tcx') {
    fitBytes = await converter.tcxToFit(await file.readAsString());
  } else {
    throw Exception('Unsupported file extension "$ext".');
  }

  final brief = await converter.fitToBrief(fitBytes);
  print('\n--- File Brief Info ---');
  print('Source: $filePath');
  print(brief);
}

Future<void> _handleConvert(ArgResults command) async {
  final args = command.rest;
  if (args.isEmpty) {
    print('Usage: dart tool/fit.dart convert <input_file> -o <output_file>');
    return;
  }

  final inputPath = args[0];
  final outputPath = command['output'];
  if (outputPath == null) {
    print('Error: Output file path is required (-o <output_file>)');
    return;
  }
  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    throw Exception('Input file "$inputPath" does not exist.');
  }
  final inputExt = p.extension(inputPath).toLowerCase();
  final outputExt = p.extension(outputPath).toLowerCase();
  final converter = FitConverter();

  if (inputExt == '.fit') {
    final bytes = await inputFile.readAsBytes();
    if (outputExt == '.gpx') {
      await File(outputPath).writeAsString(await converter.fitToGpx(bytes));
    } else if (outputExt == '.tcx') {
      await File(outputPath).writeAsString(await converter.fitToTcx(bytes));
    } else if (outputExt == '.txt') {
      await File(outputPath).writeAsString(await converter.fitToBrief(bytes));
    } else {
      throw Exception('Conversion from $inputExt to $outputExt not supported.');
    }
  } else if (inputExt == '.gpx') {
    final content = await inputFile.readAsString();
    if (outputExt == '.fit') {
      await File(outputPath).writeAsBytes(await converter.gpxToFit(content));
    } else if (outputExt == '.tcx') {
      await File(outputPath).writeAsString(await converter.gpxToTcx(content));
    } else {
      throw Exception('Conversion from $inputExt to $outputExt not supported.');
    }
  } else if (inputExt == '.tcx') {
    final content = await inputFile.readAsString();
    if (outputExt == '.fit') {
      await File(outputPath).writeAsBytes(await converter.tcxToFit(content));
    } else if (outputExt == '.gpx') {
      await File(outputPath).writeAsString(await converter.tcxToGpx(content));
    } else {
      throw Exception('Conversion from $inputExt to $outputExt not supported.');
    }
  } else {
    throw Exception('Unsupported input format "$inputExt".');
  }
  print('Successfully converted "$inputPath" to "$outputPath"');
}

Future<void> _handleCut(ArgResults command) async {
  final args = command.rest;
  if (args.isEmpty) {
    print(
      'Usage: dart tool/fit.dart cut <input.fit> -o <output.fit> -e <endSec> [-s <startSec>]',
    );
    return;
  }

  final inputPath = args[0];
  final outputPath = command['output'];
  final start = int.tryParse(command['start'] ?? '0');
  final end = int.tryParse(command['end'] ?? '');

  if (start == null || end == null) {
    throw Exception('Offset values must be integers.');
  }

  final file = File(inputPath);
  if (!file.existsSync()) throw Exception('File "$inputPath" does not exist.');

  final converter = FitConverter();
  final result = await converter.cutFit(await file.readAsBytes(), start, end);

  if (result.isEmpty) {
    print('Warning: No records found in range. Output not created.');
  } else {
    await File(outputPath).writeAsBytes(result);
    print('Successfully cut "$inputPath" and saved to "$outputPath"');
  }
}

Future<void> _handleDetail(ArgResults command, List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart tool/fit.dart detail <file_path> [options]');
    return;
  }

  final filePath = args[0];
  final file = File(filePath);
  if (!file.existsSync()) throw Exception('File "$filePath" does not exist.');

  final bool definitionsOnly = command['definitions-only'];
  final bool noFields = command['no-fields'];
  final int? filterMesgNum =
      command['filter'] != null ? int.tryParse(command['filter']) : null;

  print('$_blue=== Analyzing FIT File: $filePath ===$_reset');
  final bytes = await file.readAsBytes();
  final decoder = fit_sdk.Decode();

  int definitionCount = 0;
  int messageCount = 0;
  final Map<int, int> messageTypeCounts = {};

  decoder.onMesgDefinition = (mesgDef) {
    definitionCount++;
    if (filterMesgNum != null && mesgDef.globalMesgNum != filterMesgNum) return;

    print(
      '$_magenta[DEF] Global: ${mesgDef.globalMesgNum} | Local: ${mesgDef.localMesgNum}$_reset',
    );
    if (!noFields) {
      for (var fDef in mesgDef.getFields()) {
        print(
          '      - Field ${fDef.num} (size: ${fDef.size}, type: ${fDef.type})',
        );
      }
    }
  };

  decoder.onMesg = (mesg) {
    messageCount++;
    messageTypeCounts[mesg.num] = (messageTypeCounts[mesg.num] ?? 0) + 1;

    if (definitionsOnly) return;
    if (filterMesgNum != null && mesg.num != filterMesgNum) return;

    print('$_green[MESG] ${mesg.name} (${mesg.num})$_reset');
    if (!noFields) {
      for (var field in mesg.fields) {
        String val =
            field.values.length == 1 ? '${field.values[0]}' : '${field.values}';
        if (field.units.isNotEmpty) val += ' ${field.units}';
        print('      $_cyan${field.name} (${field.num}): $val$_reset');
      }
    }
  };

  decoder.read(bytes);
  print('\n$_blue=== Summary ===$_reset');
  print('Total Definitions: $definitionCount, Messages: $messageCount');
}

Future<void> _handleMerge(ArgResults command) async {
  final args = command.rest;
  final outputPath = command['output'];
  if (args.isEmpty || outputPath == null) {
    print(
      'Usage: dart tool/fit.dart merge <input1.fit> <input2.fit> ... -o <output.fit>',
    );
    return;
  }
  final List<Uint8List> files = [];
  for (final path in args) {
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception('Input file "$path" does not exist.');
    }
    files.add(await file.readAsBytes());
  }

  final converter = FitConverter();
  final result = await converter.mergeFit(files);
  await File(outputPath).writeAsBytes(result);
  print('Successfully merged into "$outputPath"');
}
