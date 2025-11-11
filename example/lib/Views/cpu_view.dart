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
                  Text('Running benchmarks...'),
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
                child: const Text('Run Benchmark'),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fibonacci: ${results.fibonacciMs.toStringAsFixed(2)} ms'),
        Text('Matrix (Single-threaded): ${results.matrixSingleMs.toStringAsFixed(2)} ms'),
        Text('Matrix (Multi-threaded): ${results.matrixMultiMs.toStringAsFixed(2)} ms'),
        const SizedBox(height: 16),
        Text('Single-Core Score: ${results.singleCoreScore}'),
        Text('Multi-Core Score: ${results.multiCoreScore}'),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => context.read<CpuBenchmarkController>().runBenchmarks(),
          child: const Text('Run Again'),
        ),
      ],
    );
  }
}