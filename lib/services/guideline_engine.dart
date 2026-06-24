// ESMO 2020 / ESGO-ESTRO-ESP 2021 / NCCN 2024 ガイドライン判定エンジン
import '../models/patient_data.dart';
import '../models/risk_assessment.dart';

class GuidelineEngine {
  /// メイン判定ロジック
  static RiskAssessmentResult evaluate(PatientData data) {
    // 1. 分子分類による優先判定
    if (data.molecularSubtype == MolecularSubtype.poleMutated) {
      return _evaluatePOLEmut(data);
    }

    // 2. FIGO ステージ + 組織型 + LVSI で判定
    final stage = data.figoStage;
    final histo = data.histologicalType;

    if (stage == null || histo == null) {
      return _incompleteData();
    }

    // 進行期（IVA, IVB）
    if (stage == FigoStage.iva || stage == FigoStage.ivb) {
      return _evaluateAdvanced(data);
    }

    // IIIC1, IIIC2
    if (stage == FigoStage.iiic1 || stage == FigoStage.iiic2) {
      return _evaluateStageIIIC(data);
    }

    // IIIA, IIIB
    if (stage == FigoStage.iiia || stage == FigoStage.iiib) {
      return _evaluateStageIIIAB(data);
    }

    // Stage II
    if (stage == FigoStage.iia || stage == FigoStage.iib) {
      return _evaluateStageII(data);
    }

    // Stage I（IA, IB, IC）
    return _evaluateStageI(data);
  }

  // ─────────────────────────────────────────
  // POLE変異型
  // ─────────────────────────────────────────
  static RiskAssessmentResult _evaluatePOLEmut(PatientData data) {
    final stage = data.figoStage;
    // POLE変異型はステージIVBを除き基本的に低リスク扱い（ESMO 2020）
    if (stage == FigoStage.ivb) {
      return RiskAssessmentResult(
        riskCategory: RiskCategory.advanced,
        rationale: 'POLEmut でも IVB ステージは進行期として管理します。',
        keyFactors: ['POLE変異型', 'FIGO IVB'],
        primaryRecommendations: [
          TreatmentRecommendation(
            title: 'カルボプラチン＋パクリタキセル（TC）療法',
            description: '全身化学療法を優先。放射線治療は緩和目的で考慮。',
            strength: RecommendationStrength.strongRecommend,
            details: [
              'TC 6サイクル',
              'dMMR/MSI-H かつ非癌肉腫の場合: TC＋ペムブロリズマブを検討（KEYNOTE-868）',
              'pMMR の場合: DUO-E triplet（TC＋デュルバルマブ → デュルバルマブ＋オラパリブ維持）を検討',
            ],
            guideline: 'ESMO 2020 / NCCN 2024 / KEYNOTE-868 / DUO-E',
          ),
        ],
        importantNotes: _addCytologyNote(data, [
          'POLEmut IVBは予後良好の可能性があるが証拠は限られる',
          '多職種チームでの個別検討を推奨',
        ]),
        guidelineReference: 'ESMO 2020, NCCN Uterine Neoplasms v4.2024',
      );
    }

    return RiskAssessmentResult(
      riskCategory: RiskCategory.low,
      rationale:
          'POLE exonuclease domain 変異型（POLEmut）は、ステージや組織型に関わらず予後良好な分子サブタイプです。ESMO 2020 ガイドラインでは術後補助療法を省略または最小化することを推奨しています。',
      keyFactors: [
        'POLE変異型（最優先分子分類）',
        'ステージ: ${stage?.label ?? "不明"}',
        '組織型: ${data.histologicalType?.label ?? "不明"}',
      ],
      primaryRecommendations: [
        TreatmentRecommendation(
          title: '補助療法なし（経過観察）',
          description:
              'POLEmut の場合、ステージ I-III であれば術後補助療法は推奨されません。密な経過観察を行います。',
          strength: RecommendationStrength.strongRecommend,
          details: [
            '3〜6ヶ月毎の外来フォローアップ',
            '腫瘍マーカー（CA125）定期測定',
            '症状出現時の速やかな精査',
          ],
          guideline: 'ESMO 2020 Grade A',
        ),
      ],
      alternativeRecommendations: [
        TreatmentRecommendation(
          title: 'VBT（腟断端小線源療法）— 考慮可',
          description:
              'Grade 3 類内膜癌または IB 以上で LVSI substantial の場合、個別判断でVBTを考慮できる。',
          strength: RecommendationStrength.consider,
          details: ['エビデンスは限られる', '多職種カンファレンスでの検討推奨'],
          guideline: 'ESMO 2020',
        ),
      ],
      importantNotes: _addCytologyNote(data, [
        'POLE変異の確認は認定検査機関での次世代シークエンシング（NGS）が推奨されます',
        'POLEmutはMMRd・p53abnと同時に存在する場合でも予後良好',
        '日本では保険適用の分子検査を確認してください',
      ]),
      guidelineReference: 'ESMO 2020 (Ann Oncol), ESGO-ESTRO-ESP 2021',
    );
  }

