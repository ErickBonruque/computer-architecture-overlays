import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/process.dart';
import '../services/process_manager.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();

  Widget _buildProcessCard(Process process) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(process.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${process.size} KBs'),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: process.progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    process.progress >= 1.0 ? Colors.green : Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${(process.progress * 100).toStringAsFixed(1)}%'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                context.read<ProcessManager>().removeProcess(process);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Novo Processo'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    hintText: 'Digite o nome do processo',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sizeController,
                  decoration: const InputDecoration(
                    labelText: 'Tamanho em KBs',
                    hintText: 'Digite o tamanho',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty && _sizeController.text.isNotEmpty) {
                  final process = Process(
                    name: _nameController.text,
                    size: int.tryParse(_sizeController.text) ?? 0,
                  );
                  context.read<ProcessManager>().addProcess(process);
                  _nameController.clear();
                  _sizeController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    super.dispose();
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
                        'Processos Principais',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Consumer<ProcessManager>(
                        builder: (context, manager, child) {
                          return ListView.builder(
                            itemCount: manager.mainProcesses.length,
                            itemBuilder: (context, index) {
                              return _buildProcessCard(manager.mainProcesses[index]);
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
                        'Processos Secundários',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Consumer<ProcessManager>(
                        builder: (context, manager, child) {
                          return ListView.builder(
                            itemCount: manager.secondaryProcesses.length,
                            itemBuilder: (context, index) {
                              return _buildProcessCard(manager.secondaryProcesses[index]);
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showInputDialog,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
