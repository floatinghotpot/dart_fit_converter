import 'dart:typed_data';
import 'dart:math' as math;
import 'package:fit_sdk/fit_sdk.dart';

class FitMerger {
  static const int fitEpochOffset = 631065600000;

  Future<Uint8List> merge(List<Uint8List> sourceList) async {
    if (sourceList.isEmpty) return Uint8List(0);
    if (sourceList.length == 1) return sourceList[0];

    final baseMessages = _decode(sourceList[0]);
    if (baseMessages.sessionMesgs.isEmpty) {
      throw Exception('First FIT file has no session data');
    }

    final mergedFitMessages = _cloneFitMessages(baseMessages);
    mergedFitMessages.recordMesgs.clear();
    mergedFitMessages.lapMesgs.clear();
    mergedFitMessages.eventMesgs.clear();

    double totalDistance = 0;
    int lapIndex = 0;

    final allSessions = <SessionMesg>[];

    for (int i = 0; i < sourceList.length; i++) {
      final childMessages = _decode(sourceList[i]);
      if (childMessages.sessionMesgs.isEmpty) continue;

      final curSession = childMessages.sessionMesgs.first;
      allSessions.add(curSession);

      double baseDistanceForThisChild = totalDistance;

      // Records
      for (final record in childMessages.recordMesgs) {
        final newRecord = RecordMesg.fromMesg(record);
        final recordDist = record.getDistance() ?? 0.0;
        newRecord.setFieldValue(
          RecordMesg.fieldDistance,
          baseDistanceForThisChild + recordDist,
        );
        mergedFitMessages.recordMesgs.add(newRecord);
        totalDistance = baseDistanceForThisChild + recordDist;
      }

      // Laps
      if (childMessages.lapMesgs.isNotEmpty) {
        for (final lap in childMessages.lapMesgs) {
          final newLap = LapMesg.fromMesg(lap);
          newLap.setFieldValue(LapMesg.fieldMessageIndex, lapIndex++);
          mergedFitMessages.lapMesgs.add(newLap);
        }
      } else {
        final newLap = LapMesg();
        newLap.setFieldValue(LapMesg.fieldMessageIndex, lapIndex++);
        newLap.setFieldValue(
          LapMesg.fieldTotalTimerTime,
          curSession.getTotalTimerTime(),
        );
        newLap.setFieldValue(
          LapMesg.fieldTotalElapsedTime,
          curSession.getTotalElapsedTime(),
        );
        newLap.setFieldValue(
          LapMesg.fieldTotalDistance,
          curSession.getTotalDistance(),
        );

        final startTs = curSession.getStartTime();
        if (startTs != null) {
          newLap.setFieldValue(LapMesg.fieldStartTime, _dateTimeToFit(startTs));
          final duration = curSession.getTotalElapsedTime() ?? 0.0;
          newLap.setFieldValue(
            LapMesg.fieldTimestamp,
            _dateTimeToFit(startTs.add(Duration(seconds: duration.toInt()))),
          );
        }
        mergedFitMessages.lapMesgs.add(newLap);
      }

      // Events
      mergedFitMessages.eventMesgs.addAll(
        childMessages.eventMesgs.map((e) => EventMesg.fromMesg(e)),
      );
    }

    if (mergedFitMessages.sessionMesgs.isNotEmpty) {
      final mergerSession = mergedFitMessages.sessionMesgs.first;
      _fixMergerSession(
        mergerSession,
        allSessions,
        mergedFitMessages.recordMesgs,
      );
      mergerSession.setFieldValue(
        SessionMesg.fieldNumLaps,
        mergedFitMessages.lapMesgs.length,
      );
      mergerSession.setFieldValue(
        SessionMesg.fieldTotalDistance,
        totalDistance,
      );

      if (mergedFitMessages.activityMesgs.isNotEmpty) {
        final activity = mergedFitMessages.activityMesgs.first;
        if (mergedFitMessages.recordMesgs.isNotEmpty) {
          final lastTs = mergedFitMessages.recordMesgs.last.getTimestamp();
          if (lastTs != null) {
            activity.setFieldValue(
              ActivityMesg.fieldTimestamp,
              _dateTimeToFit(lastTs),
            );
          }
        }
      }
    }

    return _encode(mergedFitMessages);
  }