  // ─────────────────────────────────────────
  // Stage I 判定
  // ─────────────────────────────────────────
  static RiskAssessmentResult _evaluateStageI(PatientData data) {
    final stage = data.figoStage;
    final histo = data.histologicalType!;
    final lvsi = data.lvsiStatus;
    final mol = data.molecularSubtype;

    // 高リスク組織型（漿液性・明細胞・癌肉腫・未分化）
    if (histo.isHighRiskHistology) {
      return _stageIHighRiskHistology(data);
    }

    // Stage IA - G1/G2 類内膜癌
    if (stage == FigoStage.ia) {
      if (histo == HistologicalType.endometrioid1 ||
          histo == HistologicalType.endometrioid2) {
        // LVSI なし → 低リスク
        if (lvsi == LvsiStatus.absent || lvsi == LvsiStatus.focal) {
          // p53abn の場合は高リスク
          if (mol == MolecularSubtype.p53abn) {
            return _stageIAP53abn(data);
          }
          return _stageIALowRisk(data);
        }
        // LVSI substantial → 低-中間リスク
        return _stageIALvsiSubstantial(data);
      }
      // Stage IA - G3 類内膜癌
      if (histo == HistologicalType.endometrioid3) {
        if (mol == MolecularSubtype.p53abn) {
          return _stageIAP53abn(data);
        }
        return _stageIAG3(data);
      }
    }

    // Stage IB
    if (stage == FigoStage.ib) {
      if (histo == HistologicalType.endometrioid1 ||
          histo == HistologicalType.endometrioid2) {
        if (mol == MolecularSubtype.p53abn) {
          return _stageIBP53abn(data);
        }
        if (lvsi == LvsiStatus.substantial) {
          return _stageIBSubstantialLvsi(data);
        }
        return _stageIBG1G2(data);
      }
      if (histo == HistologicalType.endometrioid3) {
        if (mol == MolecularSubtype.p53abn) {
          return _stageIBP53abn(data);
        }
        return _stageIBG3(data);
      }
    }

    // Stage IC（子宮漿膜限局）
    if (stage == FigoStage.ic) {
      return _stageIC(data);
    }

    return _stageIBG1G2(data); // デフォルト
  }

  static RiskAssessmentResult _stageIALowRisk(PatientData data) {
    return RiskAssessmentResult(
      riskCategory: RiskCategory.low,
      rationale:
          'FIGO IA、類内膜癌 G1/G2、LVSI なし/focal は「低リスク」に分類されます。術後補助療法の上乗せ効果はなく、経過観察が標準治療です。',
      keyFactors: [
        'FIGO ${data.figoStage?.label}',
        '${data.histologicalType?.label}',
        'LVSI: ${data.lvsiStatus?.label ?? "不明"}',
        '分子分類: ${data.molecularSubtype?.shortLabel ?? "不明"}',
      ],
      primaryRecommendations: [
        TreatmentRecommendation(
          title: '経過観察（補助療法なし）',
          description: '術後補助療法は推奨されません。定期的な経過観察を行います。',
          strength: RecommendationStrength.strongRecommend,
          details: [
            '3〜6ヶ月毎の外来診察',
            '腫瘍マーカー（CA125）定期測定',
            '骨盤内再発の早期発見のため問診・内診を実施',
          ],
          guideline: 'ESMO 2020 / NCCN 2024',
        ),
      ],
      importantNotes: _addCytologyNote(data, [
        'LVSI focalは低リスクに含まれますが、病理医との詳細な確認が推奨されます',
        'NSMPの場合でも本リスク分類が適用されます',
        'MMRd の場合も低リスク群として管理',
      ]),
      guidelineReference: 'ESMO 2020, NCCN Uterine Neoplasms v4.2024',
    );
  }

  static RiskAssessmentResult _stageIALvsiSubstantial(PatientData data) {
    return RiskAssessmentResult(
      riskCategory: RiskCategory.lowIntermediate,
      rationale:
          'FIGO IA、類内膜癌 G1/G2 でも LVSI substantial（広範リンパ管血管浸襲）は「低-中間リスク」に分類されます。VBTによる局所制御を考慮します。',
      keyFactors: [
        'FIGO ${data.figoStage?.label}',
        '${data.histologicalType?.label}',
        'LVSI: 広範（substantial）',
      ],
      primaryRecommendations: [
        TreatmentRecommendation(
          title: 'VBT（腟断端小線源療法）',
          description: '腟断端局所再発リスクを低減するためVBTを推奨します。',
          strength: RecommendationStrength.recommend,
          details: [
            '腟断端BT（HDR）: 3回分割または2回分割',
            '局所制御率の改善に有効（PORTEC-1試験）',
            'QOLへの影響が少ない',
          ],
          guideline: 'ESMO 2020 / ESGO-ESTRO-ESP 2021',
        ),
      ],
      alternativeRecommendations: [
        TreatmentRecommendation(
          title: '経過観察（考慮可）',
          description: 'LVSI substantialでも経過観察を選択する場合はリスクを十分説明します。',
          strength: RecommendationStrength.consider,
          details: ['患者と十分なインフォームドコンセントが必要'],
          guideline: 'ESMO 2020',
        ),
      ],
      importantNotes: _addCytologyNote(data, [
        'LVSI substantialの定義：腫瘍周囲の脈管浸襲が複数かつ広範',
        'リンパ節郭清が施行されている場合でも VBT を考慮',
      ]),
      guidelineReference: 'ESMO 2020, PORTEC-1, ESGO-ESTRO-ESP 2021',
    );
  }

  static RiskAssessmentResult _stageIAG3(PatientData data) {
    return RiskAssessmentResult(
      riskCategory: RiskCategory.intermediate,
      rationale:
          'FIGO IA、類内膜癌 G3 は「中間リスク」〜「高-中間リスク」に分類されます。LVSI・分子分類によりVBTまたはEBRTを考慮します。',
      keyFactors: [
        'FIGO IA',
        '類内膜癌 G3',
        'LVSI: ${data.lvsiStatus?.label ?? "不明"}',
        '分子分類: ${data.molecularSubtype?.shortLabel ?? "不明"}',
      ],
      primaryRecommendations: [
        TreatmentRecommendation(
          title: 'VBT（腟断端小線源療法）',
          description: 'G3 IA 類内膜癌では VBT が標準推奨です。',
          strength: RecommendationStrength.recommend,
          details: [
            '腟断端再発リスクの低減',
            'LVSI absent でも G3 では VBT を考慮',
            'LVSI substantial の場合は EBRT も検討',
          ],
          guideline: 'ESMO 2020',
        ),
      ],
      alternativeRecommendations: [
        TreatmentRecommendation(
          title: 'EBRT（骨盤照射）＋/－VBT',
          description: 'LVSI substantial を伴う場合は骨盤EBRTも考慮します。',
          strength: RecommendationStrength.consider,
          details: ['骨盤EBRT 45〜50Gy', 'VBTとの組み合わせ'],
          guideline: 'ESMO 2020',
        ),
      ],
      importantNotes: _addCytologyNote(data, [
        'G3 類内膜癌の場合、分子分類（特にp53abn）の確認が重要です',
        'MMRd の場合でも G3 は中間リスク以上として管理',
      ]),
      guidelineReference: 'ESMO 2020, ESGO-ESTRO-ESP 2021',
    );
  }

