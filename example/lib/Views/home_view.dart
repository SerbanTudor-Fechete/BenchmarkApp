import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:benchmark_core_example/Controllers/cpu_benchmark_controller.dart';
import 'package:benchmark_core_example/Controllers/gpu_controller.dart';
import 'package:benchmark_core_example/Controllers/memory_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CpuBenchmarkController()),
        ChangeNotifierProvider(create: (_) => GpuBenchmarkController()),
        ChangeNotifierProvider(create: (_) => MemoryBenchmarkController()),
      ],
      child: const _HomeViewBody(),
    );
  }
}

class _HomeViewBody extends StatefulWidget {
  const _HomeViewBody();

  @override
  State<_HomeViewBody> createState() => _HomeViewBodyState();
}

class _HomeViewBodyState extends State<_HomeViewBody> {
  final List<FlSpot> _cpuSpots = [];
  final List<FlSpot> _gpuSpots = [];
  final List<FlSpot> _memorySpots = [];

  double _runCounter = 0;
  bool _isSequenceRunning = false;

  Future<void> _runAllBenchmarks() async {
    if (_isSequenceRunning) return;

    setState(() {
      _isSequenceRunning = true;
      _runCounter++; 
    });

    final cpu = context.read<CpuBenchmarkController>();
    final gpu = context.read<GpuBenchmarkController>();
    final mem = context.read<MemoryBenchmarkController>();

    try {
      await cpu.runBenchmarks();
      if (!mounted) return;

      final cpuResults = cpu.results;
      if (cpuResults != null) {
        final score = cpuResults.singleCoreScore + cpuResults.multiCoreScore;
        setState(() {
          _cpuSpots.add(FlSpot(_runCounter, score.toDouble()));
        });
      }

      await gpu.runBenchmarks();
      if (!mounted) return;

      final gpuResults = gpu.results;
      if (gpuResults != null) {
        setState(() {
          _gpuSpots.add(FlSpot(_runCounter, gpuResults.averageFps));
        });
      }

      await mem.runBenchmarks();
      if (!mounted) return;

      final memResults = mem.results;
      if (memResults != null) {
        setState(() {
          _memorySpots.add(FlSpot(_runCounter, memResults.memoryScore.toDouble()));
        });
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSequenceRunning = false);
      }
    }
  }

  void _clearData() {
    setState(() {
      _cpuSpots.clear();
      _gpuSpots.clear();
      _memorySpots.clear();
      _runCounter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cpuRunning = context.select<CpuBenchmarkController, bool>((c) => c.isRunning);
    final gpuRunning = context.select<GpuBenchmarkController, bool>((c) => c.isRunning);
    final memRunning = context.select<MemoryBenchmarkController, bool>((c) => c.isRunning);

    final cpuResults = context.select<CpuBenchmarkController, dynamic>((c) => c.results);
    final gpuResults = context.select<GpuBenchmarkController, dynamic>((c) => c.results);
    final memResults = context.select<MemoryBenchmarkController, dynamic>((c) => c.results);

    final isAnyRunning = cpuRunning || gpuRunning || memRunning;

    String getCpuScore() {
      if (cpuResults == null) return '-';
      return (cpuResults.singleCoreScore + cpuResults.multiCoreScore).toString();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'System Analytics',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
            tooltip: 'Reset Graphs',
            onPressed: isAnyRunning ? null : _clearData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isAnyRunning ? null : _runAllBenchmarks,
        backgroundColor: Colors.black87,
        icon: isAnyRunning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.play_arrow_rounded, color: Colors.white),
        label: Text(
          isAnyRunning ? 'Benchmarking...' : 'Run All Tests',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          children: [
            _EfficiencyChartCard(
              title: 'CPU Performance',
              subtitle: 'Pts History',
              icon: Icons.developer_board,
              color: Colors.blueAccent,
              dataPoints: _cpuSpots,
              currentValue: getCpuScore(),
              unit: 'Pts',
              yAxisLabel: 'Pts',
            ),
            const SizedBox(height: 16),
            _EfficiencyChartCard(
              title: 'GPU Graphics',
              subtitle: 'FPS History',
              icon: Icons.gamepad_outlined,
              color: Colors.purpleAccent,
              dataPoints: _gpuSpots,
              currentValue: gpuResults?.averageFps.toStringAsFixed(1) ?? '-',
              unit: 'FPS',
              yAxisLabel: 'FPS',
            ),
            const SizedBox(height: 16),
            _EfficiencyChartCard(
              title: 'Memory Speed',
              subtitle: 'Score History',
              icon: Icons.storage_rounded,
              color: Colors.orangeAccent,
              dataPoints: _memorySpots,
              currentValue: memResults?.memoryScore.toStringAsFixed(0) ?? '-',
              unit: 'Score',
              yAxisLabel: 'Score',
            ),
          ],
        ),
      ),
    );
  }
}

class _EfficiencyChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<FlSpot> dataPoints;
  final String currentValue;
  final String unit;
  final String yAxisLabel;

  const _EfficiencyChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.dataPoints,
    required this.currentValue,
    required this.unit,
    required this.yAxisLabel,
  });

  Color _tint(Color base, double opacity) {
    return Color.alphaBlend(
      base.withAlpha((opacity * 255).toInt()),
      Colors.transparent,
    );
  }

  double _getNiceMaxY() {
    if (dataPoints.isEmpty) return 100;
    
    final maxVal = dataPoints.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return 10;

    double target = maxVal * 1.2;
    
    double magnitude = 1;
    while (target > 10) {
      target /= 10;
      magnitude *= 10;
    }
    if (target <= 1) {target = 1;}
    else if (target <= 2) {target = 2;}
    else if (target <= 5) {target = 5;}
    else {target = 10;}
    
    return target * magnitude;
  }

  double _calculateInterval(double max, {required bool isX}) {
    if (isX) return 1; 
    
    if (max == 0) return 1;
    return max / 5;
  }

  @override
  Widget build(BuildContext context) {
    final double maxY = _getNiceMaxY();
    final double intervalY = _calculateInterval(maxY, isX: false);

    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _tint(color, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currentValue,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: dataPoints.isEmpty
                ? Center(
                    child: Text(
                      'Run benchmark to see data',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY,
                      
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false, 
                        horizontalInterval: intervalY,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: Colors.grey[100], strokeWidth: 1),
                      ),
                      
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: intervalY,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const Text(""); 
                              if (value == maxY) return const Text("");
                              return Text(
                                value >= 1000 
                                  ? "${(value/1000).toStringAsFixed(1)}k" 
                                  : value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold
                                ),
                              );
                            },
                          ),
                        ),
                        
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1, 
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              if (value % 1 != 0) return const SizedBox.shrink();
                              
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      borderData: FlBorderData(show: false),
                      
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => Colors.black87,
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((LineBarSpot touchedSpot) {
                              return LineTooltipItem(
                                "Run ${touchedSpot.x.toInt()}\n$yAxisLabel: ${touchedSpot.y.toStringAsFixed(1)}",
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      
                      lineBarsData: [
                        LineChartBarData(
                          spots: dataPoints,
                          isCurved: true,
                          curveSmoothness: 0.2,
                          color: color,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: color,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _tint(color, 0.15),
                                _tint(color, 0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}