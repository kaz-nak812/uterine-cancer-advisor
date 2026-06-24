import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/patient_data.dart';
import '../utils/app_theme.dart';
import 'result_screen.dart';

class WizardScreen extends StatelessWidget {
  const WizardScreen({super.key});

  static const List<String> _stepTitles = [
    'FIGO 2023 ステージ',
    '組織型・グレード',
    'LVSI（リンパ管血管浸襲）',
    '分子分類・追加情報',
  ];



  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            title: const Text('リスク判定入力', style: TextStyle(fontSize: 16)),
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              TextButton(
                onPressed: () {
                  _showResetDialog(context, state);
                },
                child: const Text('リセット', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildProgressIndicator(state),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildStepContent(context, state),
                  ),
                ),
                _buildNavigationButtons(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(AppState state) {
    return Container(
      color: AppTheme.primaryBlue,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Row(
            children: List.generate(state.totalSteps, (index) {
              final isCompleted = index < state.currentStep;
              final isCurrent = index == state.currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < state.totalSteps - 1) const SizedBox(width: 4),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Step ${state.currentStep + 1} / ${state.totalSteps}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _stepTitles[state.currentStep],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, AppState state) {
    switch (state.currentStep) {
      case 0:
        return _StepFigoStage(state: state);
      case 1:
        return _StepHistology(state: state);
      case 2:
        return _StepLvsi(state: state);
      case 3:
        return _StepMolecular(state: state);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationButtons(BuildContext context, AppState state) {
    final isLastStep = state.currentStep == state.totalSteps - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E8F5))),
      ),
      child: Row(
        children: [
          if (state.currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state.previousStep,
                icon: const Icon(Icons.arrow_back_ios, size: 14),
                label: const Text('戻る'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.primaryBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          if (state.currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: state.canProceed
                  ? () {
                      if (isLastStep) {
                        final result = state.evaluate();
                        final patientData = state.patientData;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResultScreen(
                              result: result,
                              patientData: patientData,
                            ),
                          ),
                        );
                      } else {
                        state.nextStep();
                      }
                    }
                  : null,
              icon: Icon(
                isLastStep ? Icons.assessment : Icons.arrow_forward_ios,
                size: 14,
              ),
              label: Text(isLastStep ? '判定する' : '次へ'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFBDBDBD),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('入力をリセット'),
        content: const Text('入力した内容をすべてリセットしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              state.reset();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('リセット'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────
// Step 1: FIGO ステージ
// ─────────────────────────────────────
class _StepFigoStage extends StatelessWidget {
  final AppState state;
  const _StepFigoStage({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          icon: Icons.layers_outlined,
          title: 'FIGO 2023 ステージを選択',
          subtitle: '手術病理所見に基づくステージを選択してください',
        ),
        const SizedBox(height: 16),
        ...FigoStage.values.map((stage) {
          final isSelected = state.patientData.figoStage == stage;
          return _SelectionCard(
            isSelected: isSelected,
            label: stage.label,
            description: stage.description,
            onTap: () => state.updateFigoStage(stage),
            badge: _getStageBadge(stage),
          );
        }),
      ],
    );
  }

  String? _getStageBadge(FigoStage stage) {
    if ([FigoStage.ia, FigoStage.ib, FigoStage.ic].contains(stage)) return 'Stage I';
    if ([FigoStage.iia, FigoStage.iib].contains(stage)) return 'Stage II';
    if ([FigoStage.iiia, FigoStage.iiib, FigoStage.iiic1, FigoStage.iiic2].contains(stage)) return 'Stage III';
    return 'Stage IV';
  }
}

// ─────────────────────────────────────
// Step 2: 組織型
// ─────────────────────────────────────
class _StepHistology extends StatelessWidget {
  final AppState state;
  const _StepHistology({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          icon: Icons.biotech_outlined,
          title: '組織型・グレードを選択',
          subtitle: '最終病理診断の組織型を選択してください',
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '漿液性・明細胞・癌肉腫・未分化癌は高リスク組織型として扱われます',
                  style: TextStyle(fontSize: 12, color: Color(0xFF1565C0)),
                ),
              ),
            ],
          ),
        ),
        ...HistologicalType.values.map((type) {
          final isSelected = state.patientData.histologicalType == type;
          return _SelectionCard(
            isSelected: isSelected,
            label: type.label,
            description: type.englishLabel,
            onTap: () => state.updateHistologicalType(type),
            badge: type.isHighRiskHistology ? '高リスク' : null,
            badgeColor: type.isHighRiskHistology ? AppTheme.riskHigh : null,
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────
// Step 3: LVSI
// ─────────────────────────────────────
class _StepLvsi extends StatelessWidget {
  final AppState state;
  const _StepLvsi({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          icon: Icons.water_outlined,
          title: 'LVSI を選択',
          subtitle: 'リンパ管血管浸襲（Lymphovascular Space Invasion）の程度を選択してください',
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF2E7D32), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Substantial（広範）: 腫瘍周囲脈管の50%以上への浸襲またはブロック状浸襲',
                  style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                ),
              ),
            ],
          ),
        ),
        ...LvsiStatus.values.map((lvsi) {
          final isSelected = state.patientData.lvsiStatus == lvsi;
          return _SelectionCard(
            isSelected: isSelected,
            label: lvsi.label,
            description: lvsi.englishLabel,
            onTap: () => state.updateLvsi(lvsi),
            badge: lvsi == LvsiStatus.substantial ? 'リスク上昇' : null,
            badgeColor: lvsi == LvsiStatus.substantial ? AppTheme.riskHighInt : null,
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────
// Step 4: 分子分類・追加情報
// ─────────────────────────────────────
class _StepMolecular extends StatelessWidget {
  final AppState state;
  const _StepMolecular({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          icon: Icons.science_outlined,
          title: '分子分類を選択',
          subtitle: 'ProMisE分類 / TCGA分子サブタイプを選択してください',
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Color(0xFF6A1B9A), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '優先順位: POLEmut > p53abn > MMRd > NSMP\n複数陽性の場合は上位の分類を選択してください',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6A1B9A), height: 1.4),
                ),
              ),
            ],
          ),
        ),
        ...MolecularSubtype.values.map((subtype) {
          final isSelected = state.patientData.molecularSubtype == subtype;
          return _MolecularCard(
            isSelected: isSelected,
            subtype: subtype,
            onTap: () => state.updateMolecularSubtype(subtype),
          );
        }),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'ER（エストロゲン受容体）状態（任意）',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFCC02).withValues(alpha: 0.5)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFF57F17), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'ERカットオフについて',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF57F17)),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                '・治療選択（ホルモン療法適応）: ≥1% で陽性\n'
                '・予後判定（NSMP層別化）: ≥10% で高発現\n'
                '　病理報告書の核染色陽性率をご確認ください',
                style: TextStyle(fontSize: 11, color: Color(0xFF795548), height: 1.5),
              ),
            ],
          ),
        ),
        ...ErStatus.values.map((er) {
          final isSelected = state.patientData.erStatus == er;
          Color badgeColor;
          String? badge;
          switch (er) {
            case ErStatus.highPositive:
              badge = '予後良好';
              badgeColor = const Color(0xFF2E7D32);
            case ErStatus.lowPositive:
              badge = '治療陽性';
              badgeColor = const Color(0xFF0277BD);
            case ErStatus.negative:
              badge = 'NSMP注意';
              badgeColor = const Color(0xFFC62828);
            case ErStatus.unknown:
              badge = null;
              badgeColor = const Color(0xFF546E7A);
          }
          return _SelectionCard(
            isSelected: isSelected,
            label: er.label,
            description: er.description,
            onTap: () => state.updateErStatus(er),
            badge: badge,
            badgeColor: badgeColor,
          );
        }),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'リンパ節郭清の実施（任意）',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ToggleCard(
                label: '郭清あり',
                isSelected: state.patientData.lymphadenectomyPerformed == true,
                onTap: () => state.updateLymphadenectomy(true),
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ToggleCard(
                label: '郭清なし',
                isSelected: state.patientData.lymphadenectomyPerformed == false,
                onTap: () => state.updateLymphadenectomy(false),
                icon: Icons.cancel_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ToggleCard(
                label: 'センチネル',
                isSelected: state.patientData.lymphadenectomyPerformed == null,
                onTap: () => state.updateLymphadenectomy(null),
                icon: Icons.radio_button_checked,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        // ─── 腹水細胞診 ───
        const Text(
          '腹水細胞診（任意）',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFBE9E7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE57373).withValues(alpha: 0.5)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_outlined, color: Color(0xFFC62828), size: 14),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '陽性は独立した予後不良因子（死亡リスク 6.2倍: Cox多変量解析, IJGC 2025）。\n'
                  'FIGO 2009・2023 いずれもステージング基準に含まれないため、入力は任意です。',
                  style: TextStyle(fontSize: 11, color: Color(0xFF795548), height: 1.5),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _ToggleCard(
                label: '陽性',
                isSelected: state.patientData.peritonealCytologyPositive == true,
                onTap: () => state.updatePeritonealCytology(true),
                icon: Icons.add_circle_outline,
                activeColor: const Color(0xFFC62828),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ToggleCard(
                label: '陰性',
                isSelected: state.patientData.peritonealCytologyPositive == false,
                onTap: () => state.updatePeritonealCytology(false),
                icon: Icons.remove_circle_outline,
                activeColor: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ToggleCard(
                label: '不明',
                isSelected: state.patientData.peritonealCytologyPositive == null,
                onTap: () => state.updatePeritonealCytology(null),
                icon: Icons.help_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─────────────────────────────────────
// 共通ウィジェット
// ─────────────────────────────────────
class _StepHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StepHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF78909C)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final bool isSelected;
  final String label;
  final String description;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  const _SelectionCard({
    required this.isSelected,
    required this.label,
    required this.description,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE0E8F5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryBlue : const Color(0xFFBDBDBD),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppTheme.primaryBlue : const Color(0xFF2C3E50),
                    ),
                  ),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF78909C)),
                    ),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (badgeColor ?? AppTheme.primaryBlue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (badgeColor ?? AppTheme.primaryBlue).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor ?? AppTheme.primaryBlue,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MolecularCard extends StatelessWidget {
  final bool isSelected;
  final MolecularSubtype subtype;
  final VoidCallback onTap;

  const _MolecularCard({
    required this.isSelected,
    required this.subtype,
    required this.onTap,
  });

  Color get _subtypeColor {
    switch (subtype) {
      case MolecularSubtype.poleMutated:
        return const Color(0xFF2E7D32);
      case MolecularSubtype.mmrd:
        return const Color(0xFF0277BD);
      case MolecularSubtype.p53abn:
        return const Color(0xFFC62828);
      case MolecularSubtype.nsmp:
        return const Color(0xFF546E7A);
    }
  }

  String get _riskLabel {
    switch (subtype) {
      case MolecularSubtype.poleMutated:
        return '最良予後';
      case MolecularSubtype.mmrd:
        return '中間';
      case MolecularSubtype.p53abn:
        return '最悪予後';
      case MolecularSubtype.nsmp:
        return '中間〜';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _subtypeColor.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _subtypeColor : const Color(0xFFE0E8F5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _subtypeColor.withValues(alpha: isSelected ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  subtype.shortLabel.split('/').first.substring(0, subtype.shortLabel.length.clamp(0, 4)),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _subtypeColor,
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
                        subtype.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? _subtypeColor : const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _subtypeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _riskLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _subtypeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtype.description,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF78909C)),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: _subtypeColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final Color? activeColor;

  const _ToggleCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppTheme.primaryBlue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE0E8F5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : const Color(0xFF90A4AE),
              size: 18,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : const Color(0xFF546E7A),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
