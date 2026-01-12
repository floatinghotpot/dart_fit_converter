import 'dart:typed_data';
import 'package:fit_sdk/fit_sdk.dart';
import 'converter.dart';

class FitToBriefConverter extends SportsDataConverter<Uint8List, String> {
  @override
  Future<String> convert(Uint8List fitBytes) async {
    final listener = FitListener();
    final decoder = Decode();

    decoder.onMesg = (Mesg mesg) {
      listener.onMesg(this, MesgEventArgs(mesg));
    };

    try {
      decoder.read(fitBytes);
    } catch (e) {
      return 'Error decoding FIT file: $e';
    }

    final fitMessages = listener.fitMessages;
    final sb = StringBuffer();

    // 1. Determine File Type
    int fileType = 0; // Default or unknown
    if (fitMessages.fileIdMesgs.isNotEmpty) {
      final fileId = fitMessages.fileIdMesgs.first;
      fileType = fileId.getType() ?? 0;
      sb.writeln('File Type: ${_getFileTypeName(fileType)}');
      if (fileId.getManufacturer() != null) {
        sb.writeln('Manufacturer: ${fileId.getManufacturer()}');
      }
      if (fileId.getTimeCreated() != null) {
        sb.writeln('Created: ${fileId.getTimeCreated()}');
      }
    }

    // 2. Branch based on type
    switch (fileType) {
      case File.activity:
        _writeActivityBrief(sb, fitMessages);
        break;
      case File.workout:
        _writeWorkoutBrief(sb, fitMessages);
        break;
      case File.course:
        _writeCourseBrief(sb, fitMessages);
        break;
      case File.weight:
        _writeWeightBrief(sb, fitMessages);
        break;
      case File.monitoringDaily:
        _writeMonitoringBrief(sb, fitMessages);
        break;
      default:
        // Generic brief if type unknown but has records
        if (fitMessages.recordMesgs.isNotEmpty) {
          _writeActivityBrief(sb, fitMessages);
        } else {
          sb.writeln('No detailed summary available for this file type.');
        }
    }

    return sb.toString();
  }

  String _getFileTypeName(int type) {
    switch (type) {
      case File.device:
        return 'Device';
      case File.settings:
        return 'Settings';
      case File.sport:
        return 'Sport';
      case File.activity:
        return 'Activity';
      case File.workout:
        return 'Workout';
      case File.course:
        return 'Course';
      case File.weight:
        return 'Weight';
      case File.monitoringDaily:
        return 'Monitoring Daily';
      default:
        return 'Unknown ($type)';
    }
  }

  void _writeActivityBrief(StringBuffer sb, FitMessages m) {
    if (m.sessionMesgs.isEmpty) {
      if (m.recordMesgs.isNotEmpty) {
        sb.writeln('Summary (from records):');
        sb.writeln('  Points: ${m.recordMesgs.length}');
        final start = m.recordMesgs.first.getTimestamp();
        final end = m.recordMesgs.last.getTimestamp();
        if (start != null && end != null) {
          sb.writeln('  Start: $start');
          sb.writeln('  End: $end');
          sb.writeln('  Duration: ${end.difference(start)}');
        }
        final lastDist = m.recordMesgs.last.getDistance();
        if (lastDist != null) {
          sb.writeln('  Distance: ${(lastDist / 1000).toStringAsFixed(2)} km');
        }
      }
      return;
    }

    final s = m.sessionMesgs.first;
    sb.writeln('Activity Summary:');
    sb.writeln('  Sport: ${_getSportName(s.getSport())}');
    sb.writeln('  Start Time: ${s.getStartTime()}');
    if (s.getTotalTimerTime() != null) {
      sb.writeln('  Timer Time: ${_formatDuration(s.getTotalTimerTime()!)}');
    }
    if (s.getTotalDistance() != null) {
      sb.writeln(
          '  Distance: ${(s.getTotalDistance()! / 1000).toStringAsFixed(2)} km');
    }
    if (s.getAvgSpeed() != null) {
      sb.writeln(
          '  Avg Speed: ${(s.getAvgSpeed()! * 3.6).toStringAsFixed(1)} km/h');
    }
    if (s.getAvgHeartRate() != null) {
      sb.writeln('  Avg HR: ${s.getAvgHeartRate()} bpm');
    }
    if (s.getMaxHeartRate() != null) {
      sb.writeln('  Max HR: ${s.getMaxHeartRate()} bpm');
    }
    if (s.getTotalCalories() != null) {
      sb.writeln('  Calories: ${s.getTotalCalories()} kcal');
    }
    if (m.lapMesgs.isNotEmpty) {
      sb.writeln('  Laps: ${m.lapMesgs.length}');
    }
  }

