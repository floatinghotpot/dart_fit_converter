# FIT File Command-Line Tool

A comprehensive command-line utility for working with FIT (Flexible and Interoperable Data Transfer) files, as well as GPX and TCX formats. This tool provides various operations including format conversion, file merging, time-based cutting, and detailed inspection.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Commands](#commands)
  - [brief](#brief---show-file-summary)
  - [convert](#convert---format-conversion)
  - [cut](#cut---time-based-extraction)
  - [detail](#detail---low-level-inspection)
  - [merge](#merge---combine-multiple-files)
- [Examples](#examples)
- [Supported Formats](#supported-formats)

## Installation

This tool is part of the `fit_converter` package. To use it:

1. Ensure you have Dart SDK installed
2. Navigate to the `fit_converter` project directory
3. Run `dart pub get` to install dependencies

## Usage

```bash
dart tool/fit.dart <command> [arguments]
```

To see all available commands:

```bash
dart tool/fit.dart --help
```

To get help for a specific command:

```bash
dart tool/fit.dart <command> --help
```

## Commands

### `brief` - Show File Summary

Display a human-readable summary of a FIT, GPX, or TCX file, including activity type, duration, distance, and other key metrics.

**Syntax:**
```bash
dart tool/fit.dart brief <file_path>
```

**Arguments:**
- `<file_path>`: Path to the FIT, GPX, or TCX file

**Example:**
```bash
dart tool/fit.dart brief data/morning_run.fit
```

**Output:**
```
--- File Brief Info ---
Source: data/morning_run.fit
Activity Type: Running
Start Time: 2024-01-15 07:30:00
Duration: 45:23
Distance: 8.5 km
Average Heart Rate: 145 bpm
...
```

---

### `convert` - Format Conversion

Convert between FIT, GPX, and TCX file formats.

**Syntax:**
```bash
dart tool/fit.dart convert <input_file> -o <output_file>
```

**Arguments:**
- `<input_file>`: Path to the source file (FIT, GPX, or TCX)
- `-o, --output <output_file>`: Path for the converted output file

**Supported Conversions:**

| From | To | Description |
|------|-----|-------------|
| FIT | GPX | Convert FIT to GPS Exchange Format |
| FIT | TCX | Convert FIT to Training Center XML |
| FIT | TXT | Convert FIT to brief text summary |
| GPX | FIT | Convert GPX to FIT format |
| GPX | TCX | Convert GPX to TCX format |
| TCX | FIT | Convert TCX to FIT format |
| TCX | GPX | Convert TCX to GPX format |

**Examples:**
```bash
# Convert FIT to GPX
dart tool/fit.dart convert activity.fit -o activity.gpx

# Convert GPX to TCX
dart tool/fit.dart convert route.gpx -o route.tcx

# Convert FIT to text summary
dart tool/fit.dart convert workout.fit -o summary.txt
```

---

### `cut` - Time-Based Extraction

Extract a specific time range from a FIT file, creating a new FIT file with only the data within that range.

**Syntax:**
```bash
dart tool/fit.dart cut <input.fit> -o <output.fit> -s <start_seconds> -e <end_seconds>
```

**Arguments:**
- `<input.fit>`: Path to the input FIT file
- `-o, --output <output.fit>`: Path for the output FIT file
- `-s, --start <seconds>`: Start offset in seconds (default: 0)
- `-e, --end <seconds>`: End offset in seconds (required)

**Examples:**
```bash
# Extract first 10 minutes (600 seconds)
dart tool/fit.dart cut long_ride.fit -o warmup.fit -e 600

# Extract from 5 minutes to 15 minutes
dart tool/fit.dart cut long_ride.fit -o main_segment.fit -s 300 -e 900

# Extract last 5 minutes (if total duration is 3600 seconds)
dart tool/fit.dart cut long_ride.fit -o cooldown.fit -s 3300 -e 3600
```

**Note:** If no records are found in the specified time range, the tool will display a warning and no output file will be created.

---

### `detail` - Low-Level Inspection

Inspect the low-level structure of a FIT file, showing message definitions and field values. This is useful for debugging and understanding the internal structure of FIT files.

**Syntax:**
```bash
dart tool/fit.dart detail <file_path> [options]
```

**Arguments:**
- `<file_path>`: Path to the FIT file

**Options:**
- `--definitions-only`: Only show message definitions, skip message data
- `--no-fields`: Show messages but hide individual field details
- `--filter <message_number>`: Only show specific global message number (e.g., 20 for record messages)

**Message Number Reference:**
- `0` - File ID
- `18` - Session
- `19` - Lap
- `20` - Record (trackpoint data)
- `21` - Event
- `23` - Device Info
- And many more...

**Examples:**
```bash
# Show all message definitions and data
dart tool/fit.dart detail activity.fit

# Show only message definitions
dart tool/fit.dart detail activity.fit --definitions-only

# Show only record messages (trackpoints)
dart tool/fit.dart detail activity.fit --filter 20

# Show messages without field details
dart tool/fit.dart detail activity.fit --no-fields
```

**Output Format:**
- **Definitions** are shown in magenta: `[DEF] Global: 20 | Local: 0`
- **Messages** are shown in green: `[MESG] record (20)`
- **Fields** are shown in cyan with their values and units

---

### `merge` - Combine Multiple Files

Merge multiple FIT files into a single FIT file. This is useful for combining activities that were recorded separately or for consolidating data from multiple sources.

**Syntax:**
```bash
dart tool/fit.dart merge <input1.fit> <input2.fit> [...] -o <output.fit>
```

**Arguments:**
- `<input1.fit> <input2.fit> [...]`: Paths to two or more FIT files to merge
- `-o, --output <output.fit>`: Path for the merged output file

**Examples:**
```bash
# Merge two FIT files
dart tool/fit.dart merge part1.fit part2.fit -o complete.fit

# Merge multiple FIT files
dart tool/fit.dart merge morning.fit afternoon.fit evening.fit -o full_day.fit
```

**Merge Behavior:**
- Files are merged in the order they are provided
- Timestamps are preserved from the original files
- Session and lap data are combined appropriately
- The output file maintains FIT format integrity

---

## Examples

### Complete Workflow Example

```bash
# 1. Check the summary of your activity
dart tool/fit.dart brief my_ride.fit

# 2. Convert to GPX for use in mapping software
dart tool/fit.dart convert my_ride.fit -o my_ride.gpx

# 3. Extract just the main workout (skip warmup and cooldown)
dart tool/fit.dart cut my_ride.fit -o main_workout.fit -s 600 -e 3000

# 4. Inspect the structure of the cut file
dart tool/fit.dart detail main_workout.fit --filter 20

# 5. Merge with another activity
dart tool/fit.dart merge main_workout.fit another_ride.fit -o combined.fit
```

### Batch Processing Example

```bash
# Convert all FIT files in a directory to GPX
for file in data/*.fit; do
  dart tool/fit.dart convert "$file" -o "${file%.fit}.gpx"
done
```

### Analysis Example

```bash
# Get brief info for all activities
for file in activities/*.fit; do
  echo "=== $file ==="
  dart tool/fit.dart brief "$file"
  echo ""
done
```

## Supported Formats

### FIT (Flexible and Interoperable Data Transfer)
- Binary format developed by Garmin
- Compact and efficient storage
- Supports rich metadata and multiple data types
- Native format for most fitness devices

### GPX (GPS Exchange Format)
- XML-based format
- Widely supported by mapping and GPS software
- Human-readable structure
- Good for route sharing and visualization

### TCX (Training Center XML)
- XML-based format developed by Garmin
- Designed specifically for fitness data
- Includes heart rate, cadence, and other training metrics
- Compatible with Garmin Training Center and other fitness platforms

## Error Handling

The tool provides clear error messages for common issues:

- **File not found**: Displays which file is missing
- **Invalid format**: Reports unsupported file extensions
- **Conversion errors**: Shows specific conversion issues
- **Empty results**: Warns when operations produce no output (e.g., cut with no matching records)

## Technical Notes

### Color Output
The `detail` command uses ANSI color codes for better readability:
- **Blue**: Section headers and summaries
- **Magenta**: Message definitions
- **Green**: Message data
- **Cyan**: Field names and values

### Performance
- Large files (>100MB) may take several seconds to process
- The `merge` operation is memory-intensive for very large files
- The `detail` command with `--filter` is faster than showing all messages

### Limitations
- FIT files must be valid and not corrupted
- Some proprietary FIT fields may not be fully decoded
- Time-based cutting requires timestamp data in records
- Merging files with incompatible data types may produce unexpected results

## Troubleshooting

**Problem**: "File does not exist" error
- **Solution**: Check the file path and ensure the file exists

**Problem**: "Unsupported file extension" error
- **Solution**: Ensure the file has a `.fit`, `.gpx`, or `.tcx` extension

**Problem**: "No records found in range" when cutting
- **Solution**: Check that your start/end times are within the activity duration

**Problem**: Conversion produces unexpected results
- **Solution**: Use the `detail` command to inspect the source file structure

## Contributing

If you encounter issues or have suggestions for improvements, please:
1. Check the existing issues in the repository
2. Provide sample files that demonstrate the problem (if possible)
3. Include the full command you ran and the error message

## License

This tool is part of the `fit_converter` package. See the main package LICENSE file for details.
