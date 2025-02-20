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

  void _generateSecondaryProcesses(Process mainProcess) {
    final count = _random.nextInt(3) + 7; // 7-9 secondary processes
    final maxSlotSize = mainProcess.size ~/ 2;

    for (var i = 0; i < count; i++) {
      final secondaryProcess = Process.secondary(
        index: i,
        parent: mainProcess,
      );
      
      _secondaryProcesses.add(secondaryProcess); // Add to visible list immediately
      
      if (_canStartProcess(secondaryProcess, maxSlotSize)) {
        _startSecondaryProcess(secondaryProcess);
      } else {
        _pendingSecondaryProcesses.add(secondaryProcess);
      }
    }
    notifyListeners();
  }

  bool _canStartProcess(Process process, int maxSlotSize) {
    return _activeSecondaryProcesses.length < maxConcurrentProcesses &&
           _currentProcessingSize + process.size <= maxSlotSize;
  }

  void _startSecondaryProcess(Process process) {
    _activeSecondaryProcesses.add(process);
    _currentProcessingSize += process.size;
    process.status = ProcessStatus.running; // Update status when starting
    _startProgressTimer(process);
  }

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
        process.status = ProcessStatus.completed; // Update status when completed
        
        if (!process.isMain) {
          _completeSecondaryProcess(process);
        } else if (_canCompleteMainProcess(process)) {
          _completeMainProcess(process);
        }
      }
      notifyListeners();
    });
  }

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

  void _completeSecondaryProcess(Process process) {
    _secondaryProcesses.remove(process);
    _completedProcesses.add(process);
    _activeSecondaryProcesses.remove(process);
    _currentProcessingSize -= process.size;
    process.isCompleted = true;
    process.status = ProcessStatus.completed;

    // Try to start pending processes
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

  void _tryStartPendingProcesses(Process mainProcess) {
    final maxSlotSize = mainProcess.size ~/ 2;
    
    while (_pendingSecondaryProcesses.isNotEmpty) {
      final nextProcess = _pendingSecondaryProcesses.first;
      if (_canStartProcess(nextProcess, maxSlotSize)) {
        _pendingSecondaryProcesses.removeFirst();
        _startSecondaryProcess(nextProcess);
      } else {
        break;
      }
    }
  }

  void _completeMainProcess(Process process) {
    _mainProcesses.remove(process);
    _completedProcesses.add(process);
    process.isCompleted = true;
    notifyListeners();
  }

  void removeProcess(Process process) {
    _progressTimers[process]?.cancel();
    _progressTimers.remove(process);
    
    if (process.isMain) {
      // Update current processing size and clean up
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