  Future<Uint8List> cut(
    Uint8List fitBytes,
    int startOffset,
    int endOffset,
  ) async {
    final messages = _decode(fitBytes);

    // Find base start time from session or first record
    int? baseStartTimeUnix;
    if (messages.sessionMesgs.isNotEmpty) {
      baseStartTimeUnix =
          messages.sessionMesgs.first.getStartTime()?.millisecondsSinceEpoch !=
                  null
              ? messages.sessionMesgs.first
                      .getStartTime()!
                      .millisecondsSinceEpoch ~/
                  1000
              : null;
    }

    if (baseStartTimeUnix == null && messages.recordMesgs.isNotEmpty) {
      baseStartTimeUnix = messages.recordMesgs.first
                  .getTimestamp()
                  ?.millisecondsSinceEpoch !=
              null
          ? messages.recordMesgs.first.getTimestamp()!.millisecondsSinceEpoch ~/
              1000
          : null;
    }

    if (baseStartTimeUnix == null) {
      throw Exception('Could not determine base start time for cutting');
    }

    final startTime = baseStartTimeUnix + startOffset;
    final endTime = baseStartTimeUnix + endOffset;

    final cutMessages = _cloneFitMessages(messages);

    cutMessages.recordMesgs.clear();
    cutMessages.lapMesgs.clear();
    cutMessages.eventMesgs.clear();

    double startDistance = -1.0;

    for (final record in messages.recordMesgs) {
      final recordUnix = record.getTimestamp()?.millisecondsSinceEpoch != null
          ? record.getTimestamp()!.millisecondsSinceEpoch ~/ 1000
          : 0;

      if (recordUnix >= startTime && recordUnix <= endTime) {
        final newRecord = RecordMesg.fromMesg(record);
        if (startDistance < 0) {
          startDistance = record.getDistance() ?? 0.0;
        }
        final dist = record.getDistance() ?? 0.0;
        newRecord.setFieldValue(RecordMesg.fieldDistance, dist - startDistance);
        cutMessages.recordMesgs.add(newRecord);
      }
    }

    for (final lap in messages.lapMesgs) {
      final start = (lap.getStartTime()?.millisecondsSinceEpoch ?? 0) ~/ 1000;
      final end = (lap.getTimestamp()?.millisecondsSinceEpoch ?? 0) ~/ 1000;
      if (start >= startTime && end <= endTime) {
        cutMessages.lapMesgs.add(LapMesg.fromMesg(lap));
      }
    }

    for (final event in messages.eventMesgs) {
      final ts = (event.getTimestamp()?.millisecondsSinceEpoch ?? 0) ~/ 1000;
      if (ts >= startTime && ts <= endTime) {
        cutMessages.eventMesgs.add(EventMesg.fromMesg(event));
      }
    }

    if (cutMessages.recordMesgs.isEmpty) {
      return Uint8List(0);
    }

    if (cutMessages.sessionMesgs.isNotEmpty) {
      final session = cutMessages.sessionMesgs.first;
      final firstRecordTs = cutMessages.recordMesgs.first.getTimestamp();
      final lastRecordTs = cutMessages.recordMesgs.last.getTimestamp();

      if (firstRecordTs != null)
        session.setFieldValue(
          SessionMesg.fieldStartTime,
          _dateTimeToFit(firstRecordTs),
        );
      if (lastRecordTs != null)
        session.setFieldValue(
          SessionMesg.fieldTimestamp,
          _dateTimeToFit(lastRecordTs),
        );

      if (firstRecordTs != null && lastRecordTs != null) {
        final duration =
            lastRecordTs.difference(firstRecordTs).inSeconds.toDouble();
        session.setFieldValue(SessionMesg.fieldTotalElapsedTime, duration);
        session.setFieldValue(SessionMesg.fieldTotalTimerTime, duration);
      }

      final lastDist = (cutMessages.recordMesgs.last.getDistance() ?? 0.0);
      session.setFieldValue(SessionMesg.fieldTotalDistance, lastDist);
      session.setFieldValue(
        SessionMesg.fieldNumLaps,
        cutMessages.lapMesgs.length,
      );

      _fixSessionStats(session, cutMessages.recordMesgs);
    }

    if (cutMessages.activityMesgs.isNotEmpty) {
      final activity = cutMessages.activityMesgs.first;
      final lastTs = cutMessages.recordMesgs.last.getTimestamp();
      if (lastTs != null)
        activity.setFieldValue(
          ActivityMesg.fieldTimestamp,
          _dateTimeToFit(lastTs),
        );

      final firstTs = cutMessages.recordMesgs.first.getTimestamp();
      if (firstTs != null && lastTs != null) {
        final duration = lastTs.difference(firstTs).inSeconds.toDouble();
        activity.setFieldValue(ActivityMesg.fieldTotalTimerTime, duration);
      }
    }

    return _encode(cutMessages);
  }

  FitMessages _decode(Uint8List bytes) {
    final decoder = Decode();
    final listener = FitListener();
    decoder.onMesg = (mesg) => listener.onMesg(decoder, MesgEventArgs(mesg));
    decoder.read(bytes);
    return listener.fitMessages;
  }

