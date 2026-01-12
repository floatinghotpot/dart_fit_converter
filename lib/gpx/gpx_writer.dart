import 'package:xml/xml.dart';
import 'gpx_models.dart';

class GpxWriter {
  String write(Gpx gpx) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('gpx', attributes: {
      'version': gpx.version ?? '1.1',
      'creator': gpx.creator ?? 'GarSync',
      'xmlns': 'http://www.topografix.com/GPX/1/1',
      'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
      'xmlns:gpxtpx': 'http://www.garmin.com/xmlschemas/TrackPointExtension/v1',
      'xsi:schemaLocation':
          'http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd',
    }, nest: () {
      if (gpx.metadata != null) {
        builder.element('metadata', nest: () {
          if (gpx.metadata!.name != null)
            builder.element('name', nest: gpx.metadata!.name);
          if (gpx.metadata!.description != null)
            builder.element('desc', nest: gpx.metadata!.description);
          if (gpx.metadata!.time != null)
            builder.element('time',
                nest: gpx.metadata!.time!.toUtc().toIso8601String());
          if (gpx.metadata!.keywords != null)
            builder.element('keywords', nest: gpx.metadata!.keywords);
        });
      }

      for (var wpt in gpx.waypoints) {
        _writePoint(builder, 'wpt', wpt);
      }

      for (var trk in gpx.tracks) {
        builder.element('trk', nest: () {
          if (trk.name != null) builder.element('name', nest: trk.name);
          if (trk.number != null)
            builder.element('number', nest: trk.number.toString());
          if (trk.type != null) builder.element('type', nest: trk.type);
          for (var seg in trk.segments) {
            builder.element('trkseg', nest: () {
              for (var pt in seg.points) {
                _writePoint(builder, 'trkpt', pt);
              }
            });
          }
        });
      }
    });

    return builder.buildDocument().toXmlString(pretty: true);
  }

  void _writePoint(XmlBuilder builder, String tagName, GpxPoint pt) {
    builder.element(tagName, attributes: {
      'lat': pt.latitude.toString(),
      'lon': pt.longitude.toString(),
    }, nest: () {
      if (pt.elevation != null)
        builder.element('ele', nest: pt.elevation.toString());
      if (pt.time != null)
        builder.element('time', nest: pt.time!.toUtc().toIso8601String());
      if (pt.name != null) builder.element('name', nest: pt.name);
      if (pt.symbol != null) builder.element('sym', nest: pt.symbol);

      if (pt is GpxTrackPoint) {
        if (pt.heartRate != null ||
            pt.cadence != null ||
            pt.temperature != null) {
          builder.element('extensions', nest: () {
            builder.element('gpxtpx:TrackPointExtension', nest: () {
              if (pt.temperature != null)
                builder.element('gpxtpx:atemp',
                    nest: pt.temperature.toString());
              if (pt.heartRate != null)
                builder.element('gpxtpx:hr', nest: pt.heartRate.toString());
              if (pt.cadence != null)
                builder.element('gpxtpx:cad', nest: pt.cadence.toString());
            });
          });
        }
      }
    });
  }
}
