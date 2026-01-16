import 'dart:typed_data';
import 'dart:math' as math;
import 'package:fit_sdk/fit_sdk.dart';
import '../gpx/gpx_reader.dart';
import '../gpx/gpx_models.dart';
import 'format_converter.dart';

class GpxToFitConverter extends SportsDataConverter<String, Uint8List> {
  static const int fitEpochOffset = 631065600000;

  @override
  Future<Uint8List> convert(String gpxString) async {
    final gpx = GpxReader().read(gpxString);
    final encoder = Encode();
    encoder.open();

    // 1. File ID
    final fileId = FileIdMesg();
    fileId.setFieldValue(FileIdMesg.fieldType, File.activity);
    fileId.setFieldValue(
      FileIdMesg.fieldManufacturer,
      Manufacturer.development,
    );
    fileId.setFieldValue(FileIdMesg.fieldProduct, 0);
    fileId.setFieldValue(FileIdMesg.fieldSerialNumber, 12345);
    if (gpx.metadata?.time != null) {
      fileId.setFieldValue(
        FileIdMesg.fieldTimeCreated,
        _dateTimeToFit(gpx.metadata!.time!),
      );
    } else {
      fileId.setFieldValue(
        FileIdMesg.fieldTimeCreated,
        _dateTimeToFit(DateTime.now()),
      );
    }
    _writeMesg(encoder, fileId);

    // Collect all points
    final allPoints = <GpxTrackPoint>[];
    for (final track in gpx.tracks) {
      for (final segment in track.segments) {
        allPoints.addAll(segment.points);
      }
    }

    if (allPoints.isEmpty) {
      return encoder.close();
    }

    final trackType = gpx.tracks.isNotEmpty ? gpx.tracks.first.type : null;
    final sport = _stringToSport(trackType);
    final double lapTriggerDistance =
        (sport == Sport.cycling) ? 5000.0 : 1000.0;

    final startTime = allPoints.first.time ?? DateTime.now();
    final endTime = allPoints.last.time ?? DateTime.now();
    final totalDuration = endTime.difference(startTime).inSeconds.toDouble();

    // 2. Activity
    final activity = ActivityMesg();
    activity.setFieldValue(
      ActivityMesg.fieldTimestamp,
      _dateTimeToFit(endTime),
    );
    activity.setFieldValue(ActivityMesg.fieldTotalTimerTime, totalDuration);
    activity.setFieldValue(ActivityMesg.fieldNumSessions, 1);
    activity.setFieldValue(ActivityMesg.fieldType, ActivityType.generic);
    _writeMesg(encoder, activity);

    double totalDistance = 0.0;
    final List<LapMesg> laps = [];

    DateTime lapStartTime = startTime;
    double lapStartDistance = 0.0;
    int lapIndex = 0;

    // 3. Records (and calculate distance/laps)
    for (int i = 0; i < allPoints.length; i++) {
      final pt = allPoints[i];

      // Calculate distance from previous point
      if (i > 0) {
        final prev = allPoints[i - 1];
        if (pt.latitude != null &&
            pt.longitude != null &&
            prev.latitude != null &&
            prev.longitude != null) {
          totalDistance += _calculateDistance(
            prev.latitude!,
            prev.longitude!,
            pt.latitude!,
            pt.longitude!,
          );
        }
      }

      final record = RecordMesg();
      if (pt.time != null) {
        record.setFieldValue(
          RecordMesg.fieldTimestamp,
          _dateTimeToFit(pt.time!),
        );
      }
      if (pt.latitude != null && pt.longitude != null) {
        record.setFieldValue(
          RecordMesg.fieldPositionLat,
          _degreesToSemicircles(pt.latitude!),
        );
        record.setFieldValue(
          RecordMesg.fieldPositionLong,
          _degreesToSemicircles(pt.longitude!),
        );
      }
      if (pt.elevation != null) {
        record.setFieldValue(RecordMesg.fieldEnhancedAltitude, pt.elevation!);
      }
      if (pt.heartRate != null) {
        record.setFieldValue(RecordMesg.fieldHeartRate, pt.heartRate!);
      }
      if (pt.cadence != null) {
        record.setFieldValue(RecordMesg.fieldCadence, pt.cadence!);
      }
      if (pt.speed != null) {
        record.setFieldValue(RecordMesg.fieldEnhancedSpeed, pt.speed!);
      }
      record.setFieldValue(RecordMesg.fieldDistance, totalDistance);
      _writeMesg(encoder, record);

      // Check for New Lap
      double currentLapDist = totalDistance - lapStartDistance;
      if (currentLapDist >= lapTriggerDistance) {
        final lap = LapMesg();
        lap.setFieldValue(LapMesg.fieldMessageIndex, lapIndex++);
        lap.setFieldValue(LapMesg.fieldStartTime, _dateTimeToFit(lapStartTime));
        lap.setFieldValue(
          LapMesg.fieldTimestamp,
          _dateTimeToFit(pt.time ?? DateTime.now()),
        );
        lap.setFieldValue(LapMesg.fieldTotalDistance, currentLapDist);
        final lapDuration = (pt.time ?? DateTime.now())
            .difference(lapStartTime)
            .inSeconds
            .toDouble();
        lap.setFieldValue(LapMesg.fieldTotalTimerTime, lapDuration);
        lap.setFieldValue(LapMesg.fieldTotalElapsedTime, lapDuration);
        laps.add(lap);

        // Reset for next lap
        lapStartTime = pt.time ?? DateTime.now();
        lapStartDistance = totalDistance;
      }
    }

    // Add final lap if there's remaining distance/time
    if (totalDistance > lapStartDistance || laps.isEmpty) {
      final lap = LapMesg();
      lap.setFieldValue(LapMesg.fieldMessageIndex, lapIndex++);
      lap.setFieldValue(LapMesg.fieldStartTime, _dateTimeToFit(lapStartTime));
      lap.setFieldValue(LapMesg.fieldTimestamp, _dateTimeToFit(endTime));
      lap.setFieldValue(
        LapMesg.fieldTotalDistance,
        totalDistance - lapStartDistance,
      );
      final lapDuration = endTime.difference(lapStartTime).inSeconds.toDouble();
      lap.setFieldValue(LapMesg.fieldTotalTimerTime, lapDuration);
      lap.setFieldValue(LapMesg.fieldTotalElapsedTime, lapDuration);
      laps.add(lap);
    }

    // 4. Session (Write after activity and records, containing lap count)
    final session = SessionMesg();
    session.setFieldValue(
      SessionMesg.fieldStartTime,
      _dateTimeToFit(startTime),
    );
    session.setFieldValue(SessionMesg.fieldTimestamp, _dateTimeToFit(endTime));
    session.setFieldValue(SessionMesg.fieldTotalTimerTime, totalDuration);
    session.setFieldValue(SessionMesg.fieldTotalElapsedTime, totalDuration);
    session.setFieldValue(SessionMesg.fieldTotalDistance, totalDistance);
    session.setFieldValue(SessionMesg.fieldSport, sport);
    session.setFieldValue(SessionMesg.fieldFirstLapIndex, 0);
    session.setFieldValue(SessionMesg.fieldNumLaps, laps.length);
    _writeMesg(encoder, session);

    // 5. Laps
    for (final lap in laps) {
      _writeMesg(encoder, lap);
    }

    return encoder.close();
  }

  void _writeMesg(Encode encoder, Mesg mesg) {
    encoder.writeMesgDefinition(MesgDefinition.fromMesg(mesg));
    encoder.writeMesg(mesg);
  }

  int _dateTimeToFit(DateTime dt) {
    return (dt.millisecondsSinceEpoch - fitEpochOffset) ~/ 1000;
  }

  int _stringToSport(String? sport) {
    if (sport == null) return Sport.generic;
    final s = sport.toLowerCase();
    if (s.contains('cycling') || s.contains('biking') || s.contains('bike')) {
      return Sport.cycling;
    }
    if (s.contains('run')) {
      return Sport.running;
    }
    if (s.contains('swim')) {
      return Sport.swimming;
    }
    if (s.contains('walk')) {
      return Sport.walking;
    }
    return Sport.generic;
  }

  int _degreesToSemicircles(double degrees) {
    return (degrees * (2147483648.0 / 180.0)).round();
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double radius = 6371000; // Earth radius in meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radius * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}
