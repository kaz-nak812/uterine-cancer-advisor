// 予後判定エンジン
// データソース: PMC 2025 (J Cancer, Zhejiang大学720例) / KAKEN / Vermij Br J Cancer 2023
import '../models/patient_data.dart';
import '../models/prognosis_data.dart';

class PrognosisEngine {
  /// メイン判定: PatientData → PrognosisResult
  static PrognosisResult evaluate(PatientData data) {
    final stageSurvival = _getStageSurvival(data.figoStage);
    final molecularNote = _getMolecularNote(data.molecularSubtype);
    final erNote = _getErNote(data);
    final factors = _getPrognosticFactors(data);
    final summary = _buildSummary(data, stageSurvival, molecularNote, erNote);

    return PrognosisResult(
      stageSurvival: stageSurvival,
      molecularNote: molecularNote,
      erNote: erNote,
      prognosticFactors: factors,
      summaryText: summary,
      disclaimer: _disclaimer,
      references: _references,
    );
  }

  // ─────────────────────────────────────────────
  // ステージ別5年生存率テーブル
  // 出典: J Cancer 2025 (PMC12664729), Zhejiang大学720例
  // ─────────────────────────────────────────────
  static StageSurvivalData _getStageSurvival(FigoStage? stage) {
    switch (stage) {
      case FigoStage.ia:
        return const StageSurvivalData(
          stageLabel: 'IA',
          os5yr: 0.990,
          pfs5yr: 0.955,
          confidence: PrognosisConfidence.high,
          source: 'J Cancer 2025 (n=720)',
        );
      case FigoStage.ib:
        return const StageSurvivalData(
          stageLabel: 'IB',
          os5yr: 1.000,
          pfs5yr: 0.964,
          confidence: PrognosisConfidence.moderate,
          source: 'J Cancer 2025 (n=720)',
        );
      case FigoStage.ic:
        return const StageSurvivalData(
          stageLabel: 'IC',
          os5yr: 0.923,
          pfs5yr: 0.846,
          confidence: PrognosisConfidence.moderate,
          source: 'J Cancer 2025 (n=720)',
        );
      case FigoStage.iia:
        return const StageSurvivalData(
          stageLabel: 'IIA',
          os5yr: 1.000,
          pfs5yr: 0.955,
          confidence: PrognosisConfidence.moderate,
          source: 'J Cancer 2025 (n=720)',
        );
      case FigoStage.iib:
        return const StageSurvivalData(
          stageLabel: 'IIB',
          os5yr: 1.000,
          pfs5yr: 0.800,
          confidence: PrognosisConfidence.low,
          source: 'J Cancer 2025 (n=720, 少数例)',
        );
      case FigoStage.iiia:
        return const StageSurvivalData(
          stageLabel: 'IIIA',
          os5yr: 0.700,
          pfs5yr: 0.550,
          confidence: PrognosisConfidence.moderate,
          source: 'J Cancer 2025 / ESMO 2020統合',
        );
      case FigoStage.iiib:
        return const StageSurvivalData(
          stageLabel: 'IIIB',
          os5yr: 0.667,
          pfs5yr: 0.667,
          confidence: PrognosisConfidence.low,
          source: 'J Cancer 2025 (少数例)',
        );
      case FigoStage.iiic1:
        return const StageSurvivalData(
          stageLabel: 'IIIC1',
          os5yr: 0.700,
          pfs5yr: 0.600,
          confidence: PrognosisConfidence.moderate,
          source: 'J Cancer 2025 (micro/macromet合算)',
        );
      case FigoStage.iiic2:
        return const StageSurvivalData(
          stageLabel: 'IIIC2',
          os5yr: 0.467,
          pfs5yr: 0.400,
          confidence: PrognosisConfidence.moderate,
          source: 'J Cancer 2025 (n=720)',
        );
      case FigoStage.iva:
        return const StageSurvivalData(
          stageLabel: 'IVA',
          os5yr: 0.200,
          pfs5yr: 0.200,
          confidence: PrognosisConfidence.moderate,
          source: 'J Cancer 2025 / ESMO 2020',
        );
      case FigoStage.ivb:
        return const StageSurvivalData(
          stageLabel: 'IVB',
          os5yr: 0.200,
          pfs5yr: 0.200,
          confidence: PrognosisConfidence.moderate,
          source: 'J Cancer 2025 (n=720)',
        );
      case null:
        return const StageSurvivalData(
          stageLabel: '不明',
          confidence: PrognosisConfidence.low,
          source: 'データなし',
        );
    }
  }

