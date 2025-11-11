import 'package:flutter/material.dart';
import 'package:benchmark_core_example/Views/cpu_view.dart';
import 'package:benchmark_core_example/Views/gpu_view.dart';
import 'package:benchmark_core_example/Views/memory_view.dart';
import 'package:benchmark_core_example/Views/specs_view.dart';
import 'package:benchmark_core_example/Views/home_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 2;

  final List<Widget> _widgetOptions = const [
    CpuView(),
    GpuView(),
    HomeView(),
    MemoryView(),
    SpecsView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _widgetOptions[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.memory),
            label: 'CPU',
            backgroundColor: Colors.indigo,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.developer_board),
            label: 'GPU', 
            backgroundColor: Colors.indigo,
          ),
           BottomNavigationBarItem(
            icon: Icon(Icons.house),
            label: 'Home',
            backgroundColor: Colors.indigo,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_tree),
            label: 'Memory',
            backgroundColor: Colors.indigo,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'Specs',
            backgroundColor: Colors.indigo,
          ),

        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }
}
