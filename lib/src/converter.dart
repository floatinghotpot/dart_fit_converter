import 'dart:typed_data';

import 'fit_merger.dart';
import 'fit_to_brief.dart';
import 'fit_to_gpx.dart';
import 'fit_to_tcx.dart';
import 'gpx_to_fit.dart';
import 'gpx_to_tcx.dart';
import 'tcx_to_gpx.dart';
import 'tcx_to_fit.dart';

class FitConverter {
  Future<String> fitToGpx(Uint8List fitBytes) {
    return FitToGpxConverter().convert(fitBytes);
  }

  Future<String> fitToTcx(Uint8List fitBytes) {
    return FitToTcxConverter().convert(fitBytes);
  }

  Future<String> fitToBrief(Uint8List fitBytes) {
    return FitToBriefConverter().convert(fitBytes);
  }

  Future<Uint8List> gpxToFit(String gpxString) {
    return GpxToFitConverter().convert(gpxString);
  }

  Future<Uint8List> tcxToFit(String tcxString) {
    return TcxToFitConverter().convert(tcxString);
  }

  Future<String> tcxToGpx(String tcxString) {
    return TcxToGpxConverter().convert(tcxString);
  }

  Future<String> gpxToTcx(String gpxString) {
    return GpxToTcxConverter().convert(gpxString);
  }

  Future<Uint8List> mergeFit(List<Uint8List> fitFiles) async {
    return FitMerger().merge(fitFiles);
  }

  Future<Uint8List> cutFit(
    Uint8List fitBytes,
    int startOffsetSeconds,
    int endOffsetSeconds,
  ) async {
    return FitMerger().cut(fitBytes, startOffsetSeconds, endOffsetSeconds);
  }
}
