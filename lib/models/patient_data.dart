// 患者データモデル - FIGO2023・分子分類・病理所見

/// FIGO 2023 ステージ
enum FigoStage {
  ia('IA', '腫瘍が子宮体部に限局、筋層浸潤 < 1/2'),
  ib('IB', '腫瘍が子宮体部に限局、筋層浸潤 ≥ 1/2'),
  ic('IC', '子宮漿膜に限局（子宮全体を超えない）'),
  iia('IIA', '子宮頸部間質への浸潤'),
  iib('IIB', '卵巣・卵管への浸潤（または同時原発）'),
  iiia('IIIA', '子宮漿膜・付属器への浸潤'),
  iiib('IIIB', '腟・子宮傍組織への浸潤'),
  iiic1('IIIC1', '骨盤内リンパ節転移'),
  iiic2('IIIC2', '傍大動脈リンパ節転移'),
  iva('IVA', '膀胱・腸管粘膜への浸潤'),
  ivb('IVB', '腹膜播種・遠隔転移');

  const FigoStage(this.label, this.description);
  final String label;
  final String description;
}

/// 組織型
enum HistologicalType {
  endometrioid1('類内膜癌 G1', 'Endometrioid Grade 1'),
  endometrioid2('類内膜癌 G2', 'Endometrioid Grade 2'),
  endometrioid3('類内膜癌 G3', 'Endometrioid Grade 3'),
  serous('漿液性癌', 'Serous carcinoma'),
  clearCell('明細胞癌', 'Clear cell carcinoma'),
  carcinosarcoma('癌肉腫', 'Carcinosarcoma'),
  undifferentiated('未分化癌', 'Undifferentiated carcinoma'),
  mucinous('粘液性癌', 'Mucinous carcinoma'),
  mixed('混合型癌', 'Mixed carcinoma');

  const HistologicalType(this.label, this.englishLabel);
  final String label;
  final String englishLabel;

  /// 高リスク組織型かどうか
  bool get isHighRiskHistology => [
    HistologicalType.serous,
    HistologicalType.clearCell,
    HistologicalType.carcinosarcoma,
    HistologicalType.undifferentiated,
  ].contains(this);

  /// 類内膜癌かどうか
  bool get isEndometrioid => [
    HistologicalType.endometrioid1,
    HistologicalType.endometrioid2,
    HistologicalType.endometrioid3,
  ].contains(this);
}

/// LVSI（リンパ管血管浸襲）
enum LvsiStatus {
  absent('なし', 'Absent'),
  focal('限局性（focal）', 'Focal (<50%)'),
  substantial('広範（substantial）', 'Substantial (≥50%)');

  const LvsiStatus(this.label, this.englishLabel);
  final String label;
  final String englishLabel;
}

/// 分子分類（ProMisE / TCGA分類）
enum MolecularSubtype {
  poleMutated('POLEmut', 'POLE変異型', 'POLE exonuclease domain mutation'),
  mmrd('MMRd', 'MMR欠損型', 'Mismatch repair deficient'),
  p53abn('p53abn', 'p53異常型', 'p53 abnormal / TP53 mutant'),
  nsmp('NSMP', '特異的分子プロファイルなし', 'No Specific Molecular Profile');

  const MolecularSubtype(this.shortLabel, this.label, this.description);
  final String shortLabel;
  final String label;
  final String description;
}

/// ER（エストロゲン受容体）状態
/// 治療選択カットオフ: ≥1%（陽性定義 / ESMO 2020）
/// 予後判定カットオフ: ≥10%（NSMP層別化 / Vermij et al. Br J Cancer 2023）
enum ErStatus {
  highPositive('高発現（ER ≥10%）', '予後良好サブタイプ（治療・予後両方で陽性）'),
  lowPositive('低発現（ER 1〜9%）', '治療上は陽性、予後判定では低発現扱い'),
  negative('陰性（ER <1%）', '治療・予後いずれも陰性'),
  unknown('不明', '');

  const ErStatus(this.label, this.description);
  final String label;
  final String description;

  /// 治療選択（ホルモン療法適応）での陽性判定: ≥1%
  bool get isPositiveForTreatment =>
      this == ErStatus.highPositive || this == ErStatus.lowPositive;

  /// 予後判定での高発現判定: ≥10%（NSMP層別化に使用）
  bool get isHighForPrognosis => this == ErStatus.highPositive;
}

/// 手術術式
enum SurgeryType {
  totalHysterectomyBso('単純子宮全摘＋両側付属器切除', 'TH + BSO'),
  radicalHysterectomy('広汎子宮全摘', 'Radical hysterectomy'),
  lymphadenectomy('リンパ節郭清あり', 'With lymphadenectomy'),
  noLymphadenectomy('リンパ節郭清なし', 'Without lymphadenectomy'),
  sentinelLn('センチネルリンパ節生検', 'Sentinel LN biopsy');

  const SurgeryType(this.label, this.shortLabel);
  final String label;
  final String shortLabel;
}

/// 患者データ全体モデル
class PatientData {
  // 病理所見
  FigoStage? figoStage;
  HistologicalType? histologicalType;
  LvsiStatus? lvsiStatus;

  // 分子分類
  MolecularSubtype? molecularSubtype;
  ErStatus? erStatus;

  // 手術情報
  bool? lymphadenectomyPerformed;
  bool? peritonealCytologyPositive;
  bool? myometrialInvasionDeep; // ≥50%

  // 追加病理情報
  bool? cervicalStromalInvasion;
  bool? adnexalInvolvement;
  bool? lymphNodePositive;
  bool? distantMetastasis;

  PatientData();

  PatientData copyWith({
    FigoStage? figoStage,
    HistologicalType? histologicalType,
    LvsiStatus? lvsiStatus,
    MolecularSubtype? molecularSubtype,
    ErStatus? erStatus,
    bool? lymphadenectomyPerformed,
    bool? peritonealCytologyPositive,
    bool? myometrialInvasionDeep,
    bool? cervicalStromalInvasion,
    bool? adnexalInvolvement,
    bool? lymphNodePositive,
    bool? distantMetastasis,
  }) {
    final copy = PatientData();
    copy.figoStage = figoStage ?? this.figoStage;
    copy.histologicalType = histologicalType ?? this.histologicalType;
    copy.lvsiStatus = lvsiStatus ?? this.lvsiStatus;
    copy.molecularSubtype = molecularSubtype ?? this.molecularSubtype;
    copy.erStatus = erStatus ?? this.erStatus;
    copy.lymphadenectomyPerformed =
        lymphadenectomyPerformed ?? this.lymphadenectomyPerformed;
    copy.peritonealCytologyPositive =
        peritonealCytologyPositive ?? this.peritonealCytologyPositive;
    copy.myometrialInvasionDeep =
        myometrialInvasionDeep ?? this.myometrialInvasionDeep;
    copy.cervicalStromalInvasion =
        cervicalStromalInvasion ?? this.cervicalStromalInvasion;
    copy.adnexalInvolvement = adnexalInvolvement ?? this.adnexalInvolvement;
    copy.lymphNodePositive = lymphNodePositive ?? this.lymphNodePositive;
    copy.distantMetastasis = distantMetastasis ?? this.distantMetastasis;
    return copy;
  }

  bool get isComplete =>
      figoStage != null &&
      histologicalType != null &&
      lvsiStatus != null &&
      molecularSubtype != null;
}
