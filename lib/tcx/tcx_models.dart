class TcxTrackPoint {
  DateTime? time;
  double? latitude;
  double? longitude;
  double? altitudeMeters;
  double? distanceMeters;
  int? heartRateBpm;
  int? cadence;
  double? speed;
  int? watts;

  TcxTrackPoint({
    this.time,
    this.latitude,
    this.longitude,
    this.altitudeMeters,
    this.distanceMeters,
    this.heartRateBpm,
    this.cadence,
    this.speed,
    this.watts,
  });
}

class TcxLap {
  DateTime? startTime;
  double? totalTimeSeconds;
  double? distanceMeters;
  double? maxSpeed;
  int? calories;
  int? averageHeartRateBpm;
  int? maximumHeartRateBpm;
  String? intensity;
  String? triggerMethod;
  final List<TcxTrackPoint> trackPoints = [];

  TcxLap({
    this.startTime,
    this.totalTimeSeconds,
    this.distanceMeters,
    this.maxSpeed,
    this.calories,
    this.averageHeartRateBpm,
    this.maximumHeartRateBpm,
    this.intensity,
    this.triggerMethod,
  });
}

class TcxActivity {
  String? sport;
  DateTime? id;
  final List<TcxLap> laps = [];
  String? creator;

  TcxActivity({this.sport, this.id, this.creator});
}

class Tcx {
  final List<TcxActivity> activities = [];

  Tcx();
}