  // ─────────────────────────────────────────────
  // 分子分類別予後コメント
  // 出典: J Cancer 2025 + KAKEN日本データ
  // ─────────────────────────────────────────────
  static MolecularPrognosisNote _getMolecularNote(MolecularSubtype? mol) {
    switch (mol) {
      case MolecularSubtype.poleMutated:
        return const MolecularPrognosisNote(
          subtype: 'POLEmut',
          headline: '最良予後サブタイプ — ステージにかかわらず5年OS 100%',
          detail:
              'POLE exonuclease domain変異型は、ステージIII/IVであっても'
              '5年OS 100%が報告されています（J Cancer 2025, n=74例）。'
              'ステージ単独の数値よりも大幅に良好な予後が期待されます。'
              '\nPORTEC-2試験でも10年再発率 0% vs 野生型80.1%と報告。',
          os5yrOverall: 1.00,
          color: 'green',
        );
      case MolecularSubtype.mmrd:
        return const MolecularPrognosisNote(
          subtype: 'MMRd',
          headline: '中間〜良好予後 — 5年OS 約75〜85%（ステージI/II中心）',
          detail:
              'MMR欠損型（dMMR/MSI-H）は中間予後サブタイプです。'
              'ステージI/IIでは5年OS 75〜85%程度が報告されています。'
              '\nKAKEN日本データ（ProMisE）: 5年OS 85.1%。'
              '\n免疫チェックポイント阻害剤（ペムブロリズマブ）の奏効率が高く、'
              '近年の免疫療法により予後改善が期待されます。',
          os5yrOverall: 0.85,
          color: 'blue',
        );
      case MolecularSubtype.p53abn:
        return const MolecularPrognosisNote(
          subtype: 'p53abn',
          headline: '最不良予後サブタイプ — ステージに関係なく予後不良',
          detail:
              'p53異常型は最も予後不良の分子分類です。'
              '5年OS 32〜74%（ステージ依存）、5年PFS 72.8%（全ステージ）。'
              '\nKAKEN日本データ（ProMisE）: 5年OS 42.9%。'
              '\n早期ステージでもステージのみの予後推定より不良となります。'
              '\n漿液性癌の90%以上でp53abnを伴います。',
          os5yrOverall: 0.60,
          color: 'red',
        );
      case MolecularSubtype.nsmp:
        return const MolecularPrognosisNote(
          subtype: 'NSMP',
          headline: '中間予後 — ER発現率で大きく2分される',
          detail:
              'NSMPは中間予後サブタイプですが、ER発現率により大きく層別化されます。'
              '\n【ER高発現 ≥10%】: 5年PFS 88.5%, 10年OS 79.5%（良好）'
              '\n【ER低発現/陰性 <10%】: 5年PFS 28.6%, 10年OS 24.9%（p53abnに匹敵する不良予後）'
              '\nKAKEN日本データ（ProMisE）: NSMP全体の5年OS 65.5%。'
              '\nER入力がある場合は下記「ER補正情報」も参照してください。',
          os5yrOverall: 0.74,
          color: 'slate',
        );
      case null:
        return const MolecularPrognosisNote(
          subtype: '不明',
          headline: '分子分類未入力のため補正不可',
          detail: '分子分類が不明のため、ステージ単独の参考値のみ表示しています。'
              '\nMMR IHC（MLH1/PMS2/MSH2/MSH6）またはNGSによる分子分類の実施を推奨します。',
          color: 'grey',
        );
    }
  }

