import '../gpx/gpx_reader.dart';
import '../tcx/tcx_models.dart';
import '../tcx/tcx_writer.dart';
import 'format_converter.dart';

class GpxToTcxConverter extends SportsDataConverter<String, String> {
  @override
  Future<String> convert(String gpxString) async {
    final gpx = GpxReader().read(gpxString);
    final tcx = Tcx();

    for (var track in gpx.tracks) {
      final activity = TcxActivity(
        sport: _guessSport(track.name),
        id: gpx.metadata?.time ?? DateTime.now(),
        creator: gpx.creator,
      );

      for (var segment in track.segments) {
        if (segment.points.isEmpty) continue;

        final lap = TcxLap(startTime: segment.points.first.time);

        for (var pt in segment.points) {
          lap.trackPoints.add(
            TcxTrackPoint(
              time: pt.time,
              latitude: pt.latitude,
              longitude: pt.longitude,
              altitudeMeters: pt.elevation,
              heartRateBpm: pt.heartRate,
              cadence: pt.cadence,
            ),
          );
        }

        // Calculate some basic lap stats if points are not empty
        if (lap.trackPoints.isNotEmpty) {
          lap.totalTimeSeconds = lap.trackPoints.last.time
              ?.difference(lap.trackPoints.first.time ?? DateTime.now())
              .inSeconds
              .toDouble();
        }

        activity.laps.add(lap);
      }
      tcx.activities.add(activity);
    }

    return TcxWriter().write(tcx);
  }

  String _guessSport(String? name) {
    if (name == null) return 'Other';
    final lower = name.toLowerCase();
    if (lower.contains('run')) return 'Running';
    if (lower.contains('bike') || lower.contains('cycl')) return 'Biking';
    if (lower.contains('walk')) return 'Walking';
    return 'Other';
  }
}
