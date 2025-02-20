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
      floatingActionButton: Consumer<ProcessManager>(
        builder: (context, manager, child) {
          if (manager.completedProcesses.isEmpty) return const SizedBox.shrink();
          
          return FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Limpar Histórico'),
                    content: const Text(
                      'Deseja limpar todo o histórico de processos concluídos?'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<ProcessManager>().clearCompletedProcesses();
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Limpar'),
                      ),
                    ],
                  );
                },
              );
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.delete_forever),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
