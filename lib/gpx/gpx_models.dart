enum GpxColor {
  black(0xff000000),
  darkRed(0xff8b0000),
  darkGreen(0xff008b00),
  darkYellow(0x8b8b0000),
  darkBlue(0Xff00008b),
  darkMagenta(0xff8b008b),
  darkCyan(0xff008b8b),
  lightGray(0xffd3d3d3),
  darkGray(0xffa9a9a9),
  red(0xffff0000),
  green(0xff00b000),
  yellow(0xffffff00),
  blue(0xff0000ff),
  magenta(0xffff00ff),
  cyan(0xff00ffff),
  white(0xffffffff),
  transparent(0x00ffffff);

  final int value;
  const GpxColor(this.value);
}

class GpxLink {
  String? href;
  String? text;
  String? mimeType;

  GpxLink({this.href, this.text, this.mimeType});
}

class GpxMetadata {
  String? name;
  String? description;
  DateTime? time;
  String? keywords;
  GpxLink? link;

  GpxMetadata(
      {this.name, this.description, this.time, this.keywords, this.link});
}

class GpxPoint {
  double? latitude;
  double? longitude;
  double? elevation;
  DateTime? time;
  String? name;
  String? comment;
  String? description;
  String? symbol;

  GpxPoint({
    this.latitude,
    this.longitude,
    this.elevation,
    this.time,
    this.name,
    this.comment,
    this.description,
    this.symbol,
  });

  bool get isValid =>
      latitude != null &&
      longitude != null &&
      latitude! >= -90.0 &&
      latitude! <= 90.0 &&
      longitude! >= -180.0 &&
      longitude! <= 180.0;
}

class GpxTrackPoint extends GpxPoint {
  double? temperature;
  int? heartRate;
  int? cadence;
  double? speed;

  GpxTrackPoint({
    super.latitude,
    super.longitude,
    super.elevation,
    super.time,
    super.name,
    super.comment,
    super.description,
    super.symbol,
    this.temperature,
    this.heartRate,
    this.cadence,
    this.speed,
  });
}

class GpxTrackSegment {
  final List<GpxTrackPoint> points = [];

  GpxTrackSegment();
}

class GpxTrack {
  String? name;
  String? comment;
  String? description;
  int? number;
  GpxColor? displayColor;
  String? type;
  final List<GpxTrackSegment> segments = [];

  GpxTrack(
      {this.name,
      this.comment,
      this.description,
      this.number,
      this.displayColor,
      this.type});
}

class Gpx {
  String? creator;
  String? version = "1.1";
  GpxMetadata? metadata;
  final List<GpxPoint> waypoints = [];
  final List<GpxTrack> tracks = [];

  Gpx({this.creator, this.version, this.metadata});
}
