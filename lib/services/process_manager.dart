import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/process.dart';

class ProcessManager extends ChangeNotifier {
  final List<Process> _mainProcesses = [];
  final List<Process> _secondaryProcesses = [];
  final List<Process> _completedProcesses = [];
  final _random = Random();
  final Map<Process, Timer> _progressTimers = {};

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
    final count = _random.nextInt(7) + 7;
    for (var i = 0; i < count; i++) {
      final secondaryProcess = Process.secondary(
        index: i,
        parent: mainProcess,
      );
      _secondaryProcesses.add(secondaryProcess);
      _startProgressTimer(secondaryProcess);
    }
  }

  void _startProgressTimer(Process process) {
    final progressIncrement = 0.01 + (_random.nextDouble() * 0.02);
    const updateInterval = Duration(milliseconds: 250);

    _progressTimers[process] = Timer.periodic(updateInterval, (timer) {
      process.progress = (process.progress + progressIncrement).clamp(0.0, 1.0);
      
      if (process.progress >= 1.0) {
        timer.cancel();
        _progressTimers.remove(process);
        
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
    final secondaryProcesses = _secondaryProcesses
        .where((p) => p.parentProcess == mainProcess)
        .toList();
    
    final completedSecondaries = _completedProcesses
        .where((p) => !p.isMain && p.parentProcess == mainProcess)
        .toList();

    return secondaryProcesses.isEmpty && 
           completedSecondaries.isNotEmpty && 
           mainProcess.progress >= 1.0;
  }

  void _completeSecondaryProcess(Process process) {
    _secondaryProcesses.remove(process);
    _completedProcesses.add(process);
    process.isCompleted = true;
  
    if (process.parentProcess != null && 
        process.parentProcess!.progress >= 1.0 && 
        _canCompleteMainProcess(process.parentProcess!)) {
      _completeMainProcess(process.parentProcess!);
    }
    notifyListeners();
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
      _secondaryProcesses
          .where((p) => p.parentProcess == process)
          .forEach((p) {
            _progressTimers[p]?.cancel();
            _progressTimers.remove(p);
          });
      
      _mainProcesses.remove(process);
      _secondaryProcesses.removeWhere((p) => p.parentProcess == process);
    } else {
      _secondaryProcesses.remove(process);
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
}
