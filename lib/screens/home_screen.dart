import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_widgets.dart';
import 'search_screen.dart';
import 'disclosure_screen.dart';
import 'markets_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<_Card> _cards = [
    _Card(mode:'disclosure', title:'افصاحات الشركات المدرجة', sub:'CIP · XBRL',
      icon:Icons.campaign_rounded, bg:Color(0xFF1A5C8A), accent:Color(0xFF4AA8D8)),
    _Card(mode:'insider', title:'قائمة الأشخاص المطلعين', sub:'مجلس الإدارة · الجهاز الإداري',
      icon:Icons.people_rounded, bg:Color(0xFF2D5A3D), accent:Color(0xFF4CAF78)),
    _Card(mode:'ownership', title:'كبار الملاك والشركات التابعة', sub:'هيكل الملكية',
      icon:Icons.account_balance_rounded, bg:Color(0xFF5A3D1A), accent:Color(0xFFC8A84B)),
    _Card(mode:'financial', title:'البيانات المالية للشركات', sub:'التقارير السنوية والفصلية',
      icon:Icons.bar_chart_rounded, bg:Color(0xFF3D1A5A), accent:Color(0xFF9B6ED4)),
    _Card(mode:'compinfo', title:'بيانات الشركات المدرجة', sub:'مجلس الإدارة · التواصل',
      icon:Icons.business_rounded, bg:Color(0xFF5A1A2D), accent:Color(0xFFD45B7A)),
    _Card(mode:'markets', title:'أسعار الأسهم ومؤشرات الأسواق', sub:'بورصة الكويت · الأسواق الأمريكية',
      icon:Icons.show_chart_rounded, bg:Color(0xFF1A3A6B), accent:Color(0xFFC8A84B)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [kNavy2, kBlue],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text('ب', style: GoogleFonts.cairo(
                            fontSize: 22, fontWeight: FontWeight.w900, color: kNavy))),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('بورصة الكويت', style: GoogleFonts.cairo(
                              fontSize: 20, fontWeight: FontWeight.w800, color: kGold2)),
                            Text('لوحة بيانات الشركات المدرجة', style: GoogleFonts.cairo(
                              fontSize: 11, color: kMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => AnimationConfiguration.staggeredGrid(
                  position: i, duration: const Duration(milliseconds: 380), columnCount: 2,
                  child: ScaleAnimation(child: FadeInAnimation(
                    child: _ServiceTile(card: _cards[i]),
                  )),
                ),
                childCount: _cards.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.88,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: Text('البيانات مقدمة من بورصة الكويت', textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF3A4F72))),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card {
  final String mode, title, sub;
  final IconData icon;
  final Color bg, accent;
  const _Card({required this.mode, required this.title, required this.sub,
    required this.icon, required this.bg, required this.accent});
}

class _ServiceTile extends StatelessWidget {
  final _Card card;
  const _ServiceTile({super.key, required this.card});

  void _navigate(BuildContext ctx) {
    if (card.mode == 'disclosure') {
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => const DisclosureScreen()));
    } else if (card.mode == 'markets') {
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => const MarketsScreen()));
    } else {
      Navigator.push(ctx, MaterialPageRoute(
        builder: (_) => SearchScreen(mode: card.mode, title: card.title),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigate(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topRight, end: Alignment.bottomLeft,
            colors: [card.bg, card.bg.withOpacity(0.55)],
          ),
          border: Border.all(color: card.accent.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: card.bg.withOpacity(0.4), blurRadius: 12, offset: const Offset(0,4))],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: card.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: card.accent.withOpacity(0.35)),
              ),
              child: Icon(card.icon, color: card.accent, size: 24),
            ),
            const Spacer(),
            Text(card.title, style: GoogleFonts.cairo(
              fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3),
              maxLines: 2),
            const SizedBox(height: 3),
            Text(card.sub, style: GoogleFonts.cairo(
              fontSize: 9, color: card.accent.withOpacity(0.85)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: card.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, color: card.accent, size: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
