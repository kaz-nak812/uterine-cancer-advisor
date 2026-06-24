// リスク分類・治療推奨モデル

/// ESMO/ESGO/ESTRO リスク分類
enum RiskCategory {
  low('低リスク', 'Low Risk', 0xFF4CAF50),
  lowIntermediate('低-中間リスク', 'Low-Intermediate Risk', 0xFF8BC34A),
  intermediate('中間リスク', 'Intermediate Risk', 0xFFFFC107),
  highIntermediate('高-中間リスク', 'High-Intermediate Risk', 0xFFFF9800),
  high('高リスク', 'High Risk', 0xFFF44336),
  advanced('進行・転移', 'Advanced / Metastatic', 0xFF9C27B0);

  const RiskCategory(this.label, this.englishLabel, this.colorValue);
  final String label;
  final String englishLabel;
  final int colorValue;
}

/// 放射線治療モダリティ
enum RadiationModality {
  vbt('VBT', '腟断端小線源療法', 'Vaginal Brachytherapy'),
  ebrt('EBRT（骨盤照射）', '外部放射線治療（骨盤）', 'External Beam Radiation Therapy'),
  imrt('IMRT', '強度変調放射線治療', 'Intensity Modulated Radiation Therapy'),
  paraAorticEbrt('EBRT（傍大動脈）', '傍大動脈野放射線治療', 'Para-aortic EBRT'),
  brachy('子宮腔内照射', '子宮腔内小線源療法', 'Intracavitary Brachytherapy');

  const RadiationModality(this.label, this.japaneseDesc, this.englishLabel);
  final String label;
  final String japaneseDesc;
  final String englishLabel;
}

/// 化学療法レジメン
enum ChemoRegimen {
  carbotaxol('カルボプラチン＋パクリタキセル', 'Carboplatin + Paclitaxel (TC)'),
  cisplatinCrt('シスプラチン同時併用（CRT）', 'Cisplatin concurrent (CRT)'),
  dostarlimab('ドスタルリマブ＋TC', 'Dostarlimab + TC'),
  lenvatinibPembro('レンバチニブ＋ペムブロリズマブ', 'Lenvatinib + Pembrolizumab');

  const ChemoRegimen(this.label, this.englishLabel);
  final String label;
  final String englishLabel;
}

/// 推奨治療の推奨強度
enum RecommendationStrength {
  strongRecommend('強く推奨', 'Strong recommendation'),
  recommend('推奨', 'Recommendation'),
  consider('考慮可', 'Can be considered'),
  notRecommend('推奨しない', 'Not recommended');

  const RecommendationStrength(this.label, this.englishLabel);
  final String label;
  final String englishLabel;
}

/// 個別治療推奨
class TreatmentRecommendation {
  final String title;
  final String description;
  final RecommendationStrength strength;
  final List<String> details;
  final String? guideline; // 参照ガイドライン

  const TreatmentRecommendation({
    required this.title,
    required this.description,
    required this.strength,
    required this.details,
    this.guideline,
  });
}

/// リスク評価結果
class RiskAssessmentResult {
  final RiskCategory riskCategory;
  final String rationale; // 判定根拠
  final List<String> keyFactors; // 主要因子
  final List<TreatmentRecommendation> primaryRecommendations;
  final List<TreatmentRecommendation> alternativeRecommendations;
  final List<String> importantNotes;
  final String guidelineReference;

  const RiskAssessmentResult({
    required this.riskCategory,
    required this.rationale,
    required this.keyFactors,
    required this.primaryRecommendations,
    this.alternativeRecommendations = const [],
    required this.importantNotes,
    required this.guidelineReference,
  });
}
