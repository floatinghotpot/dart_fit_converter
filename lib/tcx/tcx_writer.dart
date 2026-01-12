import 'package:xml/xml.dart';
import 'tcx_models.dart';

class TcxWriter {
  String write(Tcx tcx) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('TrainingCenterDatabase', attributes: {
      'xmlns': 'http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2',
      'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
      'xmlns:ns3': 'http://www.garmin.com/xmlschemas/ActivityExtension/v2',
      'xsi:schemaLocation':
          'http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2 http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd',
    }, nest: () {
      builder.element('Activities', nest: () {
        for (var activity in tcx.activities) {
          builder.element('Activity',
              attributes: {'Sport': activity.sport ?? 'Other'}, nest: () {
            if (activity.id != null) {
              builder.element('Id',
                  nest: activity.id!.toUtc().toIso8601String());
            }

            for (var lap in activity.laps) {
              builder.element('Lap', attributes: {
                'StartTime': lap.startTime?.toUtc().toIso8601String() ?? ''
              }, nest: () {
                if (lap.totalTimeSeconds != null) {
                  builder.element('TotalTimeSeconds',
                      nest: lap.totalTimeSeconds.toString());
                }
                if (lap.distanceMeters != null) {
                  builder.element('DistanceMeters',
                      nest: lap.distanceMeters.toString());
                }
                if (lap.maxSpeed != null) {
                  builder.element('MaximumSpeed',
                      nest: lap.maxSpeed.toString());
                }
                if (lap.calories != null) {
                  builder.element('Calories', nest: lap.calories.toString());
                }
                if (lap.averageHeartRateBpm != null) {
                  builder.element('AverageHeartRateBpm', nest: () {
                    builder.element('Value',
                        nest: lap.averageHeartRateBpm.toString());
                  });
                }
                if (lap.maximumHeartRateBpm != null) {
                  builder.element('MaximumHeartRateBpm', nest: () {
                    builder.element('Value',
                        nest: lap.maximumHeartRateBpm.toString());
                  });
                }
                if (lap.intensity != null) {
                  builder.element('Intensity', nest: lap.intensity);
                }
                if (lap.triggerMethod != null) {
                  builder.element('TriggerMethod', nest: lap.triggerMethod);
                }

                builder.element('Track', nest: () {
                  for (var pt in lap.trackPoints) {
                    builder.element('Trackpoint', nest: () {
                      if (pt.time != null) {
                        builder.element('Time',
                            nest: pt.time!.toUtc().toIso8601String());
                      }
                      if (pt.latitude != null && pt.longitude != null) {
                        builder.element('Position', nest: () {
                          builder.element('LatitudeDegrees',
                              nest: pt.latitude.toString());
                          builder.element('LongitudeDegrees',
                              nest: pt.longitude.toString());
                        });
                      }
                      if (pt.altitudeMeters != null) {
                        builder.element('AltitudeMeters',
                            nest: pt.altitudeMeters.toString());
                      }
                      if (pt.distanceMeters != null) {
                        builder.element('DistanceMeters',
                            nest: pt.distanceMeters.toString());
                      }
                      if (pt.heartRateBpm != null) {
                        builder.element('HeartRateBpm', nest: () {
                          builder.element('Value',
                              nest: pt.heartRateBpm.toString());
                        });
                      }
                      if (pt.cadence != null) {
                        builder.element('Cadence', nest: pt.cadence.toString());
                      }

                      if (pt.speed != null || pt.watts != null) {
                        builder.element('Extensions', nest: () {
                          builder.element('ns3:TPX', nest: () {
                            if (pt.speed != null)
                              builder.element('ns3:Speed',
                                  nest: pt.speed.toString());
                            if (pt.watts != null)
                              builder.element('ns3:Watts',
                                  nest: pt.watts.toString());
                          });
                        });
                      }
                    });
                  }
                });
              });
            }

            if (activity.creator != null) {
              builder.element('Creator', attributes: {'xsi:type': 'Device_t'},
                  nest: () {
                builder.element('Name', nest: activity.creator);
              });
            }
          });
        }
      });
    });

    return builder.buildDocument().toXmlString(pretty: true);
  }
}
