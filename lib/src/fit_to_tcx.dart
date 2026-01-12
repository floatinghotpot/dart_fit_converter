import 'dart:typed_data';
import 'package:fit_sdk/fit_sdk.dart';
import '../tcx/tcx_models.dart';
import '../tcx/tcx_writer.dart';
import 'converter.dart';

class FitToTcxConverter extends SportsDataConverter<Uint8List, String> {
  @override
  Future<String> convert(Uint8List fitBytes) async {
    final listener = FitListener();
    final decoder = Decode();

    decoder.onMesg = (Mesg mesg) {
      listener.onMesg(this, MesgEventArgs(mesg));
    };

    decoder.read(fitBytes);

    final fitMessages = listener.fitMessages;
    final tcx = Tcx();

    if (fitMessages.activityMesgs.isNotEmpty) {
      final activityMesg = fitMessages.activityMesgs.first;
      final sessionMesg = fitMessages.sessionMesgs.isNotEmpty
          ? fitMessages.sessionMesgs.first
          : null;

      final activity = TcxActivity(
        id: sessionMesg?.getStartTime() ??
            activityMesg.getTimestamp() ??
            DateTime.now(),
        sport: _getSportString(sessionMesg?.getSport()),
      );

      // Process Laps
      if (fitMessages.lapMesgs.isNotEmpty) {
        for (final lapMesg in fitMessages.lapMesgs) {
          final lap = TcxLap(
            startTime: lapMesg.getStartTime() ?? DateTime.now(),
            totalTimeSeconds: lapMesg.getTotalTimerTime() ?? 0.0,
            distanceMeters: lapMesg.getTotalDistance() ?? 0.0,
            calories: lapMesg.getTotalCalories() ?? 0,
            intensity: _getIntensityString(lapMesg.getIntensity()),
            triggerMethod: _getTriggerString(lapMesg.getLapTrigger()),
            averageHeartRateBpm: lapMesg.getAvgHeartRate(),
            maximumHeartRateBpm: lapMesg.getMaxHeartRate(),
          );

          final lapStartTime = lapMesg.getStartTime();
          final lapEndTime = lapMesg.getTimestamp();

          if (lapStartTime != null && lapEndTime != null) {
            for (final record in fitMessages.recordMesgs) {
              final ts = record.getTimestamp();
              if (ts != null &&
                  ts.isAfter(lapStartTime
                      .subtract(const Duration(milliseconds: 100))) &&
                  ts.isBefore(
                      lapEndTime.add(const Duration(milliseconds: 100)))) {
                final pt = _recordToTcxPoint(record);
                if (pt != null) {
                  lap.trackPoints.add(pt);
                }
              }
            }
          }

          activity.laps.add(lap);
        }
      } else {
        // Fallback: one lap from session
        final lap = TcxLap(
          startTime: sessionMesg?.getStartTime() ?? DateTime.now(),
          totalTimeSeconds: sessionMesg?.getTotalTimerTime() ?? 0.0,
          distanceMeters: sessionMesg?.getTotalDistance() ?? 0.0,
          calories: sessionMesg?.getTotalCalories() ?? 0,
        );

        for (final record in fitMessages.recordMesgs) {
          final pt = _recordToTcxPoint(record);
          if (pt != null) lap.trackPoints.add(pt);
        }
        activity.laps.add(lap);
      }

      tcx.activities.add(activity);
    }

    return TcxWriter().write(tcx);
  }

  TcxTrackPoint? _recordToTcxPoint(RecordMesg record) {
    final lat = record.getPositionLat();
    final lon = record.getPositionLong();
    final time = record.getTimestamp();

    if (time == null) return null;

    final pt = TcxTrackPoint(time: time);
    if (lat != null && lon != null) {
      pt.latitude = lat * (180.0 / 2147483648.0);
      pt.longitude = lon * (180.0 / 2147483648.0);
    }

    pt.altitudeMeters = record.getEnhancedAltitude() ?? record.getAltitude();
    pt.distanceMeters = record.getDistance();
    pt.heartRateBpm = record.getHeartRate();
    pt.cadence = record.getCadence();
    pt.speed = record.getEnhancedSpeed() ?? record.getSpeed();
    pt.watts = record.getPower();

    return pt;
  }

  String _getSportString(int? sport) {
    if (sport == null) return 'Other';
    switch (sport) {
      case Sport.running:
        return 'Running';
      case Sport.cycling:
        return 'Biking';
      case Sport.swimming:
        return 'Other';
      default:
        return 'Other';
    }
  }

  String _getIntensityString(int? intensity) {
    return 'Active';
  }

  String _getTriggerString(int? trigger) {
    return 'Manual';
  }
}