  static RiskAssessmentResult _stageIAP53abn(PatientData data) {
    return RiskAssessmentResult(
      riskCategory: RiskCategory.high,
      rationale:
          'p53異常型（p53abn）はステージIAであっても「高リスク」相当と判断されます。ESMO 2020では術後補助療法（化学療法＋放射線治療）を推奨しています。',
      keyFactors: [
        'p53異常型（高リスク分子分類）',
        'FIGO ${data.figoStage?.label}',
        '${data.histologicalType?.label}',
      ],
      primaryRecommendations: [
        TreatmentRecommendation(
          title: 'カルボプラチン＋パクリタキセル（TC）＋VBT',
          description: 'p53abn は化学療法＋放射線治療の組み合わせが推奨されます。',
          strength: RecommendationStrength.recommend,
          details: [
            'TC 療法 6サイクル',
            'VBT（腟断端小線源療法）',
            'Sandwich法（化学療法→RT→化学療法）も選択肢',
          ],
          guideline: 'ESMO 2020',
        ),
      ],
      alternativeRecommendations: [
        TreatmentRecommendation(
          title: 'VBT のみ（個別検討）',
          description: '合併症等でTC療法が困難な場合はVBTのみも検討可。',
          strength: RecommendationStrength.consider,
          details: ['患者状態・合併症を十分に評価'],
          guideline: 'ESMO 2020',
        ),
      ],
      importantNotes: _addCytologyNote(data, [
        'p53abn は TP53体細胞変異または免疫染色p53異常発現で定義',
        'POLEmut と同時陽性の場合はPOLEmutを優先（低リスク扱い）',
        'MMRd と同時陽性の場合はp53abnを優先（高リスク扱い）',
      ]),
      guidelineReference: 'ESMO 2020, ESGO-ESTRO-ESP 2021',
    );
  }

  static RiskAssessmentResult _stageIBG1G2(PatientData data) {
    return RiskAssessmentResult(
      riskCategory: RiskCategory.lowIntermediate,
      rationale:
          'FIGO IB、類内膜癌 G1/G2 は「低-中間リスク」です。年齢・LVSI・分子分類により VBT を考慮します（PORTEC-1/2試験）。',
      keyFactors: [
        'FIGO IB',
        '${data.histologicalType?.label}',
        'LVSI: ${data.lvsiStatus?.label ?? "不明"}',
        '分子分類: ${data.molecularSubtype?.shortLabel ?? "不明"}',
      ],
      primaryRecommendations: [
        TreatmentRecommendation(
          title: 'VBT（腟断端小線源療法）',
          description: 'IB G1/G2 では VBT が標準推奨です（PORTEC-2試験で骨盤EBRT と同等の局所制御率）。',
          strength: RecommendationStrength.strongRecommend,
          details: [
            '腟断端HDR小線源療法（3回または2回分割）',
            '骨盤EBRT より低侵襲でQOL良好',
            'PORTEC-2: VBT vs EBRT で局所制御率同等、毒性はVBTが低い',
          ],
          guideline: 'ESMO 2020 / PORTEC-2 / NCCN 2024',
        ),
      ],
      alternativeRecommendations: [
        TreatmentRecommendation(
          title: '経過観察（60歳未満 G1）',
          description: '60歳未満 G1 LVSI なしは経過観察も選択肢。',
          strength: RecommendationStrength.consider,
          details: ['若年・低グレードでは再発リスクが低い'],
          guideline: 'ESMO 2020',
        ),
      ],
      importantNotes: _addCytologyNote(data, [
        'PORTEC-2試験（2010）: VBTはEBRTと同等の腟断端制御率で毒性が少ない',
        'MMRd IB G1/G2 でも同様の管理で可',
      ]),
      guidelineReference: 'ESMO 2020, PORTEC-2 (Lancet 2010), NCCN 2024',
    );
  }

  static RiskAssessmentResult _stageIBSubstantialLvsi(PatientData data) {
    return RiskAssessmentResult(
      riskCategory: RiskCategory.highIntermediate,
      rationale:
          'FIGO IB、LVSI substantial は「高-中間リスク」です。骨盤 EBRT または VBT が推奨されます。',
      keyFactors: ['FIGO IB', 'LVSI: 広範（substantial）', '${data.histologicalType?.label}'],
      primaryRecommendations: [
        TreatmentRecommendation(
          title: 'EBRT（骨盤照射）＋/－VBT',
          description: 'LVSI substantial を伴う IB では骨盤 EBRT が推奨されます。',
          strength: RecommendationStrength.recommend,
          details: [
            '骨盤EBRT 45〜50.4Gy（IMRT推奨）',
            'VBT boost 追加も考慮',
            'IMRT による正常組織毒性の低減',
          ],
          guideline: 'ESMO 2020 / ESGO-ESTRO-ESP 2021',
        ),
        TreatmentRecommendation(
          title: 'VBT のみ（代替）',
          description: '骨盤EBRTが困難な場合はVBTのみも選択肢。',
          strength: RecommendationStrength.consider,
          details: ['患者希望・合併症を考慮'],
          guideline: 'ESMO 2020',
        ),
      ],
      importantNotes: _addCytologyNote(data, [
        'LVSI substantialはリンパ節転移リスクが高く注意が必要',
        'リンパ節郭清が未実施の場合は骨盤EBRTを優先',
      ]),
      guidelineReference: 'ESMO 2020, ESGO-ESTRO-ESP 2021',
    );
  }

