import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient_data.dart';
import '../models/risk_assessment.dart';
import '../services/app_state.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import 'prognosis_screen.dart';
import 'wizard_screen.dart';

class ResultScreen extends StatelessWidget {
  final RiskAssessmentResult result;
  final PatientData patientData;

  const ResultScreen({
    super.key,
    required this.result,
    required this.patientData,
  });

  Color get _riskColor => AppTheme.getRiskColor(result.riskCategory.colorValue);

  @override
  Widget build(BuildContext context) {
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
                    _buildRiskCard(),
                    const SizedBox(height: 16),
                    _buildKeyFactors(),
                    const SizedBox(height: 16),
                    _buildRationale(),
                    const SizedBox(height: 16),
                    _buildPrimaryRecommendations(),
                    if (result.alternativeRecommendations.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildAlternativeRecommendations(),
                    ],
                    const SizedBox(height: 16),
                    _buildImportantNotes(),
                    const SizedBox(height: 16),
                    _buildGuidelineReference(),
                    const SizedBox(height: 24),
                    _buildActionButtons(context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _riskColor.withValues(alpha: 0.9),
            _riskColor,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'リスク判定結果',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildRiskCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _riskColor.withValues(alpha: 0.1),
            _riskColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _riskColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _riskColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.assessment, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'ESMO/NCCN リスク分類',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            result.riskCategory.label,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _riskColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            result.riskCategory.englishLabel,
            style: TextStyle(
              fontSize: 14,
              color: _riskColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildKeyFactors() {
    return _SectionCard(
      icon: Icons.list_alt_outlined,
      title: '判定に使用した主要因子',
      color: AppTheme.primaryBlue,
      child: Column(
        children: result.keyFactors.map((factor) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    factor,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF2C3E50)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRationale() {
    return _SectionCard(
      icon: Icons.lightbulb_outline,
      title: '判定根拠',
      color: const Color(0xFF0277BD),
      child: Text(
        result.rationale,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF2C3E50),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildPrimaryRecommendations() {
    if (result.primaryRecommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.star, color: AppTheme.primaryBlue, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              '推奨治療',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...result.primaryRecommendations.map(
          (rec) => _RecommendationCard(rec: rec, isPrimary: true),
        ),
      ],
    );
  }

  Widget _buildAlternativeRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00838F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.swap_horiz, color: Color(0xFF00838F), size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              '代替・考慮可能な治療',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...result.alternativeRecommendations.map(
          (rec) => _RecommendationCard(rec: rec, isPrimary: false),
        ),
      ],
    );
  }

  Widget _buildImportantNotes() {
    return _SectionCard(
      icon: Icons.warning_amber_outlined,
      title: '重要事項・注意点',
      color: const Color(0xFFE65100),
      child: Column(
        children: result.importantNotes.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key + 1}.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2C3E50),
                      height: 1.5,
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

  Widget _buildGuidelineReference() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.menu_book, color: Color(0xFF546E7A), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '参照ガイドライン',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF546E7A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  result.guidelineReference,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF546E7A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // 予後情報ボタン（最上部）
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PrognosisScreen(patientData: patientData),
              ),
            ),
            icon: const Icon(Icons.timeline, size: 18),
            label: const Text('予後情報を見る（参考）'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF37474F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
              context.read<AppState>().reset();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WizardScreen()),
              );
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('新しい症例を入力'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.home_outlined, size: 18),
            label: const Text('ホームへ戻る'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppTheme.primaryBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────
// 共通ウィジェット
// ─────────────────────────────────────
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
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatefulWidget {
  final TreatmentRecommendation rec;
  final bool isPrimary;

  const _RecommendationCard({required this.rec, required this.isPrimary});

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _expanded = true;

  Color get _strengthColor {
    switch (widget.rec.strength) {
      case RecommendationStrength.strongRecommend:
        return AppTheme.riskLow;
      case RecommendationStrength.recommend:
        return AppTheme.primaryBlue;
      case RecommendationStrength.consider:
        return AppTheme.riskHighInt;
      case RecommendationStrength.notRecommend:
        return AppTheme.riskHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isPrimary
              ? AppTheme.primaryBlue.withValues(alpha: 0.3)
              : const Color(0xFF00838F).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.isPrimary
                    ? AppTheme.primaryBlue.withValues(alpha: 0.04)
                    : const Color(0xFF00838F).withValues(alpha: 0.04),
                borderRadius: _expanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      )
                    : BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.rec.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _strengthColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _strengthColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                widget.rec.strength.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _strengthColor,
                                ),
                              ),
                            ),
                            if (widget.rec.guideline != null) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.rec.guideline!,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF90A4AE),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF90A4AE),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.rec.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2C3E50),
                      height: 1.5,
                    ),
                  ),
                  if (widget.rec.details.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    ...widget.rec.details.map((detail) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.arrow_right,
                              color: AppTheme.primaryBlue,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                detail,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF546E7A),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
