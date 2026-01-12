# fit_converter

A powerful Dart library for processing and converting sports activity data. Seamlessly convert between **FIT**, **GPX**, and **TCX** formats, and perform advanced operations like merging and cutting FIT files.

[![Pub Version](https://img.shields.io/pub/v/fit_converter)](https://pub.dev/packages/fit_converter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- 🔄 **Multi-format Conversion**:
  - **FIT** ➡️ GPX, TCX, CSV/TXT (Brief Summary)
  - **GPX** ➡️ FIT, TCX
  - **TCX** ➡️ FIT, GPX
- 🛠️ **FIT File Manipulation**:
  - **Merge**: Combine multiple FIT files into a single activity.
  - **Cut**: Precisely trim FIT files using time offsets.
- 📊 **Quick Summary**: Extract brief activity information (Sport, Distance, Laps, etc.) without full decoding.
- 💻 **CLI Tools**: Ready-to-use command-line scripts for batch processing.

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  fit_converter: ^0.1.0
```

Then run `dart pub get`.

## Usage

### Library Usage

```dart
import 'package:fit_converter/fit_converter.dart';
import 'dart:io';

void main() async {
  final converter = FitConverter();
  final fitBytes = await File('activity.fit').readAsBytes();

  // Convert FIT to GPX
  final gpxString = await converter.fit_to_gpx(fitBytes);
  print(gpxString);

  // Get Brief Info
  final briefInfo = await converter.fit_to_brief(fitBytes);
  print(briefInfo);
}
```

### Command-Line Tools

The package includes several useful tools in the `tool/` directory:

#### 1. Convert File
Convert between any supported formats:
```bash
dart tool/convert.dart input.fit output.gpx
```

#### 2. Get Brief Information
Quickly view activity summary:
```bash
dart tool/brief.dart activity.fit
```

#### 3. Merge FIT Files
```bash
dart tool/mergefit.dart merged.fit part1.fit part2.fit part3.fit
```

#### 4. Cut FIT File
Cut the first 10 minutes (600 seconds) of an activity:
```bash
dart tool/cutfit.dart input.fit output.fit 0 600
```

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
