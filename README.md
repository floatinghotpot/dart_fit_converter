# fit_converter

A powerful Dart library for processing and converting sports activity data. Seamlessly convert between **FIT**, **GPX**, and **TCX** formats, and perform advanced operations like merging and cutting FIT files.

[![Pub Version](https://img.shields.io/pub/v/fit_converter)](https://pub.dev/packages/fit_converter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- 🔄 **Multi-format Conversion**:
  - **FIT** ➡️ GPX, TCX, TXT (Brief Summary)
  - **GPX** ➡️ FIT, TCX
  - **TCX** ➡️ FIT, GPX
- 🛠️ **FIT File Manipulation**:
  - **Merge**: Combine multiple FIT files into a single activity.
  - **Cut**: Precisely trim FIT files using time offsets.
- 📊 **Quick Summary**: Extract brief activity information (Sport, Distance, Laps, etc.) without full decoding.
- � **Low-Level Inspection**: Examine FIT file structure with detailed message and field information.
- 💻 **Unified CLI Tool**: Comprehensive command-line interface with 5 powerful commands.

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  fit_converter: ^0.5.0
```

Then run `dart pub get`.

## Usage

### Library Usage

```dart
import 'dart:io';
import 'package:fit_converter/fit_converter.dart' hide File;

void main() async {
  final converter = FitConverter();
  final fitBytes = await File('activity.fit').readAsBytes();

  // Convert FIT to GPX
  final gpxString = await converter.fitToGpx(fitBytes);
  print(gpxString);

  // Convert FIT to TCX
  final tcxString = await converter.fitToTcx(fitBytes);
  print(tcxString);

  // Get Brief Info
  final briefInfo = await converter.fitToBrief(fitBytes);
  print(briefInfo);

  // Merge multiple FIT files
  final fitBytes2 = await File('activity2.fit').readAsBytes();
  final merged = await converter.mergeFit([fitBytes, fitBytes2]);
  await File('merged.fit').writeAsBytes(merged);

  // Cut FIT file (first 10 minutes)
  final cut = await converter.cutFit(fitBytes, 0, 600);
  await File('cut.fit').writeAsBytes(cut);
}
```

### Command-Line Tool

The package includes a unified CLI tool `tool/fit.dart` with 5 commands. For detailed documentation, see [tool/README.md](tool/README.md).

#### Quick Start

```bash
# Show help
dart tool/fit.dart --help

# Get activity summary
dart tool/fit.dart brief activity.fit

# Convert FIT to GPX
dart tool/fit.dart convert activity.fit -o activity.gpx

# Cut first 10 minutes
dart tool/fit.dart cut activity.fit -o warmup.fit -e 600

# Inspect FIT file structure
dart tool/fit.dart detail activity.fit --filter 20

# Merge multiple files
dart tool/fit.dart merge part1.fit part2.fit -o complete.fit
```

#### Available Commands

| Command | Description |
|---------|-------------|
| `brief` | Show a summary of a FIT, GPX, or TCX file |
| `convert` | Convert between FIT, GPX, and TCX formats |
| `cut` | Cut a portion of a FIT file by time offset |
| `detail` | Show low-level FIT message details |
| `merge` | Merge multiple FIT files into one |

For complete documentation with examples and troubleshooting, see [tool/README.md](tool/README.md).

## Auto-Lap & Distance Logic (GPX to FIT)

When converting from GPX to FIT, `fit_converter` automatically handles:
- **Distance Calculation**: Uses the Haversine formula to compute distance between track points.
- **Auto-Lapping**:
  - **Cycling**: Automatically creates a new lap every **5km**.
  - **Running**: Automatically creates a new lap every **1km**.
  - **Other**: Default laps for other sports.

## Platform Support

Works on any platform supported by Dart (Windows, macOS, Linux, Web, Android, iOS).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

