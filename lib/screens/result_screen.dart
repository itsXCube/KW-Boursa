import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';

class ResultScreen extends StatefulWidget {
  final Company company;
  final String mode;
  final String title;
  const ResultScreen({super.key, required this.company, required this.mode, required this.title});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _loading = true;
  String? _error;
  dynamic _data;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (widget.mode == 'stocks') {
        final ticker = widget.company.urlDefault;
        final meta = await ApiService.fetchYahooMeta(Uri.encodeComponent(ticker));
        if (meta == null) throw Exception('لا توجد بيانات للسهم: $ticker');
        _data = StockPrice.fromYahooMeta(meta);
      } else {
        final raw = await ApiService.proxyFetch(widget.company.urlDefault);
        switch (widget.mode) {
          case 'insider':   _data = ApiService.parseInsiders(raw); break;
          case 'ownership': _data = {'ownership': (raw['Ownership Disclosure'] as List? ?? []).map((e) => OwnerItem.fromJson(e as Map<String,dynamic>)).toList(), 'subsidiaries': (raw['Company Subsidiaries'] as List? ?? []).map((e) => SubsidiaryItem.fromJson(e as Map<String,dynamic>)).toList()}; break;
          case 'financial': _data = ApiService.parseFinancials(raw); break;
          case 'compinfo':  _data = CompanyInfo.fromJson(raw as Map<String,dynamic>); break;
          case 'disclosure': _data = ApiService.parseDisclosures(raw, sort: true); break;
        }
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
      appBar: AppBar(title: Text(widget.company.name, overflow: TextOverflow.ellipsis)),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _fetch)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (widget.mode) {
      case 'insider':   return _InsiderBody(sections: _data as List<InsiderSection>);
      case 'ownership': return _OwnershipBody(data: _data as Map);
      case 'financial': return _FinancialBody(reports: _data as List<FinancialReport>);
      case 'compinfo':  return _CompInfoBody(info: _data as CompanyInfo);
      case 'stocks':    return _StockBody(stock: _data as StockPrice, companyName: widget.company.name);
      case 'disclosure': return _DisclosureListBody(items: _data as List<DisclosureItem>);
      default:          return const EmptyWidget(message: 'غير محدد');
    }
  }
}

// ── Insider body ──────────────────────────────────────────────────────
class _InsiderBody extends StatelessWidget {
  final List<InsiderSection> sections;
  const _InsiderBody({required this.sections});

  static const List<Color> _colors = [
    Color(0xFF4AA8D8), Color(0xFF4CAF78), Color(0xFFD45B7A),
  ];

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const EmptyWidget(message: 'لا توجد بيانات مطلعين');
    return ListView(
      padding: const EdgeInsets.all(12),
      children: sections.asMap().entries.map((entry) {
        final sec = entry.value;
        final color = _colors[entry.key % _colors.length];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(icon: Icons.people_rounded, title: sec.header,
              count: sec.type == 3 ? sec.entities.length : sec.people.length),
            if (sec.type == 3) ...[
              ...sec.entities.map((e) => PersonTile(
                name: e.name, subtitle: e.relation.isNotEmpty ? e.relation : (e.hq.isNotEmpty ? e.hq : '—'),
                avatarColor: color.withOpacity(0.15), textColor: color,
                badge: e.hq.isNotEmpty ? e.hq : null, badgeColor: kMuted,
              )),
            ] else ...[
              ...sec.people.map((p) => PersonTile(
                name: p.name, subtitle: p.title,
                avatarColor: color.withOpacity(0.15), textColor: color,
              )),
            ],
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }
}

// ── Ownership body ────────────────────────────────────────────────────
class _OwnershipBody extends StatelessWidget {
  final Map data;
  const _OwnershipBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final owners = data['ownership'] as List<OwnerItem>;
    final subs   = data['subsidiaries'] as List<SubsidiaryItem>;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SectionHeader(icon: Icons.pie_chart_rounded, title: 'كبار الملاك', count: owners.length),
        if (owners.isEmpty) const EmptyWidget(message: 'لا يوجد')
        else ...owners.map((o) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder, width: 0.5)),
          child: Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o.name, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700)),
                if (o.type.isNotEmpty) Text(o.type, style: GoogleFonts.cairo(fontSize: 10, color: kMuted)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: kGold.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Text('${o.pct}%', style: GoogleFonts.cairo(
                  fontSize: 13, fontWeight: FontWeight.w700, color: kGold2)),
              ),
            ],
          ),
        )),
        const SizedBox(height: 16),
        SectionHeader(icon: Icons.account_tree_rounded, title: 'الشركات التابعة والزميلة', count: subs.length),
        if (subs.isEmpty) const EmptyWidget(message: 'لا يوجد')
        else ...subs.map((s) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder, width: 0.5)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700)),
              if (s.relation.isNotEmpty) Text(s.relation, style: GoogleFonts.cairo(fontSize: 10, color: kMuted)),
            ])),
            Text('${s.pct}%', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: kGold2)),
          ]),
        )),
      ],
    );
  }
}

