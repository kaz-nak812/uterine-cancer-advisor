import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class GuidelineInfoScreen extends StatelessWidget {
  const GuidelineInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('ガイドライン・参考文献', style: TextStyle(fontSize: 16)),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDisclaimerCard(),
              const SizedBox(height: 16),
              _buildGuidelineSection(),
              const SizedBox(height: 16),
              _buildMolecularClassification(),
              const SizedBox(height: 16),
              _buildRiskClassificationTable(),
              const SizedBox(height: 16),
              _buildKeyTrials(),
              const SizedBox(height: 16),
              _buildReferences(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB300)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel, color: Color(0xFFFF8F00), size: 18),
              SizedBox(width: 8),
              Text(
                '免責事項',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'このアプリは医療従事者が参考にするための情報提供ツールです。本アプリの情報はいかなる場合においても医師による診断・治療の代替となるものではありません。最終的な医療上の判断は医師の責任において行ってください。ガイドラインは定期的に改訂されるため、最新版を必ずご確認ください。',
            style: TextStyle(fontSize: 12, color: Color(0xFF5D4037), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineSection() {
    final guidelines = [
      _GuidelineItem(
        name: 'ESMO Clinical Practice Guidelines 2020',
        fullName: 'European Society for Medical Oncology',
        detail: 'Endometrial cancer: ESMO Clinical Practice Guidelines for diagnosis, treatment and follow-up',
        year: '2020',
        color: const Color(0xFF1565C0),
      ),
      _GuidelineItem(
        name: 'ESGO-ESTRO-ESP Guidelines 2021',
        fullName: 'European Society of Gynaecological Oncology / European SocieTy for Radiotherapy and Oncology / European Society of Pathology',
        detail: 'European recommendations on endometrial cancer diagnosis and treatment',
        year: '2021',
        color: const Color(0xFF00695C),
      ),
      _GuidelineItem(
        name: 'NCCN Guidelines v4.2024',
        fullName: 'National Comprehensive Cancer Network',
        detail: 'Uterine Neoplasms - Clinical Practice Guidelines in Oncology',
        year: '2024',
        color: const Color(0xFF4A148C),
      ),
    ];

    return _InfoCard(
      icon: Icons.menu_book,
      title: '準拠ガイドライン',
      color: AppTheme.primaryBlue,
      child: Column(
        children: guidelines.map((g) => _GuidelineItemWidget(item: g)).toList(),
      ),
    );
  }

  Widget _buildMolecularClassification() {
    return _InfoCard(
      icon: Icons.science,
      title: '分子分類（ProMisE / TCGA分類）',
      color: const Color(0xFF6A1B9A),
      child: Column(
        children: [
          _MolecularRow(
            label: 'POLEmut',
            fullLabel: 'POLE変異型',
            color: const Color(0xFF2E7D32),
            description: 'POLE exonuclease domain変異。超高頻度変異型。予後最良。',
            prognosis: '最良予後',
            frequency: '〜10%',
          ),
          const Divider(height: 16),
          _MolecularRow(
            label: 'MMRd',
            fullLabel: 'MMR欠損型',
            color: const Color(0xFF0277BD),
            description: 'MLH1/MSH2/MSH6/PMS2欠損（IHC）またはMSI-H（PCR/NGS）。Lynch症候群と関連。',
            prognosis: '中間',
            frequency: '〜30%',
          ),
          const Divider(height: 16),
          _MolecularRow(
            label: 'p53abn',
            fullLabel: 'p53異常型',
            color: const Color(0xFFC62828),
            description: 'p53 IHC異常発現（過剰発現または完全欠失）またはTP53体細胞変異。漿液性癌の90%以上。',
            prognosis: '最悪予後',
            frequency: '〜15%',
          ),
          const Divider(height: 16),
          _MolecularRow(
            label: 'NSMP',
            fullLabel: '特異的分子プロファイルなし',
            color: const Color(0xFF546E7A),
            description: '上記3分類のいずれにも当てはまらない。最も頻度が高い。',
            prognosis: '中間〜',
            frequency: '〜50%',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '優先順位: POLEmut > p53abn > MMRd > NSMP\n（複数陽性の場合は優先順位の高い分類を選択）',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6A1B9A),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskClassificationTable() {
    return _InfoCard(
      icon: Icons.table_chart,
      title: 'リスク分類 概要',
      color: const Color(0xFF1B5E20),
      child: Column(
        children: [
          _RiskRow(label: '低リスク', englishLabel: 'Low Risk', color: AppTheme.riskLow,
            description: 'IA G1/G2 類内膜癌、LVSI なし/focal\n（POLEmut は stage 問わず原則低リスク）'),
          _RiskRow(label: '低-中間リスク', englishLabel: 'Low-Intermediate', color: AppTheme.riskLowInt,
            description: 'IA G1/G2 LVSI substantial、またはIB G1/G2 LVSI なし/focal'),
          _RiskRow(label: '中間リスク', englishLabel: 'Intermediate Risk', color: AppTheme.riskIntermediate,
            description: 'IA G3 類内膜癌（LVSI なし）'),
          _RiskRow(label: '高-中間リスク', englishLabel: 'High-Intermediate', color: AppTheme.riskHighInt,
            description: 'IB G1/G2 LVSI substantial、IB G3、IC'),
          _RiskRow(label: '高リスク', englishLabel: 'High Risk', color: AppTheme.riskHigh,
            description: '高リスク組織型（漿液性・明細胞・癌肉腫など）、\nStage II〜III、p53abn'),
          _RiskRow(label: '進行・転移', englishLabel: 'Advanced/Metastatic', color: AppTheme.riskAdvanced,
            description: 'Stage IVA/IVB、遠隔転移'),
        ],
      ),
    );
  }

  Widget _buildKeyTrials() {
    final trials = [
      _TrialItem(
        name: 'PORTEC-1試験',
        year: '2000',
        detail: 'Stage I 子宮体癌における骨盤EBRT vs 経過観察。EBRT で局所制御は改善するが全生存に差なし。',
        journal: 'Lancet 2000',
      ),
      _TrialItem(
        name: 'PORTEC-2試験',
        year: '2010',
        detail: 'VBT vs EBRT（骨盤照射）。局所制御率は同等でVBTは毒性が低い。VBTが標準治療となる根拠。',
        journal: 'Lancet 2010',
      ),
      _TrialItem(
        name: 'PORTEC-3試験',
        year: '2018/2022',
        detail: 'Stage I-III 高リスク群への化学放射線療法（CRT: TC + EBRT）vs EBRT単独。CRTでPFS・OS改善（高リスク群で特に有効）。',
        journal: 'Lancet Oncol 2018/2022',
      ),
      _TrialItem(
        name: 'KEYNOTE-868 / NRG-GY018試験',
        year: '2023',
        detail: 'ペムブロリズマブ＋TC vs TC単独（進行再発子宮体癌一次治療）。dMMR群でPFS中央値 未到達 vs 7.6ヶ月（HR 0.30）、OSも有意改嚄。日本でドスタルリマブが未承認のため、日本標準治療として位置づけ。',
        journal: 'NEJM 2023',
      ),
      _TrialItem(
        name: 'DUO-E試験',
        year: '2023',
        detail: 'TC＋デュルバルマブ → デュルバルマブ＋オラパリブ維持 vs TC単独（進行再発子宮体癌）。triplet群でPFS HR 0.71、pMMR群でもHR 0.84。日本のpMMR譜への主要選択肢。',
        journal: 'JCO 2023',
      ),
      _TrialItem(
        name: 'RUBY試験',
        year: '2023',
        detail: 'ドスタルリマブ＋TC vs TC単独。dMMR群で劇的なPFS/OS改善。【注意】ドスタルリマブは日本未承認のため、日本では KEYNOTE-868 に基づく TC＋ペムブロリズマブを使用。',
        journal: 'NEJM 2023',
      ),
      _TrialItem(
        name: 'KEYNOTE-775試験',
        year: '2021',
        detail: 'レンバチニブ＋ペムブロリズマブ vs 単剤化学療法（二次治療）。pMMR/MSS群でOS 18.3ヶ月 vs 11.4ヶ月。日本承認済み（2022年）。主に二次治療以降で使用。',
        journal: 'NEJM 2021',
      ),
    ];

    return _InfoCard(
      icon: Icons.science_outlined,
      title: '主要エビデンス（臨床試験）',
      color: const Color(0xFF00695C),
      child: Column(
        children: trials.map((t) => _TrialItemWidget(item: t)).toList(),
      ),
    );
  }

  Widget _buildReferences() {
    return _InfoCard(
      icon: Icons.library_books,
      title: '参考文献',
      color: const Color(0xFF37474F),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReferenceText(
            '1. Concin N, et al. ESGO/ESTRO/ESP guidelines for the management of patients with endometrial carcinoma. Int J Gynecol Cancer. 2021;31(1):12-39.',
          ),
          _ReferenceText(
            '2. Colombo N, et al. ESMO-ESGO-ESTRO consensus conference on endometrial cancer. Ann Oncol. 2016;27(1):16-41.',
          ),
          _ReferenceText(
            '3. NCCN Clinical Practice Guidelines in Oncology: Uterine Neoplasms v4.2024.',
          ),
          _ReferenceText(
            '4. de Boer SM, et al. Adjuvant chemoradiotherapy versus radiotherapy alone for women with high-risk endometrial cancer (PORTEC-3). Lancet Oncol. 2018;19(3):295-309.',
          ),
          _ReferenceText(
            '5. Nout RA, et al. Vaginal brachytherapy versus pelvic external beam radiotherapy for patients with endometrial cancer of high-intermediate risk (PORTEC-2). Lancet. 2010;375(9717):816-823.',
          ),
          _ReferenceText(
            '6. Eskander RN, et al. Pembrolizumab plus Chemotherapy in Advanced Endometrial Cancer (NRG-GY018). NEJM. 2023;388(23):2159-2170.',
          ),
          _ReferenceText(
            '7. Mirza MR, et al. Dostarlimab for Primary Advanced or Recurrent Endometrial Cancer (RUBY trial). NEJM. 2023;388(23):2145-2158. ※日本未承認',
          ),
          _ReferenceText(
            '8. Westin SN, et al. Durvalumab plus Olaparib as Maintenance Therapy for Advanced Endometrial Cancer (DUO-E). JCO. 2023;41(22):3808-3819.',
          ),
          _ReferenceText(
            '9. Makker V, et al. Lenvatinib plus Pembrolizumab for Advanced Endometrial Cancer (KEYNOTE-775). NEJM. 2022;386(5):437-448.',
          ),
          _ReferenceText(
            '10. Vermij L, et al. FIGO 2023 staging for endometrial cancer. Histopathology. 2023;84(2):259-262.',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────
// 共通ウィジェット
// ─────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _GuidelineItem {
  final String name;
  final String fullName;
  final String detail;
  final String year;
  final Color color;

  const _GuidelineItem({
    required this.name,
    required this.fullName,
    required this.detail,
    required this.year,
    required this.color,
  });
}

class _GuidelineItemWidget extends StatelessWidget {
  final _GuidelineItem item;
  const _GuidelineItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: item.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.year,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: item.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.detail,
            style: const TextStyle(fontSize: 11, color: Color(0xFF546E7A), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _MolecularRow extends StatelessWidget {
  final String label;
  final String fullLabel;
  final Color color;
  final String description;
  final String prognosis;
  final String frequency;

  const _MolecularRow({
    required this.label,
    required this.fullLabel,
    required this.color,
    required this.description,
    required this.prognosis,
    required this.frequency,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    fullLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      frequency,
                      style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '予後: $prognosis',
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 11, color: Color(0xFF546E7A), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RiskRow extends StatelessWidget {
  final String label;
  final String englishLabel;
  final Color color;
  final String description;

  const _RiskRow({
    required this.label,
    required this.englishLabel,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($englishLabel)',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF90A4AE)),
                    ),
                  ],
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF546E7A), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrialItem {
  final String name;
  final String year;
  final String detail;
  final String journal;

  const _TrialItem({
    required this.name,
    required this.year,
    required this.detail,
    required this.journal,
  });
}

class _TrialItemWidget extends StatelessWidget {
  final _TrialItem item;
  const _TrialItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const Spacer(),
              Text(
                item.journal,
                style: const TextStyle(fontSize: 10, color: Color(0xFF546E7A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.detail,
            style: const TextStyle(fontSize: 11, color: Color(0xFF2C3E50), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ReferenceText extends StatelessWidget {
  final String text;
  const _ReferenceText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF546E7A),
          height: 1.5,
        ),
      ),
    );
  }
}
