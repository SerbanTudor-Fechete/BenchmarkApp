import 'package:flutter/material.dart';
import 'package:benchmark_core/benchmark_core.dart';

class MemoryResults {
  final double bandwidthMbPerSec;
  final double bandwidthElapsedMs;
  final double latencyAvgNs;
  final int latencySteps;
  final int memoryScore;

  MemoryResults({
    this.bandwidthMbPerSec = 0,
    this.bandwidthElapsedMs = 0,
    this.latencyAvgNs = 0,
    this.latencySteps = 0,
    this.memoryScore = 0,
  });
}

class MemoryRunner {
  Future<MemoryResults> runAllTests({
    int bandwidthSizeMb = 512, 
    int latencySteps = 3000000, 
  }) async {
    
    double totalBandwidth = 0;
    double totalBwTime = 0;
    const int iterations = 5; 

    for (int i = 0; i < iterations; i++) {
      final bw = await runMemoryBandwidthTest(bandwidthSizeMb);
      totalBandwidth += bw.bandwidthMb;
      totalBwTime += bw.elapsedMs;
    }
    final double avgBandwidth = totalBandwidth / iterations;
    final lat = await runMemoryLatencyTest(latencySteps);
    
    final double latDurationMs = (latencySteps * lat.avgNs) / 1000000;
    final int score = (avgBandwidth - (lat.avgNs * 100)).toInt().clamp(0, 100000);

    return MemoryResults(
      bandwidthMbPerSec: avgBandwidth,
      bandwidthElapsedMs: totalBwTime + latDurationMs, 
      latencyAvgNs: lat.avgNs,
      latencySteps: latencySteps,
      memoryScore: score,
    );
  }
}

class MemoryBenchmarkController with ChangeNotifier {
  MemoryResults? _results;
  bool _isRunning = false;
  Object? _error;

  MemoryResults? get results => _results;
  bool get isRunning => _isRunning;
  Object? get error => _error;

  Future<void> runBenchmarks() async {
    _isRunning = true;
    _error = null;
    _results = null;
    notifyListeners();

    try {
      final runner = MemoryRunner();
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