// ── Financial body ────────────────────────────────────────────────────
class _FinancialBody extends StatelessWidget {
  final List<FinancialReport> reports;
  const _FinancialBody({required this.reports});

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) return const EmptyWidget(message: 'لا توجد تقارير مالية');
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: reports.length,
      itemBuilder: (_, i) {
        final r = reports[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder, width: 0.5)),
          child: Row(
            children: [
              Container(width: 42, height: 42,
                decoration: BoxDecoration(color: const Color(0xFF9B6ED4).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.description_rounded, color: Color(0xFF9B6ED4), size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.year, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(r.period, style: GoogleFonts.cairo(fontSize: 11, color: kMuted)),
              ])),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(r.link);
                  if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: kGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8), border: Border.all(color: kGold.withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.open_in_new_rounded, size: 13, color: kGold2),
                    const SizedBox(width: 4),
                    Text(r.type, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: kGold2)),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── CompInfo body ─────────────────────────────────────────────────────
class _CompInfoBody extends StatelessWidget {
  final CompanyInfo info;
  const _CompInfoBody({required this.info});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SectionHeader(icon: Icons.info_rounded, title: 'المعلومات العامة'),
        InfoBlock(rows: [
          if (info.companyName.isNotEmpty)    InfoRow(label: 'الاسم',               value: info.companyName),
          if (info.establishedOn.isNotEmpty)  InfoRow(label: 'تاريخ التأسيس',        value: info.establishedOn),
          if (info.listingDate.isNotEmpty)    InfoRow(label: 'تاريخ الإدراج',        value: info.listingDate),
          if (info.fiscalEnd.isNotEmpty)      InfoRow(label: 'نهاية السنة المالية',   value: info.fiscalEnd),
          if (info.activity.isNotEmpty)       InfoRow(label: 'النشاط',               value: info.activity, isLast: true),
        ]),
        SectionHeader(icon: Icons.monetization_on_rounded, title: 'رأس المال والأسهم'),
        InfoBlock(rows: [
          InfoRow(label: 'رأس المال المرخص',  value: info.fmtNum('AuthorizedCapitalOrShare')),
          InfoRow(label: 'رأس المال المدفوع', value: info.fmtNum('PiadUpCapital')),
          InfoRow(label: 'الأسهم القائمة',    value: info.fmtNum('SharesOutstanding')),
          InfoRow(label: 'الأسهم المُصدرة',   value: info.fmtNum('NumberOfIssuedShares')),
          InfoRow(label: 'القيمة الاسمية',    value: info.fmtNum('SharePerValue'), isLast: true),
        ]),
        SectionHeader(icon: Icons.contact_phone_rounded, title: 'معلومات التواصل'),
        InfoBlock(rows: [
          if (info.address.isNotEmpty)      InfoRow(label: 'العنوان',     value: info.address),
          if (info.poBox.isNotEmpty)        InfoRow(label: 'ص.ب',         value: info.poBox),
          if (info.phone.isNotEmpty)        InfoRow(label: 'هاتف',        value: info.phone),
          if (info.fax.isNotEmpty)          InfoRow(label: 'فاكس',        value: info.fax),
          if (info.email.isNotEmpty)        InfoRow(label: 'البريد',      value: info.email),
          if (info.website.isNotEmpty)      InfoRow(label: 'الموقع',      value: info.website, isLast: true),
        ]),
        if (info.employees.isNotEmpty) ...[
          SectionHeader(icon: Icons.people_alt_rounded, title: 'بيانات العمل'),
          InfoBlock(rows: [
            InfoRow(label: 'عدد الموظفين',       value: info.employees),
            InfoRow(label: 'الفروع المحلية',      value: info.localBranches),
            InfoRow(label: 'الفروع الخارجية',     value: info.extBranches, isLast: true),
          ]),
        ],
        if (info.board.isNotEmpty) ...[
          SectionHeader(icon: Icons.groups_rounded, title: 'مجلس الإدارة', count: info.board.length),
          ...info.board.map((m) => PersonTile(
            name: m.name, subtitle: m.position,
            avatarColor: const Color(0xFF4AA8D8).withOpacity(0.15),
            textColor: const Color(0xFF4AA8D8),
            badge: m.bodType.isNotEmpty ? m.bodType : null,
            badgeColor: const Color(0xFF4AA8D8),
          )),
        ],
        if (info.executive.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionHeader(icon: Icons.manage_accounts_rounded, title: 'الجهاز الإداري', count: info.executive.length),
          ...info.executive.map((m) => PersonTile(
            name: m.name, subtitle: m.position,
            avatarColor: const Color(0xFF4CAF78).withOpacity(0.15),
            textColor: const Color(0xFF4CAF78),
          )),
        ],
        if (info.auditors.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionHeader(icon: Icons.verified_rounded, title: 'مراقبو الحسابات', count: info.auditors.length),
          ...info.auditors.map((a) => PersonTile(
            name: a.name, subtitle: a.position,
            avatarColor: kGold.withOpacity(0.15),
            textColor: kGold2,
          )),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Disclosure list body (company search result) ──────────────────────
class _DisclosureListBody extends StatelessWidget {
  final List<DisclosureItem> items;
  const _DisclosureListBody({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const EmptyWidget(message: 'لا توجد افصاحات');
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder, width: 0.5)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.schedule_rounded, size: 12, color: kMuted),
              const SizedBox(width: 4),
              Text(item.date, style: GoogleFonts.cairo(fontSize: 11, color: kMuted)),
              const Spacer(),
              if (item.url.isNotEmpty) GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(item.url);
                  if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: kGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(7), border: Border.all(color: kGold.withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.open_in_new_rounded, size: 12, color: kGold2),
                    const SizedBox(width: 4),
                    Text('عرض', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: kGold2)),
                  ]),
                ),
              ),
            ]),
          ]),
        );
      },
    );
  }
}

