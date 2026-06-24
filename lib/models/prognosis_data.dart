// 予後情報モデル
// データソース:
//   - FIGO 2023 ステージ別OS: PMC 2025 (Zhejiang大学720例, J Cancer 2025)
//   - 分子分類別OS: 同論文 + KAKEN日本データ (ProMisE分類)
//   - NSMP×ER層別化: Vermij et al. Br J Cancer 2023 / Gynecol Oncol 2025

/// 予後信頼度（エビデンスレベル）
enum PrognosisConfidence {
  high('高', 'データ数十分・複数論文一致'),
  moderate('中', '単一または少数施設データ'),
  low('低', 'サンプル数少・参考値');

  const PrognosisConfidence(this.label, this.description);
  final String label;
  final String description;
}

/// 5年生存率データ（ステージ単独）
class StageSurvivalData {
  final String stageLabel;   // 例: "IA2"
  final double? os5yr;       // 5年OS（0.0〜1.0）
  final double? pfs5yr;      // 5年PFS（0.0〜1.0）
  final PrognosisConfidence confidence;
  final String source;

  const StageSurvivalData({
    required this.stageLabel,
    this.os5yr,
    this.pfs5yr,
    required this.confidence,
    required this.source,
  });
}

/// 分子分類による予後補正コメント
class MolecularPrognosisNote {
  final String subtype;         // 例: "POLEmut"
  final String headline;        // 一行サマリー
  final String detail;          // 詳細説明
  final double? os5yrOverall;   // 分子分類全体の5年OS目安
  final String color;           // 表示色キー

  const MolecularPrognosisNote({
    required this.subtype,
    required this.headline,
    required this.detail,
    this.os5yrOverall,
    required this.color,
  });
}

/// ER補正情報（NSMPのみ有効）
class ErPrognosisNote {
  final String erLabel;
  final String impact;
  final double? os10yrNsmp;     // NSMP内でのER別10年OS
  final double? pfs5yrNsmp;     // NSMP内でのER別5年PFS
  final bool isApplicable;      // 現在の分子分類でER補正が有意か

  const ErPrognosisNote({
    required this.erLabel,
    required this.impact,
    this.os10yrNsmp,
    this.pfs5yrNsmp,
    required this.isApplicable,
  });
}

/// 予後情報の総合結果（PrognnosisEngine が返す）
class PrognosisResult {
  final StageSurvivalData stageSurvival;
  final MolecularPrognosisNote molecularNote;
  final ErPrognosisNote? erNote;              // NSMPかつER入力あり時のみ
  final List<String> prognosticFactors;       // 予後不良/良好因子リスト
  final String summaryText;                   // 総合サマリー文
  final String disclaimer;                    // 免責注記
  final List<String> references;             // 参考文献

  const PrognosisResult({
    required this.stageSurvival,
    required this.molecularNote,
    this.erNote,
    required this.prognosticFactors,
    required this.summaryText,
    required this.disclaimer,
    required this.references,
  });
}
