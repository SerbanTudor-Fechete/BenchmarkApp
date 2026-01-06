import 'package:benchmark_core/benchmark_core.dart';

class DartSystemSpecs {
  final String manufacturer;
  final String model;
  final String chipsetModel;
  final String androidVersion;
  final int totalRam;
  final int cpuCores;

  DartSystemSpecs({
    this.manufacturer = "",
    this.model = "",
    this.chipsetModel = "",
    this.androidVersion = "",
    this.totalRam = 0,
    this.cpuCores = 0,
  });
}

class SystemSpecsController {
  Future<DartSystemSpecs> loadSpecs() async {
      final dartSystemSpecs = await getSystemSpecs();

      return DartSystemSpecs(
        manufacturer: dartSystemSpecs.manufacturer,
        model: dartSystemSpecs.model,
        chipsetModel: dartSystemSpecs.chipsetModel,
        androidVersion: dartSystemSpecs.androidVersion,
        totalRam: dartSystemSpecs.totalRam,
        cpuCores: dartSystemSpecs.cpuCores
      );
  }

}