  void _writeWorkoutBrief(StringBuffer sb, FitMessages m) {
    if (m.workoutMesgs.isEmpty) return;
    final w = m.workoutMesgs.first;
    sb.writeln('Workout Details:');
    if (w.getWktName() != null) {
      sb.writeln('  Name: ${w.getWktName()}');
    }
    sb.writeln('  Sport: ${_getSportName(w.getSport())}');
    if (w.getNumValidSteps() != null) {
      sb.writeln('  Steps: ${w.getNumValidSteps()}');
    }
    if (m.workoutStepMesgs.isNotEmpty) {
      sb.writeln('  Step List:');
      for (final step in m.workoutStepMesgs) {
        final name = step.getWktStepName();
        sb.writeln('    - ${name ?? 'Step ${step.getMessageIndex() ?? ''}'}');
      }
    }
  }

  void _writeCourseBrief(StringBuffer sb, FitMessages m) {
    if (m.courseMesgs.isEmpty) return;
    final c = m.courseMesgs.first;
    sb.writeln('Course Details:');
    if (c.getName() != null) {
      sb.writeln('  Name: ${c.getName()}');
    }
    sb.writeln('  Sport: ${_getSportName(c.getSport())}');

    if (m.lapMesgs.isNotEmpty) {
      final totalDist = m.lapMesgs
          .map((e) => e.getTotalDistance() ?? 0)
          .reduce((a, b) => a + b);
      sb.writeln(
          '  Estimated Distance: ${(totalDist / 1000).toStringAsFixed(2)} km');
    }
  }

  void _writeWeightBrief(StringBuffer sb, FitMessages m) {
    if (m.weightScaleMesgs.isEmpty) return;
    sb.writeln('Weight Scale Data:');
    for (final w in m.weightScaleMesgs) {
      sb.writeln('  Timestamp: ${w.getTimestamp()}');
      if (w.getWeight() != null) {
        sb.writeln('  Weight: ${w.getWeight()!.toStringAsFixed(1)} kg');
      }
      if (w.getPercentFat() != null) {
        sb.writeln('  Body Fat: ${w.getPercentFat()}%');
      }
    }
  }

  void _writeMonitoringBrief(StringBuffer sb, FitMessages m) {
    if (m.monitoringMesgs.isEmpty) return;
    sb.writeln('Monitoring Data Summary:');
    int totalSteps = 0;
    double totalDist = 0;
    for (final mon in m.monitoringMesgs) {
      totalSteps += mon.getSteps() ?? 0;
      totalDist += mon.getDistance() ?? 0;
    }
    sb.writeln('  Total Steps: $totalSteps');
    sb.writeln('  Total Distance: ${(totalDist / 1000).toStringAsFixed(2)} km');
    sb.writeln('  Samples: ${m.monitoringMesgs.length}');
  }

  String _getSportName(int? sport) {
    if (sport == null) return 'Unknown';
    switch (sport) {
      case Sport.running:
        return 'Running';
      case Sport.cycling:
        return 'Cycling';
      case Sport.swimming:
        return 'Swimming';
      case Sport.walking:
        return 'Walking';
      case Sport.hiking:
        return 'Hiking';
      case Sport.fitnessEquipment:
        return 'Fitness Equipment';
      default:
        return 'Sport($sport)';
    }
  }

  String _formatDuration(double seconds) {
    final d = Duration(seconds: seconds.toInt());
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h}h ${m}m ${s}s';
    } else {
      return '${m}m ${s}s';
    }
  }
}
