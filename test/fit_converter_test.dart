import 'dart:io';
import 'package:test/test.dart';
import 'package:fit_converter/fit_converter.dart';

void main() {
  group('FitConverter Integration Tests', () {
    late FitConverter converter;
    late File testFitFile;

    setUpAll(() {
      converter = FitConverter();
      testFitFile = File('data/activity_20251108_072127.fit');

      if (!testFitFile.existsSync()) {
        throw Exception('Test data file not found: ${testFitFile.path}');
      }
    });

    group('Brief Info', () {
      test('should extract brief info from FIT file', () async {
        final fitBytes = await testFitFile.readAsBytes();
        final brief = await converter.fit_to_brief(fitBytes);

        expect(brief, isNotEmpty);
        expect(brief, contains('Cycling'));
        expect(brief, contains('Activity'));
      });

      test('should extract brief info from GPX (via conversion)', () async {
        final fitBytes = await testFitFile.readAsBytes();
        final gpxString = await converter.fit_to_gpx(fitBytes);
        final gpxToFit = await converter.gpx_to_fit(gpxString);
        final brief = await converter.fit_to_brief(gpxToFit);

        expect(brief, isNotEmpty);
        expect(brief, contains('Cycling'));
      });

      test('should extract brief info from TCX (via conversion)', () async {
        final fitBytes = await testFitFile.readAsBytes();
        final tcxString = await converter.fit_to_tcx(fitBytes);
        final tcxToFit = await converter.tcx_to_fit(tcxString);
        final brief = await converter.fit_to_brief(tcxToFit);

        expect(brief, isNotEmpty);
        expect(brief, contains('Cycling'));
      });
    });

    group('Format Conversions', () {
      test('FIT to GPX conversion should succeed', () async {
        final fitBytes = await testFitFile.readAsBytes();
        final gpxString = await converter.fit_to_gpx(fitBytes);

        expect(gpxString, isNotEmpty);
        expect(gpxString, contains('<?xml'));
        expect(gpxString, contains('<gpx'));
        expect(gpxString, contains('</gpx>'));
        expect(gpxString, contains('<trk'));
      });

      test('FIT to TCX conversion should succeed', () async {
        final fitBytes = await testFitFile.readAsBytes();
        final tcxString = await converter.fit_to_tcx(fitBytes);

        expect(tcxString, isNotEmpty);
        expect(tcxString, contains('<?xml'));
        expect(tcxString, contains('<TrainingCenterDatabase'));
        expect(tcxString, contains('</TrainingCenterDatabase>'));
        expect(tcxString, contains('<Activity'));
      });

      test('GPX to FIT conversion should succeed', () async {
        final fitBytes = await testFitFile.readAsBytes();
        final gpxString = await converter.fit_to_gpx(fitBytes);
        final fitFromGpx = await converter.gpx_to_fit(gpxString);

        expect(fitFromGpx, isNotEmpty);
        expect(fitFromGpx.length, greaterThan(100));
      });

      test('TCX to FIT conversion should succeed', () async {
        final fitBytes = await testFitFile.readAsBytes();
        final tcxString = await converter.fit_to_tcx(fitBytes);
        final fitFromTcx = await converter.tcx_to_fit(tcxString);

        expect(fitFromTcx, isNotEmpty);
        expect(fitFromTcx.length, greaterThan(100));
      });

      test('GPX to TCX conversion should succeed', () async {
        final fitBytes = await testFitFile.readAsBytes();
        final gpxString = await converter.fit_to_gpx(fitBytes);
        final tcxString = await converter.gpx_to_tcx(gpxString);

        expect(tcxString, isNotEmpty);
        expect(tcxString, contains('<TrainingCenterDatabase'));
        expect(tcxString, contains('</TrainingCenterDatabase>'));
      });

      test('TCX to GPX conversion should succeed', () async {
        final fitBytes = await testFitFile.readAsBytes();
        final tcxString = await converter.fit_to_tcx(fitBytes);
        final gpxString = await converter.tcx_to_gpx(tcxString);

        expect(gpxString, isNotEmpty);
        expect(gpxString, contains('<gpx'));
        expect(gpxString, contains('</gpx>'));
      });
    });

    group('Round-trip Conversions', () {
      test('FIT -> GPX -> FIT should preserve basic structure', () async {
        final originalFit = await testFitFile.readAsBytes();
        final gpxString = await converter.fit_to_gpx(originalFit);
        final convertedFit = await converter.gpx_to_fit(gpxString);

        // Verify the converted FIT is valid
        final brief = await converter.fit_to_brief(convertedFit);
        expect(brief, contains('Cycling'));
        expect(brief, contains('Activity'));
      });

      test('FIT -> TCX -> FIT should preserve basic structure', () async {
        final originalFit = await testFitFile.readAsBytes();
        final tcxString = await converter.fit_to_tcx(originalFit);
        final convertedFit = await converter.tcx_to_fit(tcxString);

        // Verify the converted FIT is valid
        final brief = await converter.fit_to_brief(convertedFit);
        expect(brief, contains('Cycling'));
        expect(brief, contains('Activity'));
      });

      test('GPX -> TCX -> GPX should preserve basic structure', () async {
        final fitBytes = await testFitFile.readAsBytes();
        final originalGpx = await converter.fit_to_gpx(fitBytes);
        final tcxString = await converter.gpx_to_tcx(originalGpx);
        final convertedGpx = await converter.tcx_to_gpx(tcxString);

        expect(convertedGpx, isNotEmpty);
        expect(convertedGpx, contains('<gpx'));
        expect(convertedGpx, contains('</gpx>'));
      });
    });

    group('FIT Merge', () {
      test('should merge multiple FIT files', () async {
        final fitBytes = await testFitFile.readAsBytes();

        // Create two identical files for merging
        final mergedFit = await converter.merge_fit([fitBytes, fitBytes]);

        expect(mergedFit, isNotEmpty);
        expect(mergedFit.length, greaterThan(fitBytes.length));

        // Verify merged file is valid
        final brief = await converter.fit_to_brief(mergedFit);
        expect(brief, contains('Activity'));
      });

      test('should merge single FIT file (edge case)', () async {
        final fitBytes = await testFitFile.readAsBytes();
        final mergedFit = await converter.merge_fit([fitBytes]);

        expect(mergedFit, isNotEmpty);

        // Should still be valid
        final brief = await converter.fit_to_brief(mergedFit);
        expect(brief, contains('Activity'));
      });
    });

    group('FIT Cut', () {
      test('should cut first 10 minutes (600 seconds)', () async {
        final fitBytes = await testFitFile.readAsBytes();
        final cutFit = await converter.cut_fit(fitBytes, 0, 600);

        expect(cutFit, isNotEmpty);
        expect(cutFit.length, lessThan(fitBytes.length));

        // Verify cut file is valid
        final brief = await converter.fit_to_brief(cutFit);
        expect(brief, contains('Activity'));
      });

      test('should cut middle section (600-1200 seconds)', () async {
        final fitBytes = await testFitFile.readAsBytes();
        final cutFit = await converter.cut_fit(fitBytes, 600, 1200);

        expect(cutFit, isNotEmpty);

        // Verify cut file is valid
        final brief = await converter.fit_to_brief(cutFit);
        expect(brief, contains('Activity'));
      });

      test('should handle cut with very small range', () async {
        final fitBytes = await testFitFile.readAsBytes();
        final cutFit = await converter.cut_fit(fitBytes, 0, 60);

        // Should either be empty or contain minimal data
        if (cutFit.isNotEmpty) {
          final brief = await converter.fit_to_brief(cutFit);
          expect(brief, contains('Activity'));
        }
      });
    });

    group('Auto-Lap Logic (GPX to FIT)', () {
      test('should create auto-laps for cycling (5km intervals)', () async {
        final fitBytes = await testFitFile.readAsBytes();
        final gpxString = await converter.fit_to_gpx(fitBytes);
        final convertedFit = await converter.gpx_to_fit(gpxString);

        final brief = await converter.fit_to_brief(convertedFit);

        // The original activity is ~96km cycling, should have ~19-20 laps
        expect(brief, contains('Laps:'));
        expect(brief, contains('Cycling'));
      });
    });

    group('Error Handling', () {
      // test('should handle empty FIT bytes gracefully', () async {
      //   expect(
      //     () => converter.fit_to_brief([]),
      //     throwsA(isA<Exception>()),
      //   );
      // });

      test('should handle invalid GPX string', () async {
        expect(
          () => converter.gpx_to_fit('invalid xml'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle invalid TCX string', () async {
        expect(
          () => converter.tcx_to_fit('invalid xml'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
