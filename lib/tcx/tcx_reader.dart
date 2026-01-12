import 'package:xml/xml.dart';
import 'tcx_models.dart';

class TcxReader {
  Tcx read(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final root = document.rootElement;
    if (root.name.local != 'TrainingCenterDatabase') {
      throw const FormatException('Not a valid TCX file');
    }

    final tcx = Tcx();
    final activitiesElement = root.getElement('Activities');
    if (activitiesElement != null) {
      for (var activityElement in activitiesElement.findElements('Activity')) {
        final activity = TcxActivity(
          sport: activityElement.getAttribute('Sport'),
          id: _parseTime(activityElement.getElement('Id')?.innerText),
          creator: activityElement
              .getElement('Creator')
              ?.getElement('Name')
              ?.innerText,
        );

        for (var lapElement in activityElement.findElements('Lap')) {
          final lap = TcxLap(
            startTime: _parseTime(lapElement.getAttribute('StartTime')),
            totalTimeSeconds: double.tryParse(
                lapElement.getElement('TotalTimeSeconds')?.innerText ?? ''),
            distanceMeters: double.tryParse(
                lapElement.getElement('DistanceMeters')?.innerText ?? ''),
            maxSpeed: double.tryParse(
                lapElement.getElement('MaximumSpeed')?.innerText ?? ''),
            calories: int.tryParse(
                lapElement.getElement('Calories')?.innerText ?? ''),
            intensity: lapElement.getElement('Intensity')?.innerText,
            triggerMethod: lapElement.getElement('TriggerMethod')?.innerText,
          );

          final avgHr = lapElement
              .getElement('AverageHeartRateBpm')
              ?.getElement('Value')
              ?.innerText;
          if (avgHr != null) lap.averageHeartRateBpm = int.tryParse(avgHr);

          final maxHr = lapElement
              .getElement('MaximumHeartRateBpm')
              ?.getElement('Value')
              ?.innerText;
          if (maxHr != null) lap.maximumHeartRateBpm = int.tryParse(maxHr);

          final trackElement = lapElement.getElement('Track');
          if (trackElement != null) {
            for (var tpElement in trackElement.findElements('Trackpoint')) {
              final pt = TcxTrackPoint(
                time: _parseTime(tpElement.getElement('Time')?.innerText),
                altitudeMeters: double.tryParse(
                    tpElement.getElement('AltitudeMeters')?.innerText ?? ''),
                distanceMeters: double.tryParse(
                    tpElement.getElement('DistanceMeters')?.innerText ?? ''),
                cadence: int.tryParse(
                    tpElement.getElement('Cadence')?.innerText ?? ''),
              );

              final posElement = tpElement.getElement('Position');
              if (posElement != null) {
                pt.latitude = double.tryParse(
                    posElement.getElement('LatitudeDegrees')?.innerText ?? '');
                pt.longitude = double.tryParse(
                    posElement.getElement('LongitudeDegrees')?.innerText ?? '');
              }

              final hrElement = tpElement
                  .getElement('HeartRateBpm')
                  ?.getElement('Value')
                  ?.innerText;
              if (hrElement != null) pt.heartRateBpm = int.tryParse(hrElement);

              final extensions = tpElement.getElement('Extensions');
              if (extensions != null) {
                final tpx = extensions.findElements('ns3:TPX').firstOrNull ??
                    extensions.findElements('TPX').firstOrNull;
                if (tpx != null) {
                  pt.speed = double.tryParse(
                      tpx.getElement('ns3:Speed')?.innerText ??
                          tpx.getElement('Speed')?.innerText ??
                          '');
                  pt.watts = int.tryParse(
                      tpx.getElement('ns3:Watts')?.innerText ??
                          tpx.getElement('Watts')?.innerText ??
                          '');
                }
              }

              lap.trackPoints.add(pt);
            }
          }
          activity.laps.add(lap);
        }
        tcx.activities.add(activity);
      }
    }

    return tcx;
  }

  DateTime? _parseTime(String? timeStr) {
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }
}