  static RiskAssessmentResult _stageIBG3(PatientData data) {
    final mol = data.molecularSubtype;
    return RiskAssessmentResult(
      riskCategory: RiskCategory.highIntermediate,
      rationale:
          'FIGO IB、類内膜癌 G3 は「高-中間リスク」です。PORTEC-3試験でCRTが放射線単独より有意に五年OS・PFSを改善したため、TC＋EBRT±VBTを第一推奨とします。',
      keyFactors: [
        'FIGO IB',
        '類内膜癌 G3',
        'LVSI: ${data.lvsiStatus?.label ?? "不明"}',
        '分子分類: ${mol?.shortLabel ?? "不明"}',
      ],
      primaryRecommendations: [
        TreatmentRecommendation(
          title: 'TC 化学療法＋ EBRT（骨盤照射）± VBT（CRT）',
          description:
              'PORTEC-3試験でCRTが放射線単独より有意に五年OS・PFS改善（特にp53abn/G3で効果大）。',
          strength: RecommendationStrength.strongRecommend,
          details: [
            'TC 6サイクル（Sandwich法: TC3 → EBRT±VBT → TC3）',
            '骨盤EBRT 45〜50.4Gy（IMRT推奨）',
            'VBT boost（HDR）追加推奨',
            'PORTEC-3: 五年OS 81.8% vs 76.7%（CRT vs RT単独、p53abn/G3群で特に有益）',
          ],
          guideline: 'PORTEC-3 (Lancet Oncol 2018) / ESMO 2020 / NCCN 2024',
        ),
      ],
      alternativeRecommendations: [
        TreatmentRecommendation(
          title: 'EBRT（骨盤照射）± VBTのみ（化学療法困難例）',
          description: 'PS不良・合併症等でTC療法が困難な場合の代替。',
          strength: RecommendationStrength.recommend,
          details: [
            '骨盤EBRT 45〜50.4Gy（IMRT）',
            'VBT boost（HDR）',
            '患者状態・共存疾患を十分に評価',
          ],
          guideline: 'ESMO 2020',
        ),
      ],
      importantNotes: _addCytologyNote(data, [
        'PORTEC-3: CRTが放射線単独より有意にOS・PFS改善（特にp53abn/G3群で効果大）',
        'p53abn IB G3 は高リスク——本パスはNSMP/MMRd IB G3に適用',
        'MMRd IB G3 でもCRTの適応を検討（分子分類にかかわらず組織型・ステージ優先）',
      ]),
      guidelineReference: 'PORTEC-3 (Lancet Oncol 2018), ESMO 2020, NCCN 2024',
    );
  }

  static RiskAssessmentResult _stageIBP53abn(PatientData data) {
    return RiskAssessmentResult(
      riskCategory: RiskCategory.high,
      rationale:
          'FIGO IB、p53abn（p53異常型）は「高リスク」です。化学療法＋放射線治療の組み合わせを推奨します。',
      keyFactors: ['FIGO IB', 'p53異常型', '${data.histologicalType?.label}'],
      primaryRecommendations: [
        TreatmentRecommendation(
          title: 'TC 化学療法＋ EBRT ± VBT',
          description: 'p53abn IB は化学療法と放射線治療の組み合わせが推奨されます。',
          strength: RecommendationStrength.strongRecommend,
          details: [
            'TC 6サイクル（カルボプラチン AUC5 ＋ パクリタキセル 175mg/m²）',
            '骨盤EBRT 45〜50.4Gy（IMRT）',
            'VBT boost 追加考慮',
            'Sandwich法またはsequential法',
          ],
          guideline: 'ESMO 2020 / PORTEC-3',
        ),
      ],
      importantNotes: _addCytologyNote(data, [
        'PORTEC-3試験では化学放射線療法（CRT）が放射線単独より有意に予後改善',
        'TC療法の毒性評価（末梢神経障害、骨髄抑制）を定期的に実施',
        'POLEmutと同時陽性の場合はPOLEmutを優先',
      ]),
      guidelineReference: 'ESMO 2020, PORTEC-3 (Lancet Oncol 2018)',
    );
  }

  static RiskAssessmentResult _stageIC(PatientData data) {
    final mol = data.molecularSubtype;
    final histo = data.histologicalType;
    return RiskAssessmentResult(
      riskCategory: RiskCategory.highIntermediate,
      rationale:
          'FIGO IC（子宮漿膜限局）は「高-中間リスク」です。FIGO 2023 新分類のステージで、組織型・分子分類に応じて EBRT±VBT±化学療法を検討します。',
      keyFactors: [
        'FIGO IC',
        histo?.label ?? '不明',
        'LVSI: ${data.lvsiStatus?.label ?? "不明"}',
        '分子分類: ${mol?.shortLabel ?? "不明"}',
      ],
      primaryRecommendations: [
        TreatmentRecommendation(
          title: 'EBRT（骨盤照射）± VBT',
          description: 'IC ステージでは骨盤 EBRT ± VBT boost が推奨されます。',
          strength: RecommendationStrength.strongRecommend,
          details: [
            '骨盤EBRT 45〜50.4Gy（IMRT推奨）',
            'VBT boost（HDR）を追加考慮',
            '類内膜癌G3・p53abnの場合はTC化学療法の追加を強く考慮',
          ],
          guideline: 'ESMO 2020 / NCCN 2024',
        ),
      ],
      alternativeRecommendations: [
        TreatmentRecommendation(
          title: 'TC 化学療法＋ EBRT（G3・p53abnの場合）',
          description: '類内膜癌G3、p53abnではTC+EBRT（CRT）を積極検討。',
          strength: RecommendationStrength.consider,
          details: [
            'TC 6サイクル（Sandwich法）',
            '骨盤EBRT 45〜50.4Gy（IMRT）',
            'PORTEC-3試験の知見をICにも適用可能',
          ],
          guideline: 'PORTEC-3 / NCCN 2024',
        ),
      ],
      importantNotes: _addCytologyNote(data, [
        'IC は FIGO 2023 新分類（旧 FIGO では IA/IB に包含されていた）',
        '高リスク組織型（漿液性癌・明細胞癌・癌肉腫・未分化癌）は別途高リスク組織型パスで判定',
        'p53abn IC は高リスクとしてTC+放射線治療を強く推奨',
      ]),
      guidelineReference: 'ESMO 2020, FIGO 2023 staging, PORTEC-3, NCCN 2024',
    );
  }

