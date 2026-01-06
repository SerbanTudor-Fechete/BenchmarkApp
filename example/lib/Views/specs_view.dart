import 'package:flutter/material.dart';
import 'package:benchmark_core_example/Controllers/specs_controller.dart';

class SpecsView extends StatefulWidget {
  const SpecsView({super.key});

  @override
  State<SpecsView> createState() => _SpecsViewState();
}

class _SpecsViewState extends State<SpecsView> {
  late Future<DartSystemSpecs> _specsFuture;

  @override
  void initState() {
    super.initState();
    final runner = SystemSpecsController();
    _specsFuture = runner.loadSpecs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DartSystemSpecs>(
        future: _specsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final specs = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SpecTile(
                  icon: Icons.business,
                  label: "Manufacturer",
                  value: specs.manufacturer,
                ),
                _SpecTile(
                  icon: Icons.phone_android,
                  label: "Model",
                  value: specs.model,
                ),
                _SpecTile(
                  icon: Icons.memory,
                  label: "Chipset",
                  value: specs.chipsetModel,
                ),
                _SpecTile(
                  icon: Icons.android,
                  label: "Android Version",
                  value: specs.androidVersion,
                ),
                _SpecTile(
                  icon: Icons.sd_storage,
                  label: "Total RAM",
                  value: "${(specs.totalRam / (1024 * 1024)).toStringAsFixed(2)} MB",
                ),
                _SpecTile(
                  icon: Icons.grid_view,
                  label: "CPU Cores",
                  value: "${specs.cpuCores}",
                ),
              ],
            );
          }
          return const Center(child: Text("No data found"));
        },
      ),
    );
  }
}

class _SpecTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SpecTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}