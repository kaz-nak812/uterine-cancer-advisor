import 'package:flutter/foundation.dart';
import '../models/patient_data.dart';
import '../models/risk_assessment.dart';
import 'guideline_engine.dart';

class AppState extends ChangeNotifier {
  PatientData _patientData = PatientData();
  RiskAssessmentResult? _result;
  int _currentStep = 0;
  final int totalSteps = 4;

  PatientData get patientData => _patientData;
  RiskAssessmentResult? get result => _result;
  int get currentStep => _currentStep;

  bool get canProceed {
    switch (_currentStep) {
      case 0:
        return _patientData.figoStage != null;
      case 1:
        return _patientData.histologicalType != null;
      case 2:
        return _patientData.lvsiStatus != null;
      case 3:
        return _patientData.molecularSubtype != null;
      default:
        return false;
    }
  }

  void updateFigoStage(FigoStage? stage) {
    _patientData.figoStage = stage;
    _result = null;
    notifyListeners();
  }

  void updateHistologicalType(HistologicalType? type) {
    _patientData.histologicalType = type;
    _result = null;
    notifyListeners();
  }

  void updateLvsi(LvsiStatus? lvsi) {
    _patientData.lvsiStatus = lvsi;
    _result = null;
    notifyListeners();
  }

  void updateMolecularSubtype(MolecularSubtype? subtype) {
    _patientData.molecularSubtype = subtype;
    _result = null;
    notifyListeners();
  }

  void updateErStatus(ErStatus? er) {
    _patientData.erStatus = er;
    notifyListeners();
  }

  void updateLymphadenectomy(bool? performed) {
    _patientData.lymphadenectomyPerformed = performed;
    notifyListeners();
  }

  void updatePeritonealCytology(bool? positive) {
    _patientData.peritonealCytologyPositive = positive;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  RiskAssessmentResult evaluate() {
    _result = GuidelineEngine.evaluate(_patientData);
    notifyListeners();
    return _result!;
  }

  void reset() {
    _patientData = PatientData();
    _result = null;
    _currentStep = 0;
    notifyListeners();
  }
}
