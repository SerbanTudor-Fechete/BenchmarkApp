import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:benchmark_core_example/Controllers/cpu_benchmark_controller.dart';

class CpuView extends StatelessWidget {
  const CpuView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CpuBenchmarkController(),
      child: const _CpuViewBody(),
    );
  }
}

class _CpuViewBody extends StatelessWidget {
  const _CpuViewBody();
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CpuBenchmarkController>();
    final results = controller.results;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: controller.isRunning
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Running CPU benchmarks...'),
                ],
              )
            : controller.error != null
                ? Text(
                    'Error: ${controller.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  )
                : results == null
                    ? ElevatedButton(
                        onPressed: () => controller.runBenchmarks(),
                        child: const Text('Run CPU Benchmark'),
                      )
                    : _ResultsView(results: results),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  final CPUResults results;

  const _ResultsView({required this.results});

  @override
  Widget build(BuildContext context) {
    final totalDuration = results.fibonacciMs + results.matrixSingleMs + results.matrixMultiMs;
    final totalScore = results.singleCoreScore + results.multiCoreScore;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  'CPU Score',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '$totalScore',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Duration: ${totalDuration.toStringAsFixed(2)} ms',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => context.read<CpuBenchmarkController>().runBenchmarks(),
          icon: const Icon(Icons.refresh),
          label: const Text('Run Again'),
        ),
      ],
    );
  }
}