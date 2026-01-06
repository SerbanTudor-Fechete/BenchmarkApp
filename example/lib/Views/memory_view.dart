import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:benchmark_core_example/Controllers/memory_controller.dart';

class MemoryView extends StatelessWidget {
  const MemoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MemoryBenchmarkController(),
      child: const _MemoryViewBody(),
    );
  }
}

class _MemoryViewBody extends StatelessWidget {
  const _MemoryViewBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MemoryBenchmarkController>();
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
                  Text('Running memory benchmarks...'),
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
                        child: const Text('Run Memory Benchmark'),
                      )
                    : _ResultsView(results: results),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  final MemoryResults results;

  const _ResultsView({required this.results});

  @override
  Widget build(BuildContext context) {
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
                  'Memory Score',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '${results.memoryScore}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Duration: ${results.bandwidthElapsedMs.toStringAsFixed(2)} ms',
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
          onPressed: () => context.read<MemoryBenchmarkController>().runBenchmarks(),
          icon: const Icon(Icons.refresh),
          label: const Text('Run Again'),
        ),
      ],
    );
  }
}