  // ─────────────────────────────────────────
  // 高リスク組織型 Stage I
  // ─────────────────────────────────────────
  static RiskAssessmentResult _stageIHighRiskHistology(PatientData data) {
    final histo = data.histologicalType!;
    final stage = data.figoStage!;

    return RiskAssessmentResult(
      riskCategory: RiskCategory.high,
      rationale:
          '${histo.label} は「高リスク組織型」です。FIGO ${stage.label} であっても積極的な術後補助療法が推奨されます。',
      keyFactors: [
        '高リスク組織型: ${histo.label}',
        'FIGO ${stage.label}',
        'LVSI: ${data.lvsiStatus?.label ?? "不明"}',
        '分子分類: ${data.molecularSubtype?.shortLabel ?? "不明"}',
      ],
      primaryRecommendations: [
        TreatmentRecommendation(
          title: 'TC 化学療法＋ EBRT（骨盤照射）± VBT',
          description: '高リスク組織型では化学療法と放射線治療の組み合わせが標準です。',
          strength: RecommendationStrength.strongRecommend,
          details: [
            'TC 6サイクル（カルボプラチン ＋ パクリタキセル）',
            '骨盤EBRT 45〜50.4Gy（IMRT）',
            'VBT boost 追加',
            'Sandwich法（TC3 → EBRT±VBT → TC3）が一般的',
          ],
          guideline: 'ESMO 2020 / NCCN 2024',
        ),
      ],
      alternativeRecommendations: [
        TreatmentRecommendation(
          title: 'TC 化学療法のみ（放射線治療困難例）',
          description: '放射線治療が困難な場合は化学療法単独も検討可。',
          strength: RecommendationStrength.consider,
          details: ['骨盤照射の禁忌・高齢・PS不良などを考慮'],
          guideline: 'NCCN 2024',
        ),
      ],
      importantNotes: _addCytologyNote(data, [
        '漿液性癌・明細胞癌は早期でもリンパ節転移・腹膜播種のリスクが高い',
        '癌肉腫（カルシノサルコーマ）は子宮体癌として管理',
        '全腹部照射（WAI）は現在推奨されない',
        'p53abnとの組み合わせが多い（漿液性癌の90%以上でp53abn）',
      ]),
      guidelineReference: 'ESMO 2020, NCCN Uterine Neoplasms v4.2024',
    );
  }

  // ─────────────────────────────────────────
  // Stage II
  // ─────────────────────────────────────────
  static RiskAssessmentResult _evaluateStageII(PatientData data) {
    final histo = data.histologicalType!;
    final mol = data.molecularSubtype;

    if (mol == MolecularSubtype.poleMutated) {
      return _evaluatePOLEmut(data);
    }

    // 分子分類・組織型に応じた免疫療法推奨
    final immunoRec = (_isDmmr(mol) && _isCarcinosarcoma(data))
        ? _recCarcinosarcomaDmmr()
        : _isDmmr(mol)
            ? _recDmmrPembro()
            : _recPmmrDuoE(isStrongRecommend: false);

    final immunoNote = _isCarcinosarcoma(data) && _isDmmr(mol)
        ? '⚠️ 癌肉腫＋dMMR: KEYNOTE-868除外基準のためTC＋ペムブロリズマブは非適応。DUO-E doublet（Arm B）またはTC単独をMDTで検討'
        : _isDmmr(mol)
            ? 'MMRd（dMMR）: NCCN 2024でTC＋ペムブロリズマブを推奨（KEYNOTE-868）'
            : _isPmmr(mol)
                ? '${mol?.shortLabel ?? "NSMP/p53abn"} は pMMR 相当 → DUO-E triplet を検討'
                : '分子分類不明のためMMR IHC検査を実施してから免疫療法を判断';

    return RiskAssessmentResult(
      riskCategory: RiskCategory.high,
      rationale:
          'FIGO II（子宮頸部間質浸潤 IIA、または卵巣・卵管浸潤 IIB）は「高リスク」です。化学療法＋放射線治療の組み合わせが推奨されます。分子分類に応じた免疫療法の追加も検討します。',
      keyFactors: [
        'FIGO ${data.figoStage?.label}',
        histo.label,
        'LVSI: ${data.lvsiStatus?.label ?? "不明"}',
        '分子分類: ${mol?.shortLabel ?? "不明"}',
      ],
      primaryRecommendations: [
        TreatmentRecommendation(
          title: 'TC 化学療法＋ EBRT（骨盤照射）± VBT',
          description: 'Stage II では化学療法と骨盤 EBRT の組み合わせが推奨されます（PORTEC-3）。',
          strength: RecommendationStrength.strongRecommend,
          details: [
            'TC 6サイクル（Sandwich法推奨）',
            '骨盤EBRT 45〜50.4Gy（IMRT）',
            'VBT boost（HDR）3〜4回',
            'PORTEC-3試験: CRTの有効性確立',
          ],
          guideline: 'ESMO 2020 / PORTEC-3 / NCCN 2024',
        ),
        immunoRec,
      ],
      alternativeRecommendations: [
        TreatmentRecommendation(
          title: 'EBRT ± VBT（化学療法困難例）',
          description: '合併症等でTC療法が困難な場合の代替選択肢。',
          strength: RecommendationStrength.recommend,
          details: ['骨盤EBRT 45〜50.4Gy', 'VBT boost推奨'],
          guideline: 'ESMO 2020',
        ),
      ],
      importantNotes: _addCytologyNote(data, [
        'FIGO IIB（卵巣・卵管浸潤）はFIGO 2023新分類',
        '子宮頸部浸潤（IIA）では腟断端の放射線治療が重要',
        '広汎子宮全摘が施行された場合もCRTを検討',
        immunoNote,
      ]),
      guidelineReference: 'ESMO 2020, PORTEC-3, KEYNOTE-868 (NEJM 2023), DUO-E (JCO 2023), NCCN 2024, FIGO 2023',
    );
  }