  Uint8List _encode(FitMessages messages) {
    final encoder = Encode();
    encoder.open();

    final allMesgs = _collectMessages(messages);

    // Track which global message numbers we've seen and assign local numbers
    final Map<int, int> globalToLocal = {};
    int nextLocalNum = 0;

    // Track the last definition written for each local number
    final Map<int, MesgDefinition> lastDefinitions = {};

    for (final mesg in allMesgs) {
      // Clean up the message: remove fields with no values
      // This is critical because MesgDefinition.fromMesg() will create
      // definitions for all fields, but Mesg.write() only writes fields with values
      mesg.fields.removeWhere((field) => field.values.isEmpty);

      final globalNum = mesg.num;

      // Assign a local number if we haven't seen this global number before
      if (!globalToLocal.containsKey(globalNum)) {
        if (nextLocalNum >= 16) {
          // FIT protocol only supports 16 local message numbers (0-15)
          // Reuse local number 15 for all subsequent types
          // This allows swapping definition for type 15 frequently
          globalToLocal[globalNum] = 15;
        } else {
          globalToLocal[globalNum] = nextLocalNum++;
        }
      }

      final localNum = globalToLocal[globalNum]!;
      mesg.localNum = localNum;

      // Create definition
      final def = MesgDefinition.fromMesg(mesg);
      def.localMesgNum = localNum;

      // Only write definition if it's different from the last one for this local number
      final lastDef = lastDefinitions[localNum];
      bool needNewDef = false;

      if (lastDef == null) {
        needNewDef = true;
      } else {
        if (!_definitionsEqual(lastDef, def)) {
          needNewDef = true;
        }
      }

      if (needNewDef) {
        encoder.writeMesgDefinition(def);
        lastDefinitions[localNum] = def;
      }

      // Write message - IMPORTANT: pass the definition so Mesg.write() uses it
      // instead of creating its own
      encoder.writeMesg(mesg, def);
    }

    return encoder.close();
  }

  bool _definitionsEqual(MesgDefinition a, MesgDefinition b) {
    if (a.globalMesgNum != b.globalMesgNum) return false;

    final aFields = a.getFields();
    final bFields = b.getFields();

    if (aFields.length != bFields.length) return false;

    for (int i = 0; i < aFields.length; i++) {
      if (aFields[i].num != bFields[i].num ||
          aFields[i].size != bFields[i].size ||
          aFields[i].type != bFields[i].type) {
        return false;
      }
    }

    // Check developer fields
    if (a.developerFieldDefinitions.length !=
        b.developerFieldDefinitions.length) {
      return false;
    }

    // Assuming developer fields are in same order for simplicity
    for (int i = 0; i < a.developerFieldDefinitions.length; i++) {
      final da = a.developerFieldDefinitions[i];
      final db = b.developerFieldDefinitions[i];
      if (da.fieldNum != db.fieldNum ||
          da.size != db.size ||
          da.developerDataIndex != db.developerDataIndex) {
        return false;
      }
    }

    return true;
  }

  List<Mesg> _collectMessages(FitMessages m) {
    final header = <Mesg>[];
    header.addAll(m.fileIdMesgs);
    header.addAll(m.fileCreatorMesgs);
    header.addAll(m.softwareMesgs);
    header.addAll(m.deviceInfoMesgs);

    final settings = <Mesg>[];
    settings.addAll(m.userProfileMesgs);
    settings.addAll(m.sportMesgs);

    final data = <Mesg>[];
    data.addAll(m.recordMesgs);
    data.addAll(m.eventMesgs);
    data.addAll(m.lapMesgs);
    // Sort by timestamp if available
    data.sort((a, b) {
      final ta = a.getFieldValue(253) as int? ?? 0;
      final tb = b.getFieldValue(253) as int? ?? 0;
      return ta.compareTo(tb);
    });

    final summary = <Mesg>[];
    summary.addAll(m.sessionMesgs);
    summary.addAll(m.activityMesgs);

    return [...header, ...settings, ...data, ...summary];
  }

