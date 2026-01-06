import 'package:flutter/material.dart';
import 'package:benchmark_core/benchmark_core.dart'; 

class GPUResults {
  final double averageFps;
  final double durationSeconds;
  final int score;

  GPUResults({
    this.averageFps = 0,
    this.durationSeconds = 0,
    this.score = 0,
  });

  @override
  String toString() {
    return 'FPS: ${averageFps.toStringAsFixed(1)} | Score: $score';
  }
}

class GpuBenchmarkRunner {
  
  Future<GPUResults> runAllTests() async {
    const double testDuration = 30.0;
    
    final result = await runGpuOffscreenBenchmark(durationSeconds: testDuration);

    return GPUResults(
      averageFps: result.averageFps,
      durationSeconds: result.durationSeconds,
      score: (result.averageFps * 100).toInt(),
    );
  }
}

class GpuBenchmarkController with ChangeNotifier {
  GPUResults? _results;
  bool _isRunning = false;
  Object? _error;

  GPUResults? get results => _results;
  bool get isRunning => _isRunning;
  Object? get error => _error;

  Future<void> runBenchmarks() async {
    _isRunning = true;
    _error = null;
    _results = null;
    notifyListeners();

    try {
      final runner = GpuBenchmarkRunner();
      final newResults = await runner.runAllTests();
      _results = newResults;
    } catch (e, st) {
      _error = '$e\n$st';
      debugPrint('GPU Benchmark Error: $e');
    } finally {
      _isRunning = false;
      notifyListeners();
    }
  }
}