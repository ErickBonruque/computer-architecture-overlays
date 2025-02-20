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
  static const int maxConcurrentProcesses = 4; // Máximo de processos simultâneos
  int _currentProcessingSize = 0;

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

  // Gera 7-10 processos secundários automaticamente
  void _generateSecondaryProcesses(Process mainProcess) {
    final count = _random.nextInt(3) + 7;
    final maxSlotSize = mainProcess.size ~/ 2;

    for (var i = 0; i < count; i++) {
      final secondaryProcess = Process.secondary(
        index: i,
        parent: mainProcess,
      );
      // Tamanho entre 30KB e metade do processo principal
      
      _secondaryProcesses.add(secondaryProcess);
      
      if (_canStartProcess(secondaryProcess, maxSlotSize)) {
        _startSecondaryProcess(secondaryProcess);
      } else {
        _pendingSecondaryProcesses.add(secondaryProcess);
      }
    }
    notifyListeners();
  }

  // Metodo para verificar se é possível iniciar um processo secundário
  bool _canStartProcess(Process process, int maxSlotSize) {
    return _activeSecondaryProcesses.length < maxConcurrentProcesses && // Máximo 4 processos
           _currentProcessingSize + process.size <= maxSlotSize; // Não exceder tamanho máximo
  }

  // Metodo para iniciar um processo secundário
  void _startSecondaryProcess(Process process) {
    _activeSecondaryProcesses.add(process);
    _currentProcessingSize += process.size;
    process.status = ProcessStatus.running;
    _startProgressTimer(process);
  }

  // Metodo para iniciar o timer de progresso
  void _startProgressTimer(Process process) {
    if (process.isMain) {
      process.status = ProcessStatus.running; // Inicia o processo principal
    }
    
    final progressIncrement = 0.01 + (_random.nextDouble() * 0.02); // Velocidade aleatória
    const updateInterval = Duration(milliseconds: 250);

    _progressTimers[process] = Timer.periodic(updateInterval, (timer) {
      process.progress = (process.progress + progressIncrement).clamp(0.0, 1.0);
      
      if (process.progress >= 1.0) {  // Processo concluído
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
    // Verifica se ainda existem processos secundários pendentes
    final hasUnfinishedProcesses = _pendingSecondaryProcesses
        .any((p) => p.parentProcess == mainProcess) ||
        _secondaryProcesses
        .any((p) => p.parentProcess == mainProcess);

    // Verifica se existem processos secundários concluídos
    final completedSecondaries = _completedProcesses
        .where((p) => !p.isMain && p.parentProcess == mainProcess)
        .toList();

    // Processo principal só conclui quando todos secundários terminam
    return !hasUnfinishedProcesses && 
           completedSecondaries.isNotEmpty && 
           mainProcess.progress >= 1.0;
  }

  // Metodo para completar um processo secundário
  void _completeSecondaryProcess(Process process) {
    _secondaryProcesses.remove(process);
    _completedProcesses.add(process);
    _activeSecondaryProcesses.remove(process);
    _currentProcessingSize -= process.size;
    process.isCompleted = true;
    process.status = ProcessStatus.completed;

    if (process.parentProcess != null) {
      _tryStartPendingProcesses(process.parentProcess!);
    }
    
    if (process.parentProcess != null && 
        process.parentProcess!.progress >= 1.0 && 
        _canCompleteMainProcess(process.parentProcess!)) {
      _completeMainProcess(process.parentProcess!);
    }
    notifyListeners();
  }

  // Metodo para tentar iniciar processos secundários pendentes
  void _tryStartPendingProcesses(Process mainProcess) {
    final maxSlotSize = mainProcess.size ~/ 2;
    
    while (_pendingSecondaryProcesses.isNotEmpty) {
      final nextProcess = _pendingSecondaryProcesses.first;
      if (_canStartProcess(nextProcess, maxSlotSize)) { // Verifica se é possível iniciar
        _pendingSecondaryProcesses.removeFirst();
        _startSecondaryProcess(nextProcess);
      } else {
        break;
      }
    }
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
              _currentProcessingSize -= p.size;
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
        _currentProcessingSize -= process.size;
      }
      _secondaryProcesses.remove(process);
      _activeSecondaryProcesses.remove(process);
      
      if (process.parentProcess != null) {
        _tryStartPendingProcesses(process.parentProcess!);
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
