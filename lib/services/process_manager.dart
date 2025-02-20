import 'dart:math';
import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/process.dart';

class ProcessManager extends ChangeNotifier {
  final List<Process> _mainProcesses = [];
  final List<Process> _secondaryProcesses = [];
  final List<Process> _completedProcesses = [];
  final _random = Random();
  final Map<Process, Timer> _progressTimers = {};
  final Queue<Process> _pendingSecondaryProcesses = Queue<Process>();
  final Set<Process> _activeSecondaryProcesses = {};
  static const int maxConcurrentProcesses = 4;

  List<Process> get mainProcesses => List.unmodifiable(_mainProcesses);
  List<Process> get secondaryProcesses => List.unmodifiable(_secondaryProcesses);
  List<Process> get completedProcesses => List.unmodifiable(_completedProcesses);
  List<Process> get completedMainProcesses => 
      _completedProcesses.where((p) => p.isMain).toList();
  List<Process> get completedSecondaryProcesses => 
      _completedProcesses.where((p) => !p.isMain).toList();

  void addProcess(Process process) {
    if (process.isMain) {
      _mainProcesses.add(process);
      _startProgressTimer(process);
      _generateSecondaryProcesses(process);
    } else {
      _secondaryProcesses.add(process);
      _startProgressTimer(process);
    }
    notifyListeners();
  }

  // Metodo para gerar processos secundários
  void _generateSecondaryProcesses(Process mainProcess) {
    final count = _random.nextInt(3) + 7;
    final maxSlotSize = mainProcess.size ~/ 3;

    for (var i = 0; i < count; i++) {
      final secondaryProcess = Process.secondary(
        index: i,
        parent: mainProcess,
      );
      
      _secondaryProcesses.add(secondaryProcess);
      
      if (_canStartProcess(secondaryProcess, maxSlotSize)) {
        _startSecondaryProcess(secondaryProcess);
      } else {
        _pendingSecondaryProcesses.add(secondaryProcess);
      }
    }
    // Try to start additional processes after initial generation
    _optimizeProcessAllocation(mainProcess);
    notifyListeners();
  }

  void _optimizeProcessAllocation(Process mainProcess) {
    final maxSlotSize = mainProcess.size ~/ 2;
    List<Process> pendingForThisMain = _pendingSecondaryProcesses
        .where((p) => p.parentProcess == mainProcess)
        .toList();
    
    // Sort pending processes by size to optimize slot usage
    pendingForThisMain.sort((a, b) => a.size.compareTo(b.size));
    
    for (var process in pendingForThisMain) {
      if (_canStartProcess(process, maxSlotSize)) {
        _pendingSecondaryProcesses.remove(process);
        _startSecondaryProcess(process);
      }
    }
  }

  // Metodo para verificar se é possível iniciar um processo secundário
  bool _canStartProcess(Process process, int maxSlotSize) {
    if (_activeSecondaryProcesses.length >= maxConcurrentProcesses) {
      return false;
    }

    // Calculate current processing size for this main process
    int currentSizeForMain = _activeSecondaryProcesses
        .where((p) => p.parentProcess == process.parentProcess)
        .fold(0, (sum, p) => sum + p.size);

    return currentSizeForMain + process.size <= maxSlotSize;
  }

  // Metodo para iniciar um processo secundário
  void _startSecondaryProcess(Process process) {
    _activeSecondaryProcesses.add(process);
    process.status = ProcessStatus.running;
    _startProgressTimer(process);
  }

  // Metodo para iniciar o timer de progresso
  void _startProgressTimer(Process process) {
    if (process.isMain) {
      process.status = ProcessStatus.running;
    }
    
    final progressIncrement = 0.01 + (_random.nextDouble() * 0.02);
    const updateInterval = Duration(milliseconds: 250);

    _progressTimers[process] = Timer.periodic(updateInterval, (timer) {
      process.progress = (process.progress + progressIncrement).clamp(0.0, 1.0);
      
      if (process.progress >= 1.0) {
        timer.cancel();
        _progressTimers.remove(process);
        process.status = ProcessStatus.completed;
        
        if (!process.isMain) {
          _completeSecondaryProcess(process);
        } else if (_canCompleteMainProcess(process)) {
          _completeMainProcess(process);
        }
      }
      notifyListeners();
    });
  }

  // Metodo para verificar se é possível completar um processo principal
  bool _canCompleteMainProcess(Process mainProcess) {
    final hasUnfinishedProcesses = _pendingSecondaryProcesses
        .any((p) => p.parentProcess == mainProcess) ||
        _secondaryProcesses
        .any((p) => p.parentProcess == mainProcess);

    final completedSecondaries = _completedProcesses
        .where((p) => !p.isMain && p.parentProcess == mainProcess)
        .toList();

    return !hasUnfinishedProcesses && 
           completedSecondaries.isNotEmpty && 
           mainProcess.progress >= 1.0;
  }

  // Metodo para completar um processo secundário
  void _completeSecondaryProcess(Process process) {
    _secondaryProcesses.remove(process);
    _completedProcesses.add(process);
    _activeSecondaryProcesses.remove(process);
    process.isCompleted = true;
    process.status = ProcessStatus.completed;

    if (process.parentProcess != null) {
      // Try to start new processes after one completes
      _optimizeProcessAllocation(process.parentProcess!);
      
      if (process.parentProcess!.progress >= 1.0 && 
          _canCompleteMainProcess(process.parentProcess!)) {
        _completeMainProcess(process.parentProcess!);
      }
    }
    notifyListeners();
  }

  // Metodo para completar um processo principal
  void _completeMainProcess(Process process) {
    _mainProcesses.remove(process);
    _completedProcesses.add(process);
    process.isCompleted = true;
    notifyListeners();
  }

  // Metodo para remover um processo
  void removeProcess(Process process) {
    _progressTimers[process]?.cancel();
    _progressTimers.remove(process);
    
    if (process.isMain) {
      _secondaryProcesses
          .where((p) => p.parentProcess == process)
          .forEach((p) {
            if (_activeSecondaryProcesses.contains(p)) {
            }
            _progressTimers[p]?.cancel();
            _progressTimers.remove(p);
            _activeSecondaryProcesses.remove(p);
          });
      
      _pendingSecondaryProcesses.removeWhere((p) => p.parentProcess == process);
      _mainProcesses.remove(process);
      _secondaryProcesses.removeWhere((p) => p.parentProcess == process);
    } else {
      if (_activeSecondaryProcesses.contains(process)) {
      }
      _secondaryProcesses.remove(process);
      _activeSecondaryProcesses.remove(process);
      
      if (process.parentProcess != null) {
        _optimizeProcessAllocation(process.parentProcess!);
      }
    }
    notifyListeners();
  }

  // Metodo para atualizar o progresso de um processo
  void updateProgress(Process process, double progress) {
    final index = _mainProcesses.indexOf(process);
    if (index != -1) {
      _mainProcesses[index].progress = progress.clamp(0.0, 1.0);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (var timer in _progressTimers.values) {
      timer.cancel();
    }
    _progressTimers.clear();
    super.dispose();
  }

  void completeProcess(Process process) {
    _mainProcesses.remove(process);
    _completedProcesses.add(process);
    notifyListeners();
  }

  void clearCompletedProcesses() {
    _completedProcesses.clear();
    notifyListeners();
  }
}
