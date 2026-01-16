import 'dart:typed_data';
import 'package:fit_sdk/fit_sdk.dart';
import '../tcx/tcx_reader.dart';
import '../tcx/tcx_models.dart';
import 'format_converter.dart';

class TcxToFitConverter extends SportsDataConverter<String, Uint8List> {
  static const int fitEpochOffset = 631065600000;

  @override
  Future<Uint8List> convert(String tcxString) async {
    final tcx = TcxReader().read(tcxString);
    final encoder = Encode();
    encoder.open();

    if (tcx.activities.isEmpty) {
      return encoder.close();
    }

    final tcxActivity = tcx.activities.first;

    // 1. File ID
    final fileId = FileIdMesg();
    fileId.setFieldValue(FileIdMesg.fieldType, File.activity);
    fileId.setFieldValue(
      FileIdMesg.fieldManufacturer,
      Manufacturer.development,
    );
    fileId.setFieldValue(FileIdMesg.fieldProduct, 0);
    fileId.setFieldValue(FileIdMesg.fieldSerialNumber, 67890);
    fileId.setFieldValue(
      FileIdMesg.fieldTimeCreated,
      _dateTimeToFit(tcxActivity.id ?? DateTime.now()),
    );
    _writeMesg(encoder, fileId);

    // Collect all records from laps
    final allTcxPoints = <TcxTrackPoint>[];
    for (final lap in tcxActivity.laps) {
      allTcxPoints.addAll(lap.trackPoints);
    }

    if (allTcxPoints.isEmpty) {
      return encoder.close();
    }

    // 2. Activity & Session
    final startTime = allTcxPoints.first.time ?? DateTime.now();
    final endTime = allTcxPoints.last.time ?? DateTime.now();
    final totalDuration = endTime.difference(startTime).inSeconds.toDouble();

    final activity = ActivityMesg();
    activity.setFieldValue(
      ActivityMesg.fieldTimestamp,
      _dateTimeToFit(endTime),
    );
    activity.setFieldValue(ActivityMesg.fieldTotalTimerTime, totalDuration);
    activity.setFieldValue(ActivityMesg.fieldNumSessions, 1);
    activity.setFieldValue(ActivityMesg.fieldType, ActivityType.generic);
    _writeMesg(encoder, activity);

    final session = SessionMesg();
    session.setFieldValue(
      SessionMesg.fieldStartTime,
      _dateTimeToFit(startTime),
    );
    session.setFieldValue(SessionMesg.fieldTimestamp, _dateTimeToFit(endTime));
    session.setFieldValue(SessionMesg.fieldTotalTimerTime, totalDuration);
    session.setFieldValue(SessionMesg.fieldTotalElapsedTime, totalDuration);
    session.setFieldValue(
      SessionMesg.fieldSport,
      _stringToSport(tcxActivity.sport),
    );
    session.setFieldValue(SessionMesg.fieldNumLaps, tcxActivity.laps.length);
    _writeMesg(encoder, session);

    // 3. Laps & Records
    for (int lapIdx = 0; lapIdx < tcxActivity.laps.length; lapIdx++) {
      final tcxLap = tcxActivity.laps[lapIdx];
      final lap = LapMesg();
      lap.setFieldValue(
        LapMesg.fieldStartTime,
        _dateTimeToFit(tcxLap.startTime ?? startTime),
      );
      lap.setFieldValue(
        LapMesg.fieldTimestamp,
        _dateTimeToFit(tcxLap.trackPoints.lastOrNull?.time ?? endTime),
      );
      lap.setFieldValue(LapMesg.fieldTotalDistance, tcxLap.distanceMeters);
      lap.setFieldValue(LapMesg.fieldTotalTimerTime, tcxLap.totalTimeSeconds);
      lap.setFieldValue(LapMesg.fieldTotalCalories, tcxLap.calories);
      lap.setFieldValue(LapMesg.fieldAvgHeartRate, tcxLap.averageHeartRateBpm);
      lap.setFieldValue(LapMesg.fieldMaxHeartRate, tcxLap.maximumHeartRateBpm);
      _writeMesg(encoder, lap);

      for (final pt in tcxLap.trackPoints) {
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
        if (pt.altitudeMeters != null) {
          record.setFieldValue(
            RecordMesg.fieldEnhancedAltitude,
            pt.altitudeMeters!,
          );
        }
        if (pt.distanceMeters != null) {
          record.setFieldValue(RecordMesg.fieldDistance, pt.distanceMeters!);
        }
        if (pt.heartRateBpm != null) {
          record.setFieldValue(RecordMesg.fieldHeartRate, pt.heartRateBpm!);
        }
        if (pt.cadence != null) {
          record.setFieldValue(RecordMesg.fieldCadence, pt.cadence!);
        }
        if (pt.speed != null) {
          record.setFieldValue(RecordMesg.fieldEnhancedSpeed, pt.speed!);
        }
        _writeMesg(encoder, record);
      }
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
    switch (s) {
      case 'biking':
      case 'cycling':
        return Sport.cycling;
      case 'running':
        return Sport.running;
      case 'swimming':
        return Sport.swimming;
      default:
        return Sport.generic;
    }
  }

  int _degreesToSemicircles(double degrees) {
    return (degrees * (2147483648.0 / 180.0)).round();
  }
}

extension ListLastOrNull<E> on Iterable<E> {
  E? get lastOrNull => isEmpty ? null : last;
}
