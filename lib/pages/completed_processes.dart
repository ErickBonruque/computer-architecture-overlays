import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/process_manager.dart';
import '../models/process.dart';

class CompletedProcessesPage extends StatelessWidget {
  const CompletedProcessesPage({Key? key}) : super(key: key);

  Widget _buildCompletedCard(Process process) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(process.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${process.size} KBs'),
            const Text('100%'),
          ],
        ),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Processos Principais Concluídos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Consumer<ProcessManager>(
                        builder: (context, manager, child) {
                          final completedMain = manager.completedMainProcesses;
                          return ListView.builder(
                            itemCount: completedMain.length,
                            itemBuilder: (context, index) {
                              return _buildCompletedCard(completedMain[index]);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Processos Secundários Concluídos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Consumer<ProcessManager>(
                        builder: (context, manager, child) {
                          final completedSecondary = manager.completedSecondaryProcesses;
                          return ListView.builder(
                            itemCount: completedSecondary.length,
                            itemBuilder: (context, index) {
                              return _buildCompletedCard(completedSecondary[index]);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
