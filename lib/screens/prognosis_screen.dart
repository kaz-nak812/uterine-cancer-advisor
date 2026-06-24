import 'package:flutter/material.dart';
import '../models/patient_data.dart';
import '../models/prognosis_data.dart';
import '../services/prognosis_engine.dart';
import '../utils/app_theme.dart';

class PrognosisScreen extends StatelessWidget {
  final PatientData patientData;

  const PrognosisScreen({super.key, required this.patientData});

  @override
  Widget build(BuildContext context) {
    final result = PrognosisEngine.evaluate(patientData);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDisclaimerBanner(),
                    const SizedBox(height: 16),
                    _buildSummaryCard(result),
                    const SizedBox(height: 16),
                    _buildStageSurvivalCard(result.stageSurvival),
                    const SizedBox(height: 16),
                    _buildMolecularCard(result.molecularNote),
                    if (result.erNote != null) ...[
                      const SizedBox(height: 16),
                      _buildErCard(result.erNote!),
                    ],
                    const SizedBox(height: 16),
                    _buildPrognosticFactorsCard(result.prognosticFactors),
                    const SizedBox(height: 16),
                    _buildReferencesCard(result.references),
                    const SizedBox(height: 16),
                    _buildDisclaimerCard(result.disclaimer),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // ヘッダー
  // ─────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF37474F), Color(0xFF546E7A)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '予後情報（参考）',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'FIGO 2023 × 分子分類 × ER による5年生存率目安',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // 上部免責バナー（常時表示）
  // ─────────────────────────────────────────
  Widget _buildDisclaimerBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF8F00).withValues(alpha: 0.5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '統計的参考値です。個人の予後を確定するものではありません。'
              '担当医とご相談の上、治療方針をご決定ください。',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF795548),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // 総合サマリーカード
  // ─────────────────────────────────────────
  Widget _buildSummaryCard(PrognosisResult result) {
    return _SectionCard(
      icon: Icons.summarize_outlined,
      title: '総合サマリー',
      color: const Color(0xFF37474F),
      child: Text(
        result.summaryText,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF2C3E50),
          height: 1.7,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // ステージ別5年OS カード（メインの数値）
  // ─────────────────────────────────────────
  Widget _buildStageSurvivalCard(StageSurvivalData sd) {
    return _SectionCard(
      icon: Icons.bar_chart_rounded,
      title: 'ステージ別5年生存率（FIGO 2023）',
      color: AppTheme.primaryBlue,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SurvivalGauge(
                  label: '5年OS\n（全生存率）',
                  value: sd.os5yr,
                  color: _osColor(sd.os5yr),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SurvivalGauge(
                  label: '5年PFS\n（無増悪生存率）',
                  value: sd.pfs5yr,
                  color: _osColor(sd.pfs5yr),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ConfidenceBadge(confidence: sd.confidence),
          const SizedBox(height: 6),
          Text(
            'データ出典: ${sd.source}',
            style: const TextStyle(fontSize: 10, color: Color(0xFF90A4AE)),
          ),
        ],
      ),
    );
  }

  Color _osColor(double? val) {
    if (val == null) return Colors.grey;
    if (val >= 0.90) return const Color(0xFF2E7D32);
    if (val >= 0.70) return const Color(0xFF0277BD);
    if (val >= 0.50) return const Color(0xFFF57F17);
    return const Color(0xFFC62828);
  }

  // ─────────────────────────────────────────
  // 分子分類補正カード
  // ─────────────────────────────────────────
  Widget _buildMolecularCard(MolecularPrognosisNote note) {
    final color = _molColor(note.color);
    return _SectionCard(
      icon: Icons.science_outlined,
      title: '分子分類による予後補正',
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    note.subtype,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.headline,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (note.os5yrOverall != null) ...[
            Row(
              children: [
                const Text(
                  '分子分類全体 5年OS目安: ',
                  style: TextStyle(fontSize: 12, color: Color(0xFF546E7A)),
                ),
                Text(
                  '${(note.os5yrOverall! * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _osColor(note.os5yrOverall),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Text(
            note.detail,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF546E7A),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Color _molColor(String key) {
    switch (key) {
      case 'green': return const Color(0xFF2E7D32);
      case 'blue': return const Color(0xFF0277BD);
      case 'red': return const Color(0xFFC62828);
      case 'slate': return const Color(0xFF546E7A);
      default: return const Color(0xFF78909C);
    }
  }

  // ─────────────────────────────────────────
  // ER補正カード（NSMPのみ有効）
  // ─────────────────────────────────────────
  Widget _buildErCard(ErPrognosisNote erNote) {
    final isApplicable = erNote.isApplicable;
    final cardColor = isApplicable
        ? (erNote.os10yrNsmp != null && erNote.os10yrNsmp! >= 0.7
            ? const Color(0xFF1B5E20)
            : const Color(0xFFB71C1C))
        : const Color(0xFF546E7A);

    return _SectionCard(
      icon: Icons.biotech_outlined,
      title: 'ER（エストロゲン受容体）補正',
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isApplicable
                  ? cardColor.withValues(alpha: 0.06)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              erNote.impact,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isApplicable ? cardColor : const Color(0xFF78909C),
                height: 1.5,
              ),
            ),
          ),
          if (isApplicable &&
              erNote.os10yrNsmp != null &&
              erNote.pfs5yrNsmp != null) ...[
            const SizedBox(height: 12),
            const Text(
              'NSMP内でのER別予後データ（Vermij et al. 2023）',
              style: TextStyle(fontSize: 11, color: Color(0xFF78909C)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SurvivalGauge(
                    label: '10年OS\n（NSMP内）',
                    value: erNote.os10yrNsmp,
                    color: _osColor(erNote.os10yrNsmp),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SurvivalGauge(
                    label: '5年PFS\n（NSMP内）',
                    value: erNote.pfs5yrNsmp,
                    color: _osColor(erNote.pfs5yrNsmp),
                  ),
                ),
              ],
            ),
          ],
          if (!isApplicable) ...[
            const SizedBox(height: 6),
            const Text(
              '※ この分子分類ではER発現率による有意な予後差は認められません',
              style: TextStyle(fontSize: 11, color: Color(0xFF90A4AE)),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // 予後因子カード
  // ─────────────────────────────────────────
  Widget _buildPrognosticFactorsCard(List<String> factors) {
    return _SectionCard(
      icon: Icons.checklist_outlined,
      title: '本症例の予後因子',
      color: const Color(0xFF4A148C),
      child: Column(
        children: factors.map((f) {
          final isGood = f.startsWith('✅');
          final isWarn = f.startsWith('⚠️');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isGood
                        ? const Color(0xFF2E7D32)
                        : isWarn
                            ? const Color(0xFFE65100)
                            : const Color(0xFF78909C),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 13,
                      color: isGood
                          ? const Color(0xFF2E7D32)
                          : isWarn
                              ? const Color(0xFF4E342E)
                              : const Color(0xFF546E7A),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────
  // 参考文献カード
  // ─────────────────────────────────────────
  Widget _buildReferencesCard(List<String> refs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_outlined, size: 16, color: Color(0xFF546E7A)),
              SizedBox(width: 6),
              Text(
                '参考文献・データソース',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF546E7A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...refs.map((ref) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  ref,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF78909C),
                    height: 1.5,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // 詳細免責カード（ページ末）
  // ─────────────────────────────────────────
  Widget _buildDisclaimerCard(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBE9E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF8A65).withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gavel_outlined, size: 16, color: Color(0xFFBF360C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF795548),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 共通ウィジェット
// ─────────────────────────────────────────

/// セクションカード（ヘッダー付き）
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const _SectionCard({
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
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

/// 生存率ゲージ（円形プログレス付き）
class _SurvivalGauge extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;

  const _SurvivalGauge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = value != null ? (value! * 100).toStringAsFixed(0) : 'N/A';
    final displayValue = value ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: displayValue,
                  strokeWidth: 7,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value != null ? '$pct%' : 'N/A',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF546E7A),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 信頼度バッジ
class _ConfidenceBadge extends StatelessWidget {
  final PrognosisConfidence confidence;

  const _ConfidenceBadge({required this.confidence});

  Color get _color {
    switch (confidence) {
      case PrognosisConfidence.high: return const Color(0xFF2E7D32);
      case PrognosisConfidence.moderate: return const Color(0xFF0277BD);
      case PrognosisConfidence.low: return const Color(0xFFE65100);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.data_usage, size: 11, color: _color),
              const SizedBox(width: 4),
              Text(
                'エビデンス信頼度: ${confidence.label}（${confidence.description}）',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