  FitMessages _cloneFitMessages(FitMessages original) {
    final clone = FitMessages();
    clone.fileIdMesgs.addAll(
      original.fileIdMesgs.map((e) => FileIdMesg.fromMesg(e)),
    );
    clone.fileCreatorMesgs.addAll(
      original.fileCreatorMesgs.map((e) => FileCreatorMesg.fromMesg(e)),
    );
    clone.softwareMesgs.addAll(
      original.softwareMesgs.map((e) => SoftwareMesg.fromMesg(e)),
    );
    clone.deviceInfoMesgs.addAll(
      original.deviceInfoMesgs.map((e) => DeviceInfoMesg.fromMesg(e)),
    );
    clone.userProfileMesgs.addAll(
      original.userProfileMesgs.map((e) => UserProfileMesg.fromMesg(e)),
    );
    clone.sportMesgs.addAll(
      original.sportMesgs.map((e) => SportMesg.fromMesg(e)),
    );
    clone.recordMesgs.addAll(
      original.recordMesgs.map((e) => RecordMesg.fromMesg(e)),
    );
    clone.lapMesgs.addAll(original.lapMesgs.map((e) => LapMesg.fromMesg(e)));
    clone.sessionMesgs.addAll(
      original.sessionMesgs.map((e) => SessionMesg.fromMesg(e)),
    );
    clone.activityMesgs.addAll(
      original.activityMesgs.map((e) => ActivityMesg.fromMesg(e)),
    );
    clone.eventMesgs.addAll(
      original.eventMesgs.map((e) => EventMesg.fromMesg(e)),
    );
    return clone;
  }

  void _fixMergerSession(
    SessionMesg ret,
    List<SessionMesg> list,
    List<RecordMesg> records,
  ) {
    double totalTimerTime = 0;
    double totalMovingTime = 0;
    int totalCalories = 0;

    for (final s in list) {
      totalTimerTime += s.getTotalTimerTime() ?? 0;
      totalMovingTime += s.getTotalMovingTime() ?? s.getTotalTimerTime() ?? 0;
      totalCalories += s.getTotalCalories() ?? 0;
    }

    ret.setFieldValue(SessionMesg.fieldTotalTimerTime, totalTimerTime);
    ret.setFieldValue(SessionMesg.fieldTotalMovingTime, totalMovingTime);
    ret.setFieldValue(SessionMesg.fieldTotalCalories, totalCalories);

    if (records.isNotEmpty) {
      _fixSessionStats(ret, records);
    }
  }

  void _fixSessionStats(SessionMesg session, List<RecordMesg> records) {
    if (records.isEmpty) return;

    double sumHr = 0;
    int countHr = 0;
    int maxHr = 0;
    int minHr = 255;

    double sumSpeed = 0;
    int countSpeed = 0;
    double maxSpeed = 0;

    double sumPower = 0;
    int countPower = 0;
    int maxPower = 0;

    double minAlt = 10000;
    double maxAlt = -1000;

    for (final r in records) {
      final hr = r.getHeartRate();
      if (hr != null) {
        sumHr += hr;
        countHr++;
        maxHr = math.max(maxHr, hr);
        minHr = math.min(minHr, hr);
      }
      final speed = r.getEnhancedSpeed() ?? r.getSpeed();
      if (speed != null) {
        sumSpeed += speed;
        countSpeed++;
        maxSpeed = math.max(maxSpeed, speed);
      }
      final power = r.getPower();
      if (power != null) {
        sumPower += power;
        countPower++;
        maxPower = math.max(maxPower, power);
      }
      final alt = r.getEnhancedAltitude() ?? r.getAltitude();
      if (alt != null) {
        minAlt = math.min(minAlt, alt);
        maxAlt = math.max(maxAlt, alt);
      }
    }

    if (countHr > 0) {
      session.setFieldValue(
        SessionMesg.fieldAvgHeartRate,
        (sumHr / countHr).round(),
      );
      session.setFieldValue(SessionMesg.fieldMaxHeartRate, maxHr);
      session.setFieldValue(SessionMesg.fieldMinHeartRate, minHr);
    }
    if (countSpeed > 0) {
      final avgSpeed = sumSpeed / countSpeed;
      session.setFieldValue(SessionMesg.fieldAvgSpeed, avgSpeed);
      session.setFieldValue(SessionMesg.fieldMaxSpeed, maxSpeed);
      session.setFieldValue(SessionMesg.fieldEnhancedAvgSpeed, avgSpeed);
      session.setFieldValue(SessionMesg.fieldEnhancedMaxSpeed, maxSpeed);
    }
    if (countPower > 0) {
      session.setFieldValue(
        SessionMesg.fieldAvgPower,
        (sumPower / countPower).round(),
      );
      session.setFieldValue(SessionMesg.fieldMaxPower, maxPower);
    }
    if (minAlt < 10000) {
      session.setFieldValue(SessionMesg.fieldMinAltitude, minAlt);
      session.setFieldValue(SessionMesg.fieldMaxAltitude, maxAlt);
      session.setFieldValue(SessionMesg.fieldEnhancedMinAltitude, minAlt);
      session.setFieldValue(SessionMesg.fieldEnhancedMaxAltitude, maxAlt);
    }
  }

  int _dateTimeToFit(DateTime dt) {
    return (dt.millisecondsSinceEpoch - fitEpochOffset) ~/ 1000;
  }
}
