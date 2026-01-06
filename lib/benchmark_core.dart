import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'benchmark_core_bindings_generated.dart';

class CpuBenchmarkResult {
  final double elapsedMs;
  final double score;

  CpuBenchmarkResult({
    required this.elapsedMs,
    required this.score,
  });

  @override
  String toString() =>
      'CpuBenchmarkResult(elapsedMs: $elapsedMs, score: $score)';
}

class DartSystemSpecs {
  final String manufacturer;
  final String model;
  final String chipsetModel;
  final String androidVersion;
  final int totalRam;
  final int cpuCores;

  DartSystemSpecs({
    required this.manufacturer,
    required this.model,
    required this.chipsetModel,
    required this.androidVersion,
    required this.totalRam,
    required this.cpuCores,
  });

  @override
  String toString() => '''
  System Specs:
  Manufacturer: $manufacturer
  Model: $model
  Chipset: $chipsetModel
  Android Version: $androidVersion
  Total RAM: $totalRam bytes
  CPU Cores: $cpuCores
  ''';
}

class GpuRenderResult {
  final double averageFps;
  final double durationSeconds;

  GpuRenderResult({
    required this.averageFps,
    required this.durationSeconds,
  });

  @override
  String toString() =>
      'GpuRenderResult(Average FPS: ${averageFps.toStringAsFixed(2)}, '
      'Duration: ${durationSeconds.toStringAsFixed(1)}s)';
}

class MemoryBandwidthResult {
  final double elapsedMs;
  final double bandwidthMb;

  MemoryBandwidthResult({
    required this.elapsedMs,
    required this.bandwidthMb,
  });

  @override
  String toString() =>
      'MemoryBandwidthResult(elapsedMs: $elapsedMs, bandwidthMb: $bandwidthMb MB/s)';
}

class MemoryLatencyResultDart {
  final double avgNs;
  final int steps;

  MemoryLatencyResultDart({
    required this.avgNs,
    required this.steps,
  });

  @override
  String toString() =>
      'MemoryLatencyResult(avgNs: $avgNs ns, steps: $steps)';
}

const String _libName = 'benchmark_core';

final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}();

final BenchmarkCoreBindings _bindings = BenchmarkCoreBindings(_dylib);

Future<CpuBenchmarkResult> runFibonacciBenchmark(int n) async {
  return await Isolate.run(() {
    final RawBenchmarkResult ffiResult = _bindings.run_fibonacci_test(n);
    return CpuBenchmarkResult(
      elapsedMs: ffiResult.elapsed_ms,
      score: ffiResult.score,
    );
  });
}

Future<CpuBenchmarkResult> runMatrixBenchmarkSingleThreaded(int size) async {
  return await Isolate.run(() {
    final RawBenchmarkResult ffiResult =
        _bindings.run_matrix_test_singlethreaded(size);
    return CpuBenchmarkResult(
      elapsedMs: ffiResult.elapsed_ms,
      score: ffiResult.score,
    );
  });
}

Future<CpuBenchmarkResult> runMatrixBenchmarkMultiThreaded(int size) async {
  return await Isolate.run(() {
    final RawBenchmarkResult ffiResult =
        _bindings.run_matrix_test_multithreaded(size);
    return CpuBenchmarkResult(
      elapsedMs: ffiResult.elapsed_ms,
      score: ffiResult.score,
    );
  });
}

String charArrayToString(Array<Char> array, int maxLength) {
  final bytes = <int>[];

  for (var i = 0; i < maxLength; i++) {
    final char = array[i];
    if (char == 0) break; 
    bytes.add(char);
  }

  return String.fromCharCodes(bytes);
}

Future<DartSystemSpecs> getSystemSpecs() async {
  return await Isolate.run(() {
    final SystemSpecs ffiResult = _bindings.display_system_specs();

    return DartSystemSpecs(
      manufacturer: charArrayToString(ffiResult.manufacturer, 128),
      model: charArrayToString(ffiResult.model, 128),
      chipsetModel: charArrayToString(ffiResult.chipset_model, 64),
      androidVersion: charArrayToString(ffiResult.android_version, 64),
      totalRam: ffiResult.total_ram,
      cpuCores: ffiResult.cpu_cores,
    );
  });
}


Future<MemoryBandwidthResult> runMemoryBandwidthTest(int mb) async {
  return await Isolate.run(() {
    final raw = _bindings.run_memory_bandwidth_test(mb);

    return MemoryBandwidthResult(
      elapsedMs: raw.elapsed_ms,
      bandwidthMb: raw.bandwidth_mb,
    );
  });
}

Future<MemoryLatencyResultDart> runMemoryLatencyTest(int steps) async {
  return await Isolate.run(() {
    final raw = _bindings.run_memory_latency_test(steps);

    return MemoryLatencyResultDart(
      avgNs: raw.avg_ns,
      steps: raw.steps,
    );
  });
}

Future<GpuRenderResult> runGpuOffscreenBenchmark({
  double durationSeconds = 3.0,
}) async {
  return await Isolate.run(() {
    final double fps = _bindings.run_offscreen_render_benchmark(durationSeconds);

    return GpuRenderResult(
      averageFps: fps,
      durationSeconds: durationSeconds,
    );
  });
}