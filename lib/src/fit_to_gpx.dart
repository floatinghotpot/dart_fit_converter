import 'dart:typed_data';
import 'package:fit_sdk/fit_sdk.dart';
import '../gpx/gpx_models.dart';
import '../gpx/gpx_writer.dart';
import 'format_converter.dart';

class FitToGpxConverter extends SportsDataConverter<Uint8List, String> {
  @override
  Future<String> convert(Uint8List fitBytes) async {
    final listener = FitListener();
    final decoder = Decode();

    // 连接解码器和监听器
    decoder.onMesg = (Mesg mesg) {
      listener.onMesg(this, MesgEventArgs(mesg));
    };

    // 执行解码
    decoder.read(fitBytes);

    final fitMessages = listener.fitMessages;
    final gpx = Gpx(creator: 'FitConverter');

    // 设置元数据 (Metadata)
    if (fitMessages.sessionMesgs.isNotEmpty) {
      final session = fitMessages.sessionMesgs.first;
      gpx.metadata = GpxMetadata(
        time: session.getStartTime() ?? session.getTimestamp(),
        name: _getSportName(session.getSport()),
      );
    }

    // 创建轨迹 (Track)
    final track = GpxTrack(
      name: gpx.metadata?.name ?? 'Activity',
      type: gpx.metadata?.name,
    );

    final segment = GpxTrackSegment();

    for (final record in fitMessages.recordMesgs) {
      final lat = record.getPositionLat();
      final lon = record.getPositionLong();

      // 只有带 GPS 坐标的点才加入 GPX
      if (lat != null && lon != null) {
        segment.points.add(
          GpxTrackPoint(
            latitude: _semicirclesToDegrees(lat),
            longitude: _semicirclesToDegrees(lon),
            elevation: record.getEnhancedAltitude() ?? record.getAltitude(),
            time: record.getTimestamp(),
            heartRate: record.getHeartRate(),
            cadence: record.getCadence(),
            temperature: record.getTemperature()?.toDouble(),
            speed: record.getEnhancedSpeed() ?? record.getSpeed(),
          ),
        );
      }
    }

    if (segment.points.isNotEmpty) {
      track.segments.add(segment);
      gpx.tracks.add(track);
    }

    // 使用 GpxWriter 生成 XML 字符串
    return GpxWriter().write(gpx);
  }

  /// 将 FIT 半圆单位转换为经纬度度数
  double _semicirclesToDegrees(int semicircles) {
    return semicircles * (180.0 / 2147483648.0);
  }

  /// 获取运动类型的显示名称
  String? _getSportName(int? sportValue) {
    if (sportValue == null) return null;
    // 由于 Sport 在 fit_sdk 中是带有静态常量的类而非 enum，
    // 这里简单返回其数值字符串，或者后续可以增加映射表。
    switch (sportValue) {
      case Sport.running:
        return 'Running';
      case Sport.cycling:
        return 'Cycling';
      case Sport.swimming:
        return 'Swimming';
      case Sport.walking:
        return 'Walking';
      case Sport.hiking:
        return 'Hiking';
      default:
        return 'Sport($sportValue)';
    }
  }
}
