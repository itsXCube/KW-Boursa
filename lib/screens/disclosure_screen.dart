import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';

const _kSheetCip  = 'Sheet1';
const _kSheetXbrl = 'Sheet4';

class DisclosureScreen extends StatelessWidget {
  const DisclosureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('افصاحات الشركات المدرجة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SubMenuTile(
            icon: Icons.receipt_long_rounded,
            title: 'افصاحات الشركات على نظام الـ CIP',
            color: const Color(0xFF4AA8D8),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const _DisclosureDetailScreen(sheet: _kSheetCip, label: 'CIP'),
            )),
          ),
          const SizedBox(height: 10),
          _SubMenuTile(
            icon: Icons.analytics_rounded,
            title: 'افصاحات الشركات على نظام الـ XBRL',
            color: const Color(0xFF9B6ED4),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const _DisclosureDetailScreen(sheet: _kSheetXbrl, label: 'XBRL'),
            )),
          ),
        ],
      ),
    );
  }
}

class _SubMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  const _SubMenuTile({required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700))),
            Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

// ── Detail screen: daily / previous / search ──────────────────────────
class _DisclosureDetailScreen extends StatefulWidget {
  final String sheet;
  final String label;
  const _DisclosureDetailScreen({required this.sheet, required this.label});

  @override
  State<_DisclosureDetailScreen> createState() => _DisclosureDetailScreenState();
}

class _DisclosureDetailScreenState extends State<_DisclosureDetailScreen> {
  bool _isDaily = true;
  bool _loading = false;
  String? _error;
  List<DisclosureItem> _items = [];
  List<Company> _companies = [];
  final _searchCtrl = TextEditingController();
  List<Company> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _fetchGlobal(daily: true);
  }

  Future<void> _loadCompanies() async {
    _companies = await ApiService.getCompanies(widget.sheet);
  }

  Future<void> _fetchGlobal({required bool daily}) async {
    setState(() { _isDaily = daily; _loading = true; _error = null; });
    try {
      final urls = await ApiService.getGlobalUrls(widget.sheet);
      final url = daily ? urls['daily']! : urls['previous']!;
      if (url.isEmpty) throw Exception('الرابط غير متوفر');
      final data = await ApiService.proxyFetch(url);
      setState(() { _items = ApiService.parseDisclosures(data, sort: false); });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _fetchCompany(Company c) async {
    setState(() { _loading = true; _error = null; _suggestions = []; _searchCtrl.text = c.name; });
    try {
      final data = await ApiService.proxyFetch(c.urlDefault);
      setState(() { _items = ApiService.parseDisclosures(data, sort: true); });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  String _norm(String t) => t.replaceAll(RegExp(r'[أإآ]'),'ا').replaceAll('ى','ي').replaceAll('ة','ه').trim().toLowerCase();

  void _onSearch(String v) {
    if (v.isEmpty) { setState(() { _suggestions = []; }); return; }
    final q = _norm(v);
    setState(() {
      _suggestions = _companies.where((c) => _norm(c.name).contains(q)).take(8).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('افصاحات ${widget.label}')),
      body: Column(
        children: [
          Container(
            color: kNavy2,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              children: [
                Row(children: [
                  _ToggleBtn(label: 'افصاحات جلسة اليوم',    active: _isDaily,  onTap: () => _fetchGlobal(daily: true)),
                  const SizedBox(width: 8),
                  _ToggleBtn(label: 'الجلسة السابقة', active: !_isDaily, onTap: () => _fetchGlobal(daily: false)),
                ]),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      textDirection: TextDirection.rtl,
                      onChanged: _onSearch,
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن شركة...',
                        hintStyle: GoogleFonts.cairo(color: kMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: kGold),
                        filled: true, fillColor: kNavy,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kGold)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      ),
                    ),
                    if (_suggestions.isNotEmpty)
                      Positioned(top: 50, left: 0, right: 0,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                              color: kCard2, borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kGold.withOpacity(0.4)),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                              itemCount: _suggestions.length,
                              itemBuilder: (_, i) => InkWell(
                                onTap: () => _fetchCompany(_suggestions[i]),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                  decoration: BoxDecoration(
                                    border: i < _suggestions.length - 1
                                        ? const Border(bottom: BorderSide(color: kBorder)) : null,
                                  ),
                                  child: Text(_suggestions[i].name, style: GoogleFonts.cairo(fontSize: 13)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading ? const LoadingWidget()
              : _error != null ? AppErrorWidget(message: _error!, onRetry: () => _fetchGlobal(daily: _isDaily))
              : _items.isEmpty ? const EmptyWidget(message: 'لا توجد سجلات')
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  itemBuilder: (_, i) => _DisclosureCard(item: _items[i]),
                ),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? kGold : kCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? kGold : kBorder),
          ),
          child: Text(label, textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700,
              color: active ? kNavy : kMuted)),
        ),
      ),
    );
  }
}

class _DisclosureCard extends StatelessWidget {
  final DisclosureItem item;
  const _DisclosureCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.title,
                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700))),
              if (item.ticker.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: kBlue, borderRadius: BorderRadius.circular(6)),
                  child: Text(item.ticker, style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w700, color: kGold2)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 12, color: kMuted),
              const SizedBox(width: 4),
              Text(item.date, style: GoogleFonts.cairo(fontSize: 11, color: kMuted)),
              const Spacer(),
              if (item.url.isNotEmpty)
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse(item.url);
                    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: kGold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kGold.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.open_in_new_rounded, size: 12, color: kGold2),
                      const SizedBox(width: 4),
                      Text('عرض', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: kGold2)),
                    ]),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
