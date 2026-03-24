import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';
import 'search_screen.dart';

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});
  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loading = true;
  String? _error;
  List<MarketIndex> _kwIndexes = [];
  List<MarketIndex> _usIndexes = [];

  static const List<_IndexDef> _kw = [
    _IndexDef('%5EBKA.KW',   'المؤشر العام'),
    _IndexDef('%5E50.KW',    'السوق الرئيسي 50'),
    _IndexDef('%5EBKM50.KW', 'المؤشر الرئيسي 50'),
  ];
  static const List<_IndexDef> _us = [
    _IndexDef('%5EGSPC', 'S&P 500'),
    _IndexDef('%5EDJI',  'داو جونز'),
    _IndexDef('%5EIXIC', 'ناسداك'),
    _IndexDef('%5ENYA',  'بورصة نيويورك'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _fetch();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final kwFutures = _kw.map((d) => ApiService.fetchYahooMeta(d.symbol));
      final usFutures = _us.map((d) => ApiService.fetchYahooMeta(d.symbol));
      final kwResults = await Future.wait(kwFutures);
      final usResults = await Future.wait(usFutures);

      _kwIndexes = [];
      for (var i = 0; i < _kw.length; i++) {
        final meta = kwResults[i];
        if (meta != null) _kwIndexes.add(MarketIndex.fromMeta(_kw[i].name, _kw[i].symbol, meta));
      }
      _usIndexes = [];
      for (var i = 0; i < _us.length; i++) {
        final meta = usResults[i];
        if (meta != null) _usIndexes.add(MarketIndex.fromMeta(_us[i].name, _us[i].symbol, meta));
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أسعار الأسهم ومؤشرات الأسواق'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetch),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: kGold,
          labelColor: kGold2,
          unselectedLabelColor: kMuted,
          labelStyle: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: '🇰🇼 الكويت'),
            Tab(text: '🌐 أمريكا'),
            Tab(text: '💹 الأسهم'),
          ],
        ),
      ),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _fetch)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _IndexList(indexes: _kwIndexes, flag: '🇰🇼'),
                    _IndexList(indexes: _usIndexes, flag: '🌐'),
                    const _StocksSearchTab(),
                  ],
                ),
    );
  }
}

class _IndexDef {
  final String symbol;
  final String name;
  const _IndexDef(this.symbol, this.name);
}

// ── Index list tab ────────────────────────────────────────────────────
class _IndexList extends StatelessWidget {
  final List<MarketIndex> indexes;
  final String flag;
  const _IndexList({required this.indexes, required this.flag});

  String _fmt(double v, {int dec = 2}) =>
      v.toStringAsFixed(dec).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  @override
  Widget build(BuildContext context) {
    if (indexes.isEmpty) {
      return const Center(child: Text('تعذر جلب البيانات من Yahoo Finance'));
    }
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        ...indexes.map((idx) {
          final isUp = idx.change >= 0;
          final clr  = isUp ? kGreen : kRed;
          final sign = isUp ? '+' : '';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCard, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('$flag  ${idx.nameAr}',
                  style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: clr.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text('$sign${_fmt(idx.changePct)}%',
                    style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: clr)),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Text(_fmt(idx.price),
                  style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                Text('$sign${_fmt(idx.change)}',
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: clr)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.arrow_upward_rounded, size: 12, color: kGreen),
                const SizedBox(width: 2),
                Text(_fmt(idx.dayHigh), style: GoogleFonts.cairo(fontSize: 11, color: kMuted)),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_downward_rounded, size: 12, color: kRed),
                const SizedBox(width: 2),
                Text(_fmt(idx.dayLow), style: GoogleFonts.cairo(fontSize: 11, color: kMuted)),
              ]),
            ]),
          );
        }),
        const SizedBox(height: 8),
        Text('المصدر: Yahoo Finance', textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontSize: 10, color: const Color(0xFF3A4F72))),
      ],
    );
  }
}

// ── Stocks search tab ─────────────────────────────────────────────────
class _StocksSearchTab extends StatelessWidget {
  const _StocksSearchTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: kGold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kGold.withOpacity(0.3)),
              ),
              child: const Icon(Icons.candlestick_chart_rounded, size: 36, color: kGold2),
            ),
            const SizedBox(height: 20),
            Text('قيمة الأسهم', style: GoogleFonts.cairo(
              fontSize: 20, fontWeight: FontWeight.w800, color: kGold2)),
            const SizedBox(height: 8),
            Text('ابحث عن شركة مدرجة للاطلاع على سعر سهمها من Yahoo Finance',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 12, color: kMuted, height: 1.6)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const SearchScreen(mode: 'stocks', title: 'قيمة الأسهم للشركات المدرجة'),
                )),
                icon: const Icon(Icons.search_rounded, size: 20),
                label: Text('بحث عن شركة', style: GoogleFonts.cairo(
                  fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGold,
                  foregroundColor: kNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
