import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // ── Replace with your GAS Web App URL ────────────────────────────────
  static const String gasUrl =
      'https://script.google.com/macros/s/AKfycbwPOu8arF4k96Ti7ZezJMpMgywJEkuc4ilmrHTSw2j8hhVnYw_-L8B90MlmMzY07fYsjQ/exec';

  static const Map<String, String> periodMap = {
    '1':'الربع الأول','2':'الربع الثاني','3':'الربع الثالث',
    '4':'الربع الرابع','5':'سنوي','6':'نصف سنوي',
    '7':'الربع الثاني','8':'الربع الأول',
  };

  // ── GAS proxy (Boursa Kuwait APIs) ───────────────────────────────────
  static Future<dynamic> proxyFetch(String apiUrl) async {
    final uri = Uri.parse('$gasUrl?action=proxy&url=${Uri.encodeComponent(apiUrl)}');
    final res = await http.get(uri).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return json.decode(utf8.decode(res.bodyBytes));
  }

  // ── Company list from a given sheet ──────────────────────────────────
  static Future<List<Company>> getCompanies(String sheet) async {
    final uri = Uri.parse('$gasUrl?action=companies&sheet=$sheet');
    final res = await http.get(uri).timeout(const Duration(seconds: 30));
    final data = json.decode(utf8.decode(res.bodyBytes));
    if (data['success'] != true) return [];
    return (data['companies'] as List)
        .map((c) => Company.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // ── Global disclosure URLs (daily / previous) ─────────────────────────
  static Future<Map<String, String>> getGlobalUrls(String sheet) async {
    final uri = Uri.parse('$gasUrl?action=globalUrls&sheet=$sheet');
    final res = await http.get(uri).timeout(const Duration(seconds: 30));
    final data = json.decode(utf8.decode(res.bodyBytes));
    return {'daily': data['daily'] ?? '', 'previous': data['previous'] ?? ''};
  }

  // ── Yahoo Finance index / stock ───────────────────────────────────────
  static Future<Map<String, dynamic>?> fetchYahooMeta(String symbol) async {
    try {
      final url = 'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=1d&range=1d';
      final res = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body);
      final result = data['chart']?['result'];
      if (result == null || (result as List).isEmpty) return null;
      return (result[0] as Map<String, dynamic>)['meta'] as Map<String, dynamic>?;
    } catch (_) { return null; }
  }

  // ── Parse disclosures from raw API response ───────────────────────────
  static List<DisclosureItem> parseDisclosures(dynamic data, {bool sort = false}) {
    List items = data is List ? data : [data];
    items = items.where((i) => i['Title'] != 'الشركات الموقوفة عن التداول').toList();
    if (sort) items.sort((a, b) => (b['PostedDate'] ?? '').compareTo(a['PostedDate'] ?? ''));
    return items.take(50).map((i) => DisclosureItem.fromJson(i as Map<String,dynamic>)).toList();
  }

  // ── Parse insider sections ────────────────────────────────────────────
  static List<InsiderSection> parseInsiders(dynamic data) {
    final sections = data is List ? data : [data];
    final result = <InsiderSection>[];
    for (final sec in sections) {
      final type     = sec['InsiderType'] as int? ?? 0;
      final header   = sec['HeaderAr']?.toString() ?? '';
      final insiders = (sec['CompaniesInsiders'] as List?) ?? [];
      if (type == 3) {
        final entities = insiders.map((p) => InsiderEntity(
          name:     p['InstitutionNameAr'] ?? p['InstitutionNameEng'] ?? '—',
          relation: (p['RelationshipAr']   ?? p['RelationshipEng']   ?? '').toString().trim(),
          hq:       (p['InstitutionHQAr']  ?? p['InstitutionHQEng']  ?? '').toString().trim(),
        )).toList();
        result.add(InsiderSection(header: header, type: type, people: [], entities: entities));
      } else {
        final people = insiders.map((p) => InsiderPerson(
          name:  p['InvestorNameAr'] ?? p['InvestorNameEng'] ?? '—',
          title: (p['TitleAr'] ?? p['TitleEng'] ?? '—').toString().trim(),
        )).toList();
        result.add(InsiderSection(header: header, type: type, people: people, entities: []));
      }
    }
    return result.where((s) => s.people.isNotEmpty || s.entities.isNotEmpty).toList();
  }

  // ── Parse financial reports ───────────────────────────────────────────
  static List<FinancialReport> parseFinancials(dynamic data) {
    final fields = ((data['dataFields'] as List?) ?? []);
    fields.sort((a, b) {
      final yc = (b['year'] ?? '').compareTo(a['year'] ?? '');
      return yc != 0 ? yc : (b['activatedDate'] ?? '').compareTo(a['activatedDate'] ?? '');
    });
    final reports = <FinancialReport>[];
    for (final item in fields.take(30)) {
      for (final f in ((item['fileNames'] as List?) ?? [])) {
        final link = f['fileName']?.toString() ?? '';
        if (link.isEmpty) continue;
        final period = periodMap[item['period']?.toString()] ?? 'فترة ${item['period']}';
        reports.add(FinancialReport(
          year: item['year']?.toString() ?? '—',
          period: period,
          link: link,
          type: f['type']?.toString() ?? 'PDF',
        ));
      }
    }
    return reports;
  }
}
