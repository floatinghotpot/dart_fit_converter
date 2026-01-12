# Changelog

All notable changes to this project will be documented in this file.

## [0.3.0] - 2026-01-12

### Added
- Expose gpx/tcx classes
- Add integration test

## [0.1.0] - 2026-01-12

### Added
- **Core Conversion Engines**:
  - `FitToGpxConverter`: Export activities to GPX format with Garmin Extensions (HR, Cadence, Temp).
  - `FitToTcxConverter`: Export activities to TCX format.
  - `GpxToFitConverter`: Import GPX files to FIT. Includes Haversine distance calculation and Sport-based auto-lap logic (5km for Cycling, 1km for Running).
  - `TcxToFitConverter`: Import TCX files to FIT.
  - `GpxToTcxConverter`: Convert GPX to TCX format.
  - `TcxToGpxConverter`: Convert TCX to GPX format.
- **FIT Utilities**:
  - `FitMerger`: Merge multiple FIT files into a single activity message stream.
  - `FitToBriefConverter`: Extract summary information (Total Time, Distance, Laps, Sport) from FIT files.
  - `FitCutter`: Cut FIT files by specific time offsets (seconds).
- **Command Line Interfaces (CLI)**:
  - `tool/brief.dart`: Unified tool to view summary info for FIT, GPX, and TCX files.
  - `tool/convert.dart`: versatile file converter.
  - `tool/mergefit.dart`: CLI for merging files.
  - `tool/cutfit.dart`: CLI for trimming activities.
- **Models**:
  - Lightweight internal models for GPX and TCX parsing (`GpxReader`, `TcxReader`).

### Changed
- Refactored `FitMerger.cut` to use time offsets in seconds instead of absolute timestamps for better usability.

### Fixed
- Fixed sport type identification during GPX/TCX to FIT conversion.
- Fixed setter method compatibility issues with the underlying `fit_sdk`.
- Fixed total lap count mismatch in merged/converted files.

---

Initial project release.
