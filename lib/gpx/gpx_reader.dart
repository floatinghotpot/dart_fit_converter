import 'package:xml/xml.dart';
import 'gpx_models.dart';

class GpxReader {
  Gpx read(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final gpxElement = document.rootElement;
    if (gpxElement.name.local != 'gpx') {
      throw const FormatException('Not a valid GPX file');
    }

    final gpx = Gpx(
      creator: gpxElement.getAttribute('creator'),
      version: gpxElement.getAttribute('version'),
    );

    // Metadata
    final metadataElement = gpxElement.getElement('metadata');
    if (metadataElement != null) {
      gpx.metadata = GpxMetadata(
        name: metadataElement.getElement('name')?.innerText,
        description: metadataElement.getElement('desc')?.innerText,
        time: _parseTime(metadataElement.getElement('time')?.innerText),
        keywords: metadataElement.getElement('keywords')?.innerText,
      );
    }

    // Waypoints
    for (var wptElement in gpxElement.findAllElements('wpt')) {
      gpx.waypoints.add(_parsePoint(wptElement, isTrackPoint: false));
    }

    // Tracks
    for (var trkElement in gpxElement.findAllElements('trk')) {
      final trk = GpxTrack(
        name: trkElement.getElement('name')?.innerText,
        number: int.tryParse(trkElement.getElement('number')?.innerText ?? ''),
        type: trkElement.getElement('type')?.innerText,
      );
      for (var segElement in trkElement.findAllElements('trkseg')) {
        final seg = GpxTrackSegment();
        for (var ptElement in segElement.findAllElements('trkpt')) {
          seg.points
              .add(_parsePoint(ptElement, isTrackPoint: true) as GpxTrackPoint);
        }
        trk.segments.add(seg);
      }
      gpx.tracks.add(trk);
    }

    return gpx;
  }

  GpxPoint _parsePoint(XmlElement element, {required bool isTrackPoint}) {
    final lat = double.tryParse(element.getAttribute('lat') ?? '');
    final lon = double.tryParse(element.getAttribute('lon') ?? '');
    final ele = double.tryParse(element.getElement('ele')?.innerText ?? '');
    final time = _parseTime(element.getElement('time')?.innerText);
    final name = element.getElement('name')?.innerText;
    final symbol = element.getElement('sym')?.innerText;

    if (isTrackPoint) {
      final pt = GpxTrackPoint(
        latitude: lat,
        longitude: lon,
        elevation: ele,
        time: time,
        name: name,
        symbol: symbol,
      );

      // Extensions
      final extensions = element.getElement('extensions');
      if (extensions != null) {
        final tpx =
            extensions.findElements('gpxtpx:TrackPointExtension').firstOrNull ??
                extensions.findElements('TrackPointExtension').firstOrNull;
        if (tpx != null) {
          pt.temperature = double.tryParse(
              tpx.getElement('gpxtpx:atemp')?.innerText ??
                  tpx.getElement('atemp')?.innerText ??
                  '');
          pt.heartRate = int.tryParse(tpx.getElement('gpxtpx:hr')?.innerText ??
              tpx.getElement('hr')?.innerText ??
              '');
          pt.cadence = int.tryParse(tpx.getElement('gpxtpx:cad')?.innerText ??
              tpx.getElement('cad')?.innerText ??
              '');
        }
      }
      return pt;
    } else {
      return GpxPoint(
        latitude: lat,
        longitude: lon,
        elevation: ele,
        time: time,
        name: name,
        symbol: symbol,
      );
    }
  }

  DateTime? _parseTime(String? timeStr) {
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }
}