  // ─────────────────────────────────────────
  // Stage IIIA, IIIB
  // ─────────────────────────────────────────
  static RiskAssessmentResult _evaluateStageIIIAB(PatientData data) {
    final mol = data.molecularSubtype;

    if (mol == MolecularSubtype.poleMutated) {
      return _evaluatePOLEmut(data);
    }

    // 分子分類・組織型に応じた免疫療法推奨を1つだけ選択
    // 癌肉腫＋dMMRの場合：KEYNOTE-868除外基準のためペムブロリズマブは推奨不可
    final immunoRec = (_isDmmr(mol) && _isCarcinosarcoma(data))
        ? _recCarcinosarcomaDmmr()
        : _isDmmr(mol)
            ? _recDmmrPembro()
            : _recPmmrDuoE(isStrongRecommend: false);

    final immunoNote = _isCarcinosarcoma(data) && _isDmmr(mol)
        ? '⚠️ 癌肉腫＋dMMR: KEYNOTE-868除外基準のためTC＋ペムブロリズマブは非適応。DUO-E doublet（Arm B）またはTC単独をMDTで検討'
        : _isDmmr(mol)
            ? 'MMRd（dMMR）のため TC＋ペムブロリズマブを優先検討'
            : _isPmmr(mol)
                ? '${mol?.shortLabel ?? "NSMP/p53abn"} は pMMR 相当 → DUO-E triplet を検討'
                : '分子分類不明のため MMR IHC 検査を実施してから免疫療法を判断';

    return RiskAssessmentResult(
      riskCategory: RiskCategory.high,
      rationale:
          'FIGO IIIA/IIIB（付属器・腹膜・腟・子宮傍組織への浸潤）は「高リスク」です。化学療法＋放射線治療の積極的な治療が推奨されます。',
      keyFactors: [
        'FIGO ${data.figoStage?.label}',
        '${data.histologicalType?.label}',
        '分子分類: ${mol?.shortLabel ?? "不明"}',
      ],
      primaryRecommendations: [
        const TreatmentRecommendation(
          title: 'TC 化学療法＋ EBRT（骨盤照射）± VBT',
          description: 'Stage III では化学療法と骨盤 EBRT の組み合わせが標準です。',
          strength: RecommendationStrength.strongRecommend,
          details: [
            'TC 6サイクル（Sandwich法推奨）',
            '骨盤EBRT 45〜50.4Gy（IMRT）',
            'VBT boost',
            'IIIA: 腹膜照射範囲の拡大を考慮',
          ],
          guideline: 'ESMO 2020 / PORTEC-3 / NCCN 2024',
        ),
        immunoRec,
      ],
      alternativeRecommendations: const [],
      importantNotes: _addCytologyNote(data, [
        'FIGO 2023 では IIIA は子宮漿膜・付属器浸潤、IIIB は腟・傍組織浸潤',
        immunoNote,
        'NCCN 2024: dMMR ではTC＋ペムブロリズマブを一次推奨として位置づけ',
        '術後腹腔内残存腫瘍がある場合は治療効果が不良',
      ]),
      guidelineReference: 'ESMO 2020, PORTEC-3, KEYNOTE-868 (NEJM 2023), DUO-E (JCO 2023), NCCN 2024',
    );
  }

  // ─────────────────────────────────────────
  // Stage IIIC
  // ─────────────────────────────────────────
  static RiskAssessmentResult _evaluateStageIIIC(PatientData data) {
    final mol = data.molecularSubtype;
    final stage = data.figoStage;

    // 分子分類・組織型に応じた免疫療法推奨を1つだけ選択
    // 癌肉腫＋dMMRの場合：KEYNOTE-868除外基準のためペムブロリズマブは推奨不可
    final immunoRec = (_isDmmr(mol) && _isCarcinosarcoma(data))
        ? _recCarcinosarcomaDmmr()
        : _isDmmr(mol)
            ? _recDmmrPembro()
            : _recPmmrDuoE(isStrongRecommend: false);

    final immunoNote = _isCarcinosarcoma(data) && _isDmmr(mol)
        ? '⚠️ 癌肉腫＋dMMR: KEYNOTE-868除外基準のためTC＋ペムブロリズマブは非適応。DUO-E doublet（Arm B）またはTC単独をMDTで検討'
        : _isDmmr(mol)
            ? 'MMRd（dMMR）のため TC＋ペムブロリズマブを優先検討'
            : _isPmmr(mol)
                ? '${mol?.shortLabel ?? "NSMP/p53abn"} は pMMR 相当 → DUO-E triplet を積極検討'
                : '分子分類不明のため MMR IHC 検査を実施してから免疫療法を判断';

    return RiskAssessmentResult(
      riskCategory: RiskCategory.high,
      rationale:
          'FIGO ${stage?.label}（リンパ節転移）は「高リスク」です。化学療法＋拡大野放射線治療が推奨されます。',
      keyFactors: [
        'FIGO ${stage?.label}（リンパ節転移）',
        '${data.histologicalType?.label}',
        '分子分類: ${mol?.shortLabel ?? "不明"}',
      ],
      primaryRecommendations: [
        const TreatmentRecommendation(
          title: 'TC 化学療法＋ 拡大野 EBRT（骨盤±傍大動脈）± VBT',
          description: 'IIIC1 は骨盤野、IIIC2 は傍大動脈野を含む拡大野照射＋化学療法が推奨。',
          strength: RecommendationStrength.strongRecommend,
          details: [
            'TC 6サイクル（sandwich法）',
            'IIIC1: 骨盤EBRT 45〜50.4Gy（IMRT）',
            'IIIC2: 骨盤＋傍大動脈野 EBRT（拡大野照射）',
            'VBT boost',
            'IMRT による隣接臓器毒性の低減が重要',
          ],
          guideline: 'ESMO 2020 / NCCN 2024',
        ),
        immunoRec,
      ],
      alternativeRecommendations: const [],
      importantNotes: _addCytologyNote(data, [
        'IIIC2（傍大動脈 LN 転移）では拡大野照射の毒性管理が重要',
        'センチネルリンパ節生検による staging の場合、郭清省略例でも同様に管理',
        immunoNote,
        'NCCN 2024: dMMR ではTC＋ペムブロリズマブを一次推奨として位置づけ',
        '化学療法終了後に PET-CT による効果判定を推奨',
      ]),
      guidelineReference: 'ESMO 2020, NCCN 2024, KEYNOTE-868 (NEJM 2023), DUO-E (JCO 2023)',
    );
  }

