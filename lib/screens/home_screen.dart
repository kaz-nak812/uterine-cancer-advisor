import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/app_theme.dart';
import 'wizard_screen.dart';
import 'guideline_info_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              _buildMainContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryBlueDark, AppTheme.primaryBlue, AppTheme.accentBlue],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medical_services, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '子宮体癌',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        '術後補助治療判断支援',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Colors.white70, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'ESMO 2020 / ESGO-ESTRO-ESP / NCCN 2024 準拠',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDisclaimerCard(context),
          const SizedBox(height: 16),
          _buildStartButton(context),
          const SizedBox(height: 16),
          _buildFeatureGrid(context),
          const SizedBox(height: 16),
          _buildGuidelineButton(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB300), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF8F00), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'このアプリは医療専門家向けの参考情報を提供するものです。最終的な治療判断は、担当医師が患者個別の状況を考慮した上で行ってください。',
              style: TextStyle(fontSize: 12, color: Color(0xFF5D4037), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          context.read<AppState>().reset();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WizardScreen()),
          );
        },
        icon: const Icon(Icons.play_arrow_rounded, size: 24),
        label: const Text('リスク判定を開始する'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      _FeatureItem(
        icon: Icons.science_outlined,
        title: 'FIGO 2023',
        subtitle: '最新ステージ分類',
        color: const Color(0xFF1565C0),
      ),
      _FeatureItem(
        icon: Icons.biotech_outlined,
        title: '分子分類',
        subtitle: 'POLE・MMR・p53・ER',
        color: const Color(0xFF00838F),
      ),
      _FeatureItem(
        icon: Icons.local_hospital_outlined,
        title: '放射線治療',
        subtitle: 'VBT・EBRT・IMRT・BT',
        color: const Color(0xFF558B2F),
      ),
      _FeatureItem(
        icon: Icons.medication_outlined,
        title: '化学療法',
        subtitle: 'TC・ICI・ホルモン',
        color: const Color(0xFF6A1B9A),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            '対応項目',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF546E7A),
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: features.map((f) => _buildFeatureCard(f)).toList(),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(_FeatureItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: item.color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: item.color,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF78909C)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GuidelineInfoScreen()),
        );
      },
      icon: const Icon(Icons.menu_book_outlined, size: 18),
      label: const Text('ガイドライン・参考文献'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: const BorderSide(color: AppTheme.primaryBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