  // ─────────────────────────────────────────────
  // ER補正情報（NSMPのみ有意）
  // 出典: Vermij et al. Br J Cancer 2023 / Gynecol Oncol 2025
  // ─────────────────────────────────────────────
  static ErPrognosisNote? _getErNote(PatientData data) {
    final mol = data.molecularSubtype;
    final er = data.erStatus;
    if (er == null || er == ErStatus.unknown) return null;

    // POLEmut / MMRd: 全例ER陽性で予後差なし → 補正不要
    if (mol == MolecularSubtype.poleMutated || mol == MolecularSubtype.mmrd) {
      return ErPrognosisNote(
        erLabel: er.label,
        impact: 'POLEmut/MMRdではER状態による予後差なし（全例ほぼER陽性）',
        isApplicable: false,
      );
    }

    // p53abn: ER陽性/陰性で予後差なし（p53変異が支配的）
    if (mol == MolecularSubtype.p53abn) {
      return ErPrognosisNote(
        erLabel: er.label,
        impact: 'p53abnではER状態による予後差なし（p53変異の影響が支配的）',
        isApplicable: false,
      );
    }

    // NSMP: ER発現率で大きく予後が分かれる（≥10% vs <10%）
    if (mol == MolecularSubtype.nsmp) {
      if (er.isHighForPrognosis) {
        return const ErPrognosisNote(
          erLabel: 'ER高発現（≥10%）',
          impact: '【良好サブタイプ】NSMP ER高発現は予後良好群に分類されます。',
          os10yrNsmp: 0.795,
          pfs5yrNsmp: 0.885,
          isApplicable: true,
        );
      } else if (er == ErStatus.lowPositive) {
        return const ErPrognosisNote(
          erLabel: 'ER低発現（1〜9%）',
          impact: '【注意】ER <10%のNSMPは予後不良サブタイプに該当します。p53abnに匹敵する不良予後の可能性があります。',
          os10yrNsmp: 0.249,
          pfs5yrNsmp: 0.286,
          isApplicable: true,
        );
      } else {
        // ER陰性
        return const ErPrognosisNote(
          erLabel: 'ER陰性（<1%）',
          impact: '【注意】ER陰性NSMPは予後不良サブタイプです。p53abnに匹敵する不良予後が報告されています。',
          os10yrNsmp: 0.249,
          pfs5yrNsmp: 0.286,
          isApplicable: true,
        );
      }
    }

    // 分子分類不明でもER情報は表示
    return ErPrognosisNote(
      erLabel: er.label,
      impact: '分子分類が不明のためER補正の適用可否が判断できません。',
      isApplicable: false,
    );
  }

  // ─────────────────────────────────────────────
  // 予後因子リスト生成
  // ─────────────────────────────────────────────
  static List<String> _getPrognosticFactors(PatientData data) {
    final factors = <String>[];

    // 良好因子
    if (data.molecularSubtype == MolecularSubtype.poleMutated) {
      factors.add('✅ POLEmut: 最良予後（ステージ問わず）');
    }
    if (data.erStatus?.isHighForPrognosis == true &&
        data.molecularSubtype == MolecularSubtype.nsmp) {
      factors.add('✅ NSMP ER高発現（≥10%）: 予後良好サブタイプ');
    }
    if (data.molecularSubtype == MolecularSubtype.mmrd) {
      factors.add('✅ MMRd: 免疫療法（ペムブロリズマブ）の高い奏効率');
    }
    if (data.lvsiStatus == LvsiStatus.absent) {
      factors.add('✅ LVSI陰性: リンパ節転移リスク低');
    }

    // 不良因子
    if (data.molecularSubtype == MolecularSubtype.p53abn) {
      factors.add('⚠️ p53abn: 最不良予後サブタイプ（早期でも注意）');
    }
    if (data.molecularSubtype == MolecularSubtype.nsmp &&
        data.erStatus != null &&
        data.erStatus != ErStatus.unknown &&
        !data.erStatus!.isHighForPrognosis) {
      factors.add('⚠️ NSMP ER低発現/陰性（<10%）: p53abnに匹敵する不良予後');
    }
    if (data.lvsiStatus == LvsiStatus.substantial) {
      factors.add('⚠️ LVSI substantial: リンパ節転移リスク上昇');
    }
    if (data.histologicalType?.isHighRiskHistology == true) {
      factors.add('⚠️ 高リスク組織型（${data.histologicalType?.label}）: 腹膜播種リスク');
    }
    if (data.peritonealCytologyPositive == true) {
      factors.add('⚠️ 腹水細胞診陽性: 死亡リスク 6.2倍（Cox多変量解析）');
    }
    if (data.myometrialInvasionDeep == true) {
      factors.add('⚠️ 深部筋層浸潤（≥50%）: 死亡リスク 4.8倍（Cox多変量解析）');
    }
    if ([FigoStage.iiia, FigoStage.iiib, FigoStage.iiic1,
         FigoStage.iiic2, FigoStage.iva, FigoStage.ivb]
        .contains(data.figoStage)) {
      factors.add('⚠️ Stage III/IV: 全身治療が主軸');
    }

    if (factors.isEmpty) {
      factors.add('判定に使用できる因子が十分ではありません');
    }
    return factors;
  }