  // ─────────────────────────────────────────
  // Stage IVA, IVB
  // ─────────────────────────────────────────
  static RiskAssessmentResult _evaluateAdvanced(PatientData data) {
    final mol = data.molecularSubtype;
    final er = data.erStatus;

    // 分子分類・組織型に基づいて一次推奨の免疫療法を1つだけ選択
    // 癌肉腫＋dMMRの場合：KEYNOTE-868除外基準のためペムブロリズマブは推奨不可
    final immunoPrimary = (_isDmmr(mol) && _isCarcinosarcoma(data))
        ? _recCarcinosarcomaDmmr()
        : _isDmmr(mol)
            ? _recDmmrPembro()
            : _recPmmrDuoE(isStrongRecommend: true);

    final immunoNote = _isCarcinosarcoma(data) && _isDmmr(mol)
        ? '⚠️ 癌肉腫＋dMMR: KEYNOTE-868除外基準のためTC＋ペムブロリズマブは非適応。DUO-E doublet（Arm B）またはTC単独をMDTで検討'
        : _isDmmr(mol)
            ? 'MMRd（dMMR）: TC＋ペムブロリズマブが一次治療の標準（日本承認）'
            : _isPmmr(mol)
                ? '${mol?.shortLabel ?? "NSMP/p53abn"} は pMMR 相当 → DUO-E triplet を一次治療として検討'
                : '分子分類不明: MMR IHC 検査を先行実施し免疫療法の適応を判断';

    return RiskAssessmentResult(
      riskCategory: RiskCategory.advanced,
      rationale:
          'FIGO IVA/IVB（膀胱・腸管浸潤、腹膜播種、遠隔転移）は「進行期」として全身治療を主軸とした管理を行います。',
      keyFactors: [
        'FIGO ${data.figoStage?.label}（進行期）',
        '${data.histologicalType?.label}',
        '分子分類: ${mol?.shortLabel ?? "不明"}',
        'ER: ${er?.label ?? "不明"}',
      ],
      primaryRecommendations: [
        // 分子分類に応じた免疫療法（dMMR→ペムブロ / pMMR→DUO-E）を1つだけ表示
        immunoPrimary,
        const TreatmentRecommendation(
          title: 'TC 化学療法のみ（免疫療法非適応例・バックアップ）',
          description: '免疫療法・PARP阻害剤が使用できない場合のバックアップ。PS不良・重篤な合併症例。',
          strength: RecommendationStrength.recommend,
          details: [
            'TC 6サイクル（カルボプラチン AUC5 ＋ パクリタキセル 175mg/m²）',
            '3週毎投与',
            'PS 2以上の場合はカルボプラチン単剤も考慮',
          ],
          guideline: 'ESMO 2020 / NCCN 2024',
        ),
      ],
      alternativeRecommendations: [
        const TreatmentRecommendation(
          title: 'レンバチニブ＋ペムブロリズマブ（二次治療）',
          description: '一次治療後の増悪例に対する二次治療選択肢。pMMR/MSS でも有効性が確認されている（KEYNOTE-775）。日本承認済み（2022年）。',
          strength: RecommendationStrength.recommend,
          details: [
            'KEYNOTE-775試験(2021)で有効性確認（pMMR・dMMR両群）',
            'レンバチニブ 20mg/日 po ＋ ペムブロリズマブ 200mg q3w iv',
            'OS: 18.3ヶ月 vs 11.4ヶ月（化学療法単剤比、pMMR群）',
            '日本承認済み（2022年）',
          ],
          guideline: 'KEYNOTE-775 (NEJM 2021)',
        ),
        TreatmentRecommendation(
          title: 'ホルモン療法（ER陽性 低グレード例）',
          description: 'ER陽性の低グレード類内膜癌で PS 不良例などに選択肢。',
          strength: RecommendationStrength.consider,
          details: [
            'メドロキシプロゲステロン酢酸エステル（MPA）',
            'レトロゾールなどアロマターゼ阻害剤',
            '奏効率は低いが毒性が少ない',
          ],
          guideline: 'NCCN 2024',
        ),
        const TreatmentRecommendation(
          title: '放射線治療（局所緩和目的）',
          description: '骨転移・脳転移・局所出血などに対する緩和的放射線治療。',
          strength: RecommendationStrength.recommend,
          details: [
            '骨転移: 8Gy/1回 または 30Gy/10回',
            '脳転移: 全脳照射または定位放射線治療（SRS/SRT）',
            '局所出血制御目的',
          ],
          guideline: 'NCCN 2024',
        ),
      ],
      importantNotes: _addCytologyNote(data, [
        'PS（Performance Status）の評価が治療選択の前提',
        immunoNote,
        '【重要】ドスタルリマブ（RUBY試験）は日本未承認 → dMMR には TC＋ペムブロリズマブを使用',
        '【重要】癌肉腫（Carcinosarcoma）は KEYNOTE-868/NRG-GY018 の除外基準 → dMMR 癌肉腫には TC＋ペムブロリズマブは非適応',
        'NSMP・p53abn は pMMR 相当であり DUO-E triplet の対象',
        '分子検査（MMR/MSI、TMB、HER2、NTRK、BRCA など）の実施を推奨',
        '遺伝カウンセリング（Lynch症候群スクリーニング）を考慮',
        '緩和ケアチームとの早期連携を推奨',
        'FIGO IVAは手術による腫瘍減量（debulking）を考慮する場合あり',
      ]),
      guidelineReference:
          'KEYNOTE-868/NRG-GY018 (NEJM 2023), DUO-E (JCO 2023), KEYNOTE-775 (NEJM 2021), ESMO 2020, NCCN 2024',
    );
  }