// ── Stock price body ──────────────────────────────────────────────────
class _StockBody extends StatelessWidget {
  final StockPrice stock;
  final String companyName;
  const _StockBody({required this.stock, required this.companyName});

  String _fmt3(double v) => v.toStringAsFixed(3).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  @override
  Widget build(BuildContext context) {
    final isUp    = stock.change >= 0;
    final clr     = isUp ? kGreen : kRed;
    final sign    = isUp ? '+' : '';
    final volStr  = stock.volume > 0
        ? stock.volume.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')
        : '—';

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // ── Price hero ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCard, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kBorder),
          ),
          child: Column(children: [
            if (stock.longName.isNotEmpty)
              Text(stock.longName, textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 12, color: kMuted)),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: kBlue, borderRadius: BorderRadius.circular(6)),
                child: Text(stock.ticker, style: GoogleFonts.cairo(
                  fontSize: 11, fontWeight: FontWeight.w700, color: kGold2)),
              ),
              const SizedBox(width: 6),
              Text(stock.exchange, style: GoogleFonts.cairo(fontSize: 10, color: kMuted)),
            ]),
            const SizedBox(height: 18),
            Text('${_fmt3(stock.price)} ${stock.currency}',
              style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: clr.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
              child: Text('$sign${_fmt3(stock.change)}  ($sign${stock.changePct.toStringAsFixed(2)}%)',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: clr)),
            ),
            const SizedBox(height: 8),
            Text('إغلاق سابق: ${_fmt3(stock.prevClose)}',
              style: GoogleFonts.cairo(fontSize: 11, color: kMuted)),
          ]),
        ),
        const SizedBox(height: 14),

        // ── Day range bar ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('نطاق اليوم', style: GoogleFonts.cairo(fontSize: 11, color: kMuted)),
            const SizedBox(height: 10),
            Row(children: [
              Column(children: [
                Text('أدنى', style: GoogleFonts.cairo(fontSize: 10, color: kRed)),
                Text(_fmt3(stock.dayLow),
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Stack(children: [
                    Container(height: 4, decoration: BoxDecoration(
                      color: kBorder, borderRadius: BorderRadius.circular(2))),
                    if (stock.dayHigh > stock.dayLow)
                      FractionallySizedBox(
                        widthFactor: ((stock.price - stock.dayLow) / (stock.dayHigh - stock.dayLow)).clamp(0, 1),
                        child: Container(height: 4, decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [kGold, kGold2]),
                          borderRadius: BorderRadius.circular(2))),
                      ),
                  ]),
                ),
              ),
              Column(children: [
                Text('أعلى', style: GoogleFonts.cairo(fontSize: 10, color: kGreen)),
                Text(_fmt3(stock.dayHigh),
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
            ]),
          ]),
        ),
        const SizedBox(height: 10),

        // ── Stats grid ──
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10, mainAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            StatCard(label: 'حجم التداول',      value: volStr),
            StatCard(label: 'أعلى 52 أسبوع',   value: _fmt3(stock.fiftyTwoHigh), valueColor: kGreen),
            StatCard(label: 'أدنى 52 أسبوع',   value: _fmt3(stock.fiftyTwoLow),  valueColor: kRed),
            StatCard(label: 'العملة',           value: stock.currency, valueColor: kGold2),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
