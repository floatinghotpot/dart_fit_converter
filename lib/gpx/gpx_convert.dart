
import 'dart:math';

class GpxConvert {
  static const double earthR = 6378137.0;
  static const double xPi = pi * 3000.0 / 180.0;
  static const double ee = 0.006693421622965943;

  static bool isOutOfChina(double lat, double lng) {
    return !(lng >= 72.004 && lng <= 137.8347 && lat >= 0.8293 && lat <= 55.8271);
  }

  static List<double> _transform(double x, double y) {
    double xy = x * y;
    double absX = sqrt(x.abs());
    double xPiValue = x * pi;
    double yPiValue = y * pi;
    double d = 20.0 * sin(6.0 * xPiValue) + 20.0 * sin(2.0 * xPiValue);

    double lat = d;
    double lng = d;

    lat += 20.0 * sin(yPiValue) + 40.0 * sin(yPiValue / 3.0);
    lng += 20.0 * sin(xPiValue) + 40.0 * sin(xPiValue / 3.0);

    lat += 160.0 * sin(yPiValue / 12.0) + 320.0 * sin(yPiValue / 30.0);
    lng += 150.0 * sin(xPiValue / 12.0) + 300.0 * sin(xPiValue / 30.0);

    lat *= 2.0 / 3.0;
    lng *= 2.0 / 3.0;

    lat += -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * xy + 0.2 * absX;
    lng += 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * xy + 0.1 * absX;

    return [lat, lng];
  }

  static List<double> _delta(double lat, double lng) {
    final t = _transform(lng - 105.0, lat - 35.0);
    double dLat = t[0];
    double dLng = t[1];
    double radLat = lat / 180.0 * pi;
    double sinRadLat = sin(radLat);

    double magic = 1 - ee * sinRadLat * sinRadLat;
    double sqrtMagic = sqrt(magic);

    dLat = (dLat * 180.0) / ((earthR * (1 - ee)) / (magic * sqrtMagic) * pi);
    dLng = (dLng * 180.0) / (earthR / sqrtMagic * cos(radLat) * pi);

    return [dLat, dLng];
  }

  static List<double> wgs2Gcj(double wgsLat, double wgsLng) {
    if (isOutOfChina(wgsLat, wgsLng)) {
      return [wgsLat, wgsLng];
    } else {
      final d = _delta(wgsLat, wgsLng);
      return [wgsLat + d[0], wgsLng + d[1]];
    }
  }

  static List<double> gcj2Wgs(double gcjLat, double gcjLng) {
    if (isOutOfChina(gcjLat, gcjLng)) {
      return [gcjLat, gcjLng];
    } else {
      final d = _delta(gcjLat, gcjLng);
      return [gcjLat - d[0], gcjLng - d[1]];
    }
  }

  static List<double> gcj2Bd(double gcjLat, double gcjLng) {
    if (isOutOfChina(gcjLat, gcjLng)) {
      return [gcjLat, gcjLng];
    }
    double x = gcjLng;
    double y = gcjLat;
    double z = sqrt(x * x + y * y) + 0.00002 * sin(y * xPi);
    double theta = atan2(y, x) + 0.000003 * cos(x * xPi);
    double bdLng = z * cos(theta) + 0.0065;
    double bdLat = z * sin(theta) + 0.006;
    return [bdLat, bdLng];
  }

  static List<double> bd2Gcj(double bdLat, double bdLng) {
    if (isOutOfChina(bdLat, bdLng)) {
      return [bdLat, bdLng];
    }
    double x = bdLng - 0.0065;
    double y = bdLat - 0.006;
    double z = sqrt(x * x + y * y) - 0.00002 * sin(y * xPi);
    double theta = atan2(y, x) - 0.000003 * cos(x * xPi);
    double gcjLng = z * cos(theta);
    double gcjLat = z * sin(theta);
    return [gcjLat, gcjLng];
  }

  static double distance(double latA, double lngA, double latB, double lngB) {
    const double pi180 = pi / 180.0;
    double arcLatA = latA * pi180;
    double arcLatB = latB * pi180;
    double x = cos(arcLatA) * cos(arcLatB) * cos((lngA - lngB) * pi180);
    double y = sin(arcLatA) * sin(arcLatB);
    double s = x + y;
    if (s > 1.0) s = 1.0;
    if (s < -1.0) s = -1.0;
    double alpha = acos(s);
    return alpha * earthR;
  }
}
