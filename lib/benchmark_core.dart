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

const String _libName = 'benchmark_core';

/// Load the native dynamic library.
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

/// Bindings to the native functions in the shared library.
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

/// Runs a single-threaded matrix benchmark.
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

/// Runs a multithreaded matrix benchmark.
Future<CpuBenchmarkResult> runMatrixBenchmarkMultiThreaded(
    int size) async {
  return await Isolate.run(() {
    final RawBenchmarkResult ffiResult =
        _bindings.run_matrix_test_multithreaded(size);
    return CpuBenchmarkResult(
      elapsedMs: ffiResult.elapsed_ms,
      score: ffiResult.score,
    );
  });
}
