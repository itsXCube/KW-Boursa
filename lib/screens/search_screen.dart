import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';
import 'result_screen.dart';

class SearchScreen extends StatefulWidget {
  final String mode;
  final String title;
  const SearchScreen({super.key, required this.mode, required this.title});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const Map<String, String> _sheetMap = {
    'insider':   'Sheet2',
    'ownership': 'Sheet3',
    'financial': 'Sheet5',
    'compinfo':  'Sheet3',
    'stocks':    'Sheet7',
  };

  List<Company> _all = [];
  List<Company> _filtered = [];
  bool _loading = true;
  String? _error;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final sheet = _sheetMap[widget.mode] ?? 'Sheet1';
      _all = await ApiService.getCompanies(sheet);
      setState(() { _filtered = _all; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  String _norm(String t) => t
      .replaceAll(RegExp(r'[أإآ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .trim().toLowerCase();

  void _onSearch(String v) {
    final q = _norm(v);
    setState(() {
      _filtered = q.isEmpty ? _all : _all.where((c) => _norm(c.name).contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Container(
            color: kNavy2,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: TextField(
              controller: _ctrl,
              textDirection: TextDirection.rtl,
              onChanged: _onSearch,
              autofocus: !_loading,
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'ابحث عن شركة...',
                hintStyle: GoogleFonts.cairo(color: kMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: kGold),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: kMuted, size: 18),
                        onPressed: () { _ctrl.clear(); _onSearch(''); },
                      )
                    : null,
                filled: true,
                fillColor: kNavy,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kGold)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              ),
            ),
          ),
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text('${_filtered.length} شركة', style: GoogleFonts.cairo(fontSize: 11, color: kMuted)),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _error != null
                    ? AppErrorWidget(message: _error!, onRetry: _load)
                    : _filtered.isEmpty
                        ? const EmptyWidget(message: 'لا توجد نتائج')
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final c = _filtered[i];
                              return _CompanyTile(
                                company: c,
                                onTap: () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => ResultScreen(
                                    company: c,
                                    mode: widget.mode,
                                    title: widget.title,
                                  ),
                                )),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _CompanyTile extends StatelessWidget {
  final Company company;
  final VoidCallback onTap;
  const _CompanyTile({required this.company, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials = company.name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0] : '').join();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: kGold.withOpacity(0.15),
              child: Text(initials, style: GoogleFonts.cairo(
                fontSize: 12, fontWeight: FontWeight.w800, color: kGold2)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(company.name,
              style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600))),
            const Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: kMuted),
          ],
        ),
      ),
    );
  }
}
