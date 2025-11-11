import 'package:flutter/material.dart';
import 'package:benchmark_core/benchmark_core.dart';

class CPUResults {
  final double fibonacciMs;
  final double matrixSingleMs;
  final double matrixMultiMs;

  final int singleCoreScore;
  final int multiCoreScore;

  CPUResults({
    this.fibonacciMs = 0,
    this.matrixSingleMs = 0,
    this.matrixMultiMs = 0,
    this.singleCoreScore = 0,
    this.multiCoreScore = 0,
  });
}

class BenchmarkRunner {
  static const double _baselineFibScore = 120.0;
  static const double _baselineMatrixSingleScore = 2.5; // GFLOPs
  static const double _baselineMatrixMultiScore = 20.0; // GFLOPs

  static const double _fibWeight = 0.35;
  static const double _matrixWeight = 0.65;

  static const int _scalingFactor = 10000;

  Future<CPUResults> runAllTests() async {
    final fibResult = await runFibonacciBenchmark(40);
    final matrixMultiResult = await runMatrixBenchmarkMultiThreaded(2000);
    final matrixSingleResult = await runMatrixBenchmarkSingleThreaded(2000);

    double normFib = fibResult.score / _baselineFibScore;
    double normMatrix = matrixSingleResult.score / _baselineMatrixSingleScore;
    double normMulti = matrixMultiResult.score / _baselineMatrixMultiScore;

    int singleCoreScore = ((normFib * _fibWeight) + (normMatrix * _matrixWeight) * _scalingFactor).round();
    int multiCoreScore = (normMulti * _scalingFactor).round();

    return CPUResults(
      fibonacciMs: fibResult.elapsedMs,
      matrixSingleMs: matrixSingleResult.elapsedMs,
      matrixMultiMs: matrixMultiResult.elapsedMs,
      singleCoreScore: (matrixSingleResult.score * 1000).toInt(),
      multiCoreScore: (matrixMultiResult.score * 1000).toInt(),
    );
  }
}

class CpuBenchmarkController with ChangeNotifier {
  CPUResults? _results;
  bool _isRunning = false;
  Object? _error;

  CPUResults? get results => _results;
  bool get isRunning => _isRunning;
  Object? get error => _error;

  Future<void> runBenchmarks() async {
    _isRunning = true;
    _error = null;
    _results = null;
    notifyListeners();

    try {
      final runner = BenchmarkRunner();
      final newResults = await runner.runAllTests();
      _results = newResults;
    } catch (e, st) {
      _error = '$e\n$st';
    } finally {
      _isRunning = false;
      notifyListeners();
    }
  }
}