  // ─────────────────────────────────────────
  // 腹水細胞診陽性注記ヘルパー
  // ─────────────────────────────────────────
  /// 腹水細胞診陽性の場合に importantNotes へ追加する注記文字列
  /// FIGO 2009/2023 でステージング基準から除外済み。
  /// IJGC 2025 (Fumagalli et al.): 予後不良因子だが治療ガイダンスには使用されない。
  static const String _cytologyNote =
      '【腹水細胞診陽性】独立した予後不良因子（IJGC 2025）。'
      'FIGO 2009・2023 いずれもステージング基準に含まれず、'
      '現行ガイドライン（ESMO 2020 / NCCN 2024）では治療変更の直接根拠とならない。'
      'フォローアップ強化・治療強化の個別検討を MDT で行うことを推奨。';

  /// 腹水細胞診陽性の場合に注記リストへ追加するヘルパー
  static List<String> _addCytologyNote(
      PatientData data, List<String> notes) {
    if (data.peritonealCytologyPositive == true) {
      return [...notes, _cytologyNote];
    }
    return notes;
  }

  // ─────────────────────────────────────────
  // MMR状態・組織型ヘルパー
  // ─────────────────────────────────────────
  /// dMMR（MMR欠損型）かどうか: MMRd のみ true
  static bool _isDmmr(MolecularSubtype? mol) =>
      mol == MolecularSubtype.mmrd;

  /// pMMR相当かどうか: NSMP / p53abn は pMMR 相当
  static bool _isPmmr(MolecularSubtype? mol) =>
      mol == MolecularSubtype.nsmp || mol == MolecularSubtype.p53abn;

  /// 癌肉腫かどうか
  static bool _isCarcinosarcoma(PatientData data) =>
      data.histologicalType == HistologicalType.carcinosarcoma;

  /// 免疫療法推奨（dMMR・非癌肉腫）の TreatmentRecommendation
  static TreatmentRecommendation _recDmmrPembro() =>
      const TreatmentRecommendation(
        title: 'dMMR/MSI-H: TC＋ペムブロリズマブ（日本標準）',
        description:
            'MMRd（dMMR/MSI-H）のため、TC＋ペムブロリズマブが推奨されます。日本ではドスタルリマブ（RUBY試験）は未承認のため、ペムブロリズマブが標準治療です。',
        strength: RecommendationStrength.strongRecommend,
        details: [
          'ペムブロリズマブ 200mg q3w ＋ TC 6コース',
          '維持: ペムブロリズマブ 400mg q6w（最大35サイクル）',
          'KEYNOTE-868/NRG-GY018(2023): dMMR群 PFS中央値 未到達 vs 7.6ヶ月',
          'OS有意改善（HR 0.30, 95%CI 0.13–0.71）',
          'MMR IHC または PCR/NGS によるMSI検査で事前確認必須',
        ],
        guideline: 'KEYNOTE-868 / NRG-GY018 (NEJM 2023)',
      );

  /// 癌肉腫+dMMRに対する注記付き推奨（ペムブロリズマブ非適応）
  static TreatmentRecommendation _recCarcinosarcomaDmmr() =>
      const TreatmentRecommendation(
        title: '癌肉腫 dMMR: DUO-E doublet（TC＋デュルバルマブ → デュルバルマブ維持）',
        description:
            '【重要】癌肉腫（Carcinosarcoma）はKEYNOTE-868/NRG-GY018試験の除外基準に該当します。'
            'dMMRであってもTC＋ペムブロリズマブは非適応のため、DUO-E doublet（Arm B）を優先検討してください。'
            'DUO-E試験では癌肉腫が7.5%組み込まれており除外されていません。',
        strength: RecommendationStrength.recommend,
        details: [
          '⚠️ 癌肉腫はNRG-GY018（NEJM 2023）の除外基準に明記 → ペムブロリズマブは非適応',
          '推奨: DUO-E doublet（Arm B）',
          '　TC 6コース ＋ デュルバルマブ 1120mg q3w（同時投与）',
          '　維持: デュルバルマブ 1500mg q4w（病勢進行または許容できない毒性まで）',
          '※ オラパリブを加えたtriplet（Arm C）はdMMR癌肉腫でのHRR欠損根拠が乏しく非推奨',
          '代替: TC 6コース単独（doubletが使用困難な場合）',
          '多職種カンファレンス（MDT）での個別検討を強く推奨',
        ],
        guideline: 'NRG-GY018 (NEJM 2023) 除外基準 / DUO-E (JCO 2023) Arm B',
      );

  /// DUO-E triplet（pMMR）の TreatmentRecommendation
  static TreatmentRecommendation _recPmmrDuoE({bool isStrongRecommend = false}) =>
      TreatmentRecommendation(
        title: 'pMMR/MSS: DUO-E triplet（TC＋デュルバルマブ → 維持療法）',
        description:
            'pMMR/MSS（NSMP・p53abn はpMMR相当）のため、DUO-E試験に基づくTC＋デュルバルマブ → デュルバルマブ＋オラパリブ維持療法が推奨されます。',
        strength: isStrongRecommend
            ? RecommendationStrength.strongRecommend
            : RecommendationStrength.recommend,
        details: const [
          'TC 6コース ＋ デュルバルマブ 1120mg q3w（同時投与）',
          '維持: デュルバルマブ 1500mg q4w ＋ オラパリブ 300mg bid（病勢進行〔PD〕または許容できない毒性まで継続）',
          'DUO-E試験(2023): triplet群 PFS HR 0.71（vs TC単独）',
          'pMMR群でもPFS改善（HR 0.84）',
          '日本での保険適用状況を事前に確認',
        ],
        guideline: 'DUO-E trial (JCO 2023)',
      );

  static RiskAssessmentResult _incompleteData() {
    return RiskAssessmentResult(
      riskCategory: RiskCategory.intermediate,
      rationale: '入力情報が不完全です。すべての必須項目を入力してください。',
      keyFactors: ['情報不足'],
      primaryRecommendations: [],
      importantNotes: ['FIGO ステージ、組織型、LVSI、分子分類をすべて入力してください'],
      guidelineReference: '',
    );
  }
}