  // ─────────────────────────────────────────────
  // 総合サマリー文生成
  // ─────────────────────────────────────────────
  static String _buildSummary(
    PatientData data,
    StageSurvivalData stage,
    MolecularPrognosisNote mol,
    ErPrognosisNote? er,
  ) {
    final sb = StringBuffer();
    final stageLabel = data.figoStage?.label ?? '不明';
    final molLabel = data.molecularSubtype?.shortLabel ?? '不明';

    sb.write('FIGO $stageLabel・$molLabel の組み合わせでは、');

    if (stage.os5yr != null) {
      final pct = (stage.os5yr! * 100).toStringAsFixed(0);
      sb.write('ステージ単独の5年OS参考値は約$pct%です。');
    } else {
      sb.write('ステージ単独の5年OSデータは限られています。');
    }

    // 分子分類補正
    switch (data.molecularSubtype) {
      case MolecularSubtype.poleMutated:
        sb.write('\nPOLEmut のためステージにかかわらず5年OS 100%が期待されます。');
      case MolecularSubtype.p53abn:
        sb.write('\np53abn のため、ステージ単独の値より予後不良となる可能性があります。');
      case MolecularSubtype.mmrd:
        sb.write('\nMMRd では免疫療法（ペムブロリズマブ）による予後改善が期待されます。');
      case MolecularSubtype.nsmp:
        if (er != null && er.isApplicable) {
          if (data.erStatus?.isHighForPrognosis == true) {
            sb.write('\nNSMP ER高発現（≥10%）のため、NSMPの中でも予後良好サブタイプに分類されます。');
          } else {
            sb.write('\nNSMP ER低発現/陰性（<10%）のため、p53abnに近い予後不良サブタイプに分類されます。積極的な治療と密なフォローアップを推奨します。');
          }
        } else {
          sb.write('\nNSMP ではER発現率（≥10%/未満）の確認により予後が大きく変わります。');
        }
      case null:
        sb.write('\n分子分類が不明のため補正はできません。分子分類の実施を推奨します。');
    }

    return sb.toString();
  }

  // ─────────────────────────────────────────────
  // 免責注記・参考文献
  // ─────────────────────────────────────────────
  static const String _disclaimer =
      '⚠️【重要な免責事項】\n'
      'この予後情報は集団研究データに基づく統計的参考値です。'
      '個人の5年生存率を確定するものではありません。'
      '実際の予後は術後補助療法の実施・施設・患者背景（年齢・PS・合併症）'
      'により大きく異なります。本情報は臨床判断の補助を目的とし、'
      '最終的な治療方針は担当医との十分な話し合いのもと決定してください。';

  static const List<String> _references = [
    '① J Cancer 2025; PMC12664729. "2023 FIGO Staging of Endometrial Cancer with Molecular Classification" (Zhejiang大学, n=720)',
    '② KAKEN研究報告書 (22K16891). ProMisE分類別5年生存率（日本人コホート）',
    '③ Vermij L et al. Br J Cancer 2023; 128:1360-1368. "Prognostic refinement of NSMP high-risk endometrial cancers using oestrogen receptor immunohistochemistry"',
    '④ Gynecol Oncol 2025. "The prognostic potential of molecular subtypes including estrogen receptor status"',
    '⑤ FIGO Staging of Endometrial Cancer 2023. Berek JS et al. J Gynecol Oncol 2023',
  ];
}
