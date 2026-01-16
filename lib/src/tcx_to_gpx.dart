import '../gpx/gpx_models.dart';
import '../gpx/gpx_writer.dart';
import '../tcx/tcx_reader.dart';
import 'format_converter.dart';

class TcxToGpxConverter extends SportsDataConverter<String, String> {
  @override
  Future<String> convert(String tcxString) async {
    final tcx = TcxReader().read(tcxString);
    final gpx = Gpx(creator: 'FitConverter');

    if (tcx.activities.isNotEmpty) {
      final firstActivity = tcx.activities.first;
      gpx.metadata = GpxMetadata(
        time: firstActivity.id,
        name: firstActivity.sport,
      );
    }

    for (var activity in tcx.activities) {
      final track = GpxTrack(name: activity.sport ?? 'Activity');

      for (var lap in activity.laps) {
        final segment = GpxTrackSegment();
        for (var pt in lap.trackPoints) {
          segment.points.add(
            GpxTrackPoint(
              latitude: pt.latitude,
              longitude: pt.longitude,
              elevation: pt.altitudeMeters,
              time: pt.time,
              heartRate: pt.heartRateBpm,
              cadence: pt.cadence,
              speed: pt.speed,
            ),
          );
        }
        if (segment.points.isNotEmpty) {
          track.segments.add(segment);
        }
      }

      if (track.segments.isNotEmpty) {
        gpx.tracks.add(track);
      }
    }

    return GpxWriter().write(gpx);
  }
}
