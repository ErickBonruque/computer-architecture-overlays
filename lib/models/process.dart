import 'dart:math';

enum ProcessStatus {
  waiting,
  running,
  completed
}

class Process {
  final String name;
  final int size;
  double progress;
  bool isCompleted;
  final bool isMain;
  final Process? parentProcess;
  ProcessStatus status;

  Process({
    required this.name, 
    required this.size, 
    this.progress = 0.0,
    this.isCompleted = false,
    this.isMain = true,
    this.parentProcess,
    this.status = ProcessStatus.waiting,
  });

  factory Process.secondary({
    required int index,
    required Process parent,
  }) {
    final random = Random();
    final maxSize = parent.size ~/ 2;
    final size = random.nextInt(maxSize - 30 + 1) + 30; // Random between 30 and maxSize

    return Process(
      name: 'Processo Secundário - $index - ${parent.name}',
      size: size,
      isMain: false,
      parentProcess: parent,
      status: ProcessStatus.waiting,
    );
  }
}
