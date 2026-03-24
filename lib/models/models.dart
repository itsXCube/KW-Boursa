// ── Company (Sheet row) ───────────────────────────────────────────────
class Company {
  final String name;
  final String urlDefault; // URL for most modes, ticker symbol for MODE_STOCKS
  const Company({required this.name, required this.urlDefault});
  factory Company.fromJson(Map<String, dynamic> j) =>
      Company(name: j['name'] ?? '', urlDefault: j['urlDefault'] ?? '');
}

// ── Disclosure item ───────────────────────────────────────────────────
class DisclosureItem {
  final String title;
  final String url;
  final String date;
  final String ticker;
  const DisclosureItem({required this.title, required this.url, required this.date, required this.ticker});

  static String _fmt(String raw) {
    if (raw.length >= 12) {
      return '${raw.substring(0,4)}-${raw.substring(4,6)}-${raw.substring(6,8)}'
          ' ${raw.substring(8,10)}:${raw.substring(10,12)}';
    }
    return raw;
  }

  factory DisclosureItem.fromJson(Map<String, dynamic> j) => DisclosureItem(
    title:  j['Title']  ?? j['title']  ?? 'بدون عنوان',
    url:    (j['Url']   ?? j['url']    ?? '').toString().replaceAll(r'\', '/'),
    date:   _fmt((j['PostedDate'] ?? j['postedDate'] ?? '').toString()),
    ticker: j['DisplayTicker']?.toString() ?? '',
  );
}

// ── Insider person ────────────────────────────────────────────────────
class InsiderPerson {
  final String name;
  final String title;
  const InsiderPerson({required this.name, required this.title});
}

class InsiderSection {
  final String header;
  final int type; // 1, 2, or 3
  final List<InsiderPerson> people;
  final List<InsiderEntity> entities; // type 3
  const InsiderSection({required this.header, required this.type, required this.people, required this.entities});
}

class InsiderEntity {
  final String name;
  final String relation;
  final String hq;
  const InsiderEntity({required this.name, required this.relation, required this.hq});
}

// ── Ownership ─────────────────────────────────────────────────────────
class OwnerItem {
  final String name;
  final double pct;
  final String type;
  const OwnerItem({required this.name, required this.pct, required this.type});
  factory OwnerItem.fromJson(Map<String, dynamic> j) => OwnerItem(
    name: j['FullName'] ?? '—',
    pct:  double.tryParse(j['Percentage']?.toString() ?? '0') ?? 0,
    type: j['DisclosureType'] ?? '',
  );
}

class SubsidiaryItem {
  final String name;
  final String relation;
  final String pct;
  const SubsidiaryItem({required this.name, required this.relation, required this.pct});
  factory SubsidiaryItem.fromJson(Map<String, dynamic> j) => SubsidiaryItem(
    name:     j['CName']    ?? j['name']    ?? '—',
    relation: j['Relation'] ?? j['relation'] ?? '',
    pct:      (j['Percentage'] ?? j['percent'] ?? '—').toString(),
  );
}

// ── Financial report ──────────────────────────────────────────────────
class FinancialReport {
  final String year;
  final String period;
  final String link;
  final String type;
  const FinancialReport({required this.year, required this.period, required this.link, required this.type});
}

// ── Board member (compinfo, board, exec, auditors) ────────────────────
class BoardMember {
  final String name;
  final String position;
  final String bodType;
  const BoardMember({required this.name, required this.position, required this.bodType});
  factory BoardMember.fromJson(Map<String, dynamic> j) => BoardMember(
    name:     j['Name']     ?? '—',
    position: j['Position'] ?? '',
    bodType:  j['BODType']  ?? '',
  );
}

class CompanyInfo {
  final Map<String, dynamic> raw;
  final List<BoardMember> board;
  final List<BoardMember> executive;
  final List<BoardMember> auditors;
  const CompanyInfo({required this.raw, required this.board, required this.executive, required this.auditors});

  factory CompanyInfo.fromJson(Map<String, dynamic> j) {
    final info = ((j['Company Information'] as List?) ?? []);
    final raw = info.isNotEmpty ? info[0] as Map<String, dynamic> : <String, dynamic>{};
    return CompanyInfo(
      raw:       raw,
      board:     ((j['Board of Directors']   as List?) ?? []).map((e) => BoardMember.fromJson(e as Map<String,dynamic>)).toList(),
      executive: ((j['Executive Management'] as List?) ?? []).map((e) => BoardMember.fromJson(e as Map<String,dynamic>)).toList(),
      auditors:  ((j['Auditors']             as List?) ?? []).map((e) => BoardMember.fromJson(e as Map<String,dynamic>)).toList(),
    );
  }

