library fit_converter;

export 'gpx/gpx.dart';
export 'tcx/tcx.dart';

import 'dart:typed_data';
import 'src/fit_to_gpx.dart';
import 'src/fit_to_tcx.dart';
import 'src/gpx_to_fit.dart';
import 'src/tcx_to_fit.dart';
import 'src/gpx_to_tcx.dart';
import 'src/tcx_to_gpx.dart';
import 'src/fit_merger.dart';

import 'src/fit_to_brief.dart';

class FitConverter {
  Future<String> fit_to_gpx(Uint8List fitBytes) {
    return FitToGpxConverter().convert(fitBytes);
  }

  Future<String> fit_to_tcx(Uint8List fitBytes) {
    return FitToTcxConverter().convert(fitBytes);
  }

  Future<String> fit_to_brief(Uint8List fitBytes) {
    return FitToBriefConverter().convert(fitBytes);
  }

  Future<Uint8List> gpx_to_fit(String gpxString) {
    return GpxToFitConverter().convert(gpxString);
  }

  Future<Uint8List> tcx_to_fit(String tcxString) {
    return TcxToFitConverter().convert(tcxString);
  }

  Future<String> tcx_to_gpx(String tcxString) {
    return TcxToGpxConverter().convert(tcxString);
  }

  Future<String> gpx_to_tcx(String gpxString) {
    return GpxToTcxConverter().convert(gpxString);
  }

  Future<Uint8List> merge_fit(List<Uint8List> fitFiles) async {
    return FitMerger().merge(fitFiles);
  }

  Future<Uint8List> cut_fit(
      Uint8List fitBytes, int startOffsetSeconds, int endOffsetSeconds) async {
    return FitMerger().cut(fitBytes, startOffsetSeconds, endOffsetSeconds);
  }
}