  String get companyName   => raw['NameEng']?.toString()            ?? '';
  String get activity      => raw['ActivitiesEng']?.toString().trim() ?? '';
  String get website       => raw['Website']?.toString()            ?? '';
  String get email         => raw['EMail']?.toString()              ?? '';
  String get phone         => raw['Telephone']?.toString()          ?? '';
  String get fax           => raw['TeleFax']?.toString()            ?? '';
  String get address       => raw['AddressEng']?.toString().trim()  ?? '';
  String get employees     => raw['NoofEmployee']?.toString()       ?? '';
  String get localBranches => raw['LocalBranches']?.toString()      ?? '';
  String get extBranches   => raw['ExternalBranches']?.toString()   ?? '';
  String get fiscalEnd     => raw['FiscalYearEnd']?.toString()      ?? '';
  String get contactName   => raw['ContactNameE']?.toString()       ?? '';
  String get contactPhone  => raw['ContactPhone']?.toString()       ?? '';
  String get poBox         => raw['POBoxEng']?.toString().trim()    ?? '';

  String get listingDate {
    final s = raw['ListingDate']?.toString() ?? '';
    return s.length >= 8 ? '${s.substring(0,4)}-${s.substring(4,6)}-${s.substring(6,8)}' : s;
  }
  String get establishedOn {
    final s = raw['EstablishedOn']?.toString() ?? '';
    return s.length >= 8 ? '${s.substring(0,4)}-${s.substring(4,6)}-${s.substring(6,8)}' : s;
  }
  String fmtNum(String key) {
    final v = raw[key];
    if (v == null) return '—';
    final n = double.tryParse(v.toString());
    if (n == null) return v.toString();
    return n.toStringAsFixed(n == n.truncateToDouble() ? 0 : 2)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  }
}

// ── Stock price ───────────────────────────────────────────────────────
class StockPrice {
  final String ticker;
  final String longName;
  final String exchange;
  final String currency;
  final double price;
  final double prevClose;
  final double change;
  final double changePct;
  final double dayHigh;
  final double dayLow;
  final int volume;
  final double fiftyTwoHigh;
  final double fiftyTwoLow;

  const StockPrice({
    required this.ticker, required this.longName, required this.exchange,
    required this.currency, required this.price, required this.prevClose,
    required this.change, required this.changePct, required this.dayHigh,
    required this.dayLow, required this.volume, required this.fiftyTwoHigh,
    required this.fiftyTwoLow,
  });

  factory StockPrice.fromYahooMeta(Map<String, dynamic> meta) {
    final price     = (meta['regularMarketPrice'] as num?)?.toDouble()    ?? 0;
    final prevClose = (meta['chartPreviousClose'] as num?)?.toDouble()    ??
                      (meta['previousClose']      as num?)?.toDouble()    ?? 0;
    return StockPrice(
      ticker:       meta['symbol']?.toString()           ?? '',
      longName:     meta['longName']?.toString()         ?? meta['shortName']?.toString() ?? '',
      exchange:     meta['fullExchangeName']?.toString() ?? meta['exchangeName']?.toString() ?? '',
      currency:     meta['currency']?.toString()         ?? 'KWF',
      price:        price,
      prevClose:    prevClose,
      change:       price - prevClose,
      changePct:    prevClose > 0 ? ((price - prevClose) / prevClose) * 100 : 0,
      dayHigh:      (meta['regularMarketDayHigh'] as num?)?.toDouble()   ?? 0,
      dayLow:       (meta['regularMarketDayLow']  as num?)?.toDouble()   ?? 0,
      volume:       (meta['regularMarketVolume']  as num?)?.toInt()      ?? 0,
      fiftyTwoHigh: (meta['fiftyTwoWeekHigh']     as num?)?.toDouble()   ?? 0,
      fiftyTwoLow:  (meta['fiftyTwoWeekLow']      as num?)?.toDouble()   ?? 0,
    );
  }
}

// ── Market index ──────────────────────────────────────────────────────
class MarketIndex {
  final String nameAr;
  final String symbol;
  final double price;
  final double change;
  final double changePct;
  final double dayHigh;
  final double dayLow;
  const MarketIndex({
    required this.nameAr, required this.symbol,
    required this.price, required this.change, required this.changePct,
    required this.dayHigh, required this.dayLow,
  });

  factory MarketIndex.fromMeta(String nameAr, String symbol, Map<String, dynamic> meta) {
    final price     = (meta['regularMarketPrice'] as num?)?.toDouble()  ?? 0;
    final prevClose = (meta['chartPreviousClose'] as num?)?.toDouble()  ??
                      (meta['previousClose']      as num?)?.toDouble()  ?? 0;
    return MarketIndex(
      nameAr:    nameAr,
      symbol:    symbol,
      price:     price,
      change:    price - prevClose,
      changePct: prevClose > 0 ? ((price - prevClose) / prevClose) * 100 : 0,
      dayHigh:   (meta['regularMarketDayHigh'] as num?)?.toDouble() ?? 0,
      dayLow:    (meta['regularMarketDayLow']  as num?)?.toDouble() ?? 0,
    );
  }
}
