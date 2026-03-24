import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

const kNavy    = Color(0xFF0A1628);
const kNavy2   = Color(0xFF0F2044);
const kBlue    = Color(0xFF1A3A6B);
const kCard    = Color(0xFF111E36);
const kCard2   = Color(0xFF162540);
const kBorder  = Color(0xFF1E3358);
const kGold    = Color(0xFFC8A84B);
const kGold2   = Color(0xFFE8C96A);
const kMuted   = Color(0xFF8A9AB8);
const kGreen   = Color(0xFF2ECC71);
const kRed     = Color(0xFFE74C3C);

// ── Loading shimmer ───────────────────────────────────────────────────
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kCard,
      highlightColor: kCard2,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 72,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ── Error widget ──────────────────────────────────────────────────────
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AppErrorWidget({super.key, required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: kRed),
            const SizedBox(height: 16),
            Text('فشل الاتصال', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700, color: kRed)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 12, color: kMuted)),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(backgroundColor: kGold, foregroundColor: kNavy),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty widget ──────────────────────────────────────────────────────
class EmptyWidget extends StatelessWidget {
  final String message;
  const EmptyWidget({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_rounded, size: 56, color: Color(0xFF3A4F72)),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.cairo(fontSize: 14, color: kMuted)),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? count;
  const SectionHeader({super.key, required this.icon, required this.title, this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kCard2,
        borderRadius: BorderRadius.circular(10),
        border: const Border(right: BorderSide(color: kGold, width: 3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kGold2),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: kGold2)),
          if (count != null) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: kGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: kGold2)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Info row (label + value) ──────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;
  const InfoRow({super.key, required this.label, required this.value, this.isLast = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: kBorder, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: GoogleFonts.cairo(fontSize: 11, color: kMuted)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Info block card ───────────────────────────────────────────────────
class InfoBlock extends StatelessWidget {
  final List<Widget> rows;
  const InfoBlock({super.key, required this.rows});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(children: rows),
    );
  }
}

// ── Person tile ───────────────────────────────────────────────────────
class PersonTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final Color avatarColor;
  final Color textColor;
  final String? badge;
  final Color? badgeColor;
  const PersonTile({super.key, required this.name, required this.subtitle,
    required this.avatarColor, required this.textColor, this.badge, this.badgeColor});
  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0] : '').join();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: avatarColor,
            child: Text(initials, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w800, color: textColor)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(subtitle, style: GoogleFonts.cairo(fontSize: 10, color: kMuted)),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (badgeColor ?? kMuted).withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badge!, style: GoogleFonts.cairo(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: badgeColor ?? kMuted,
              )),
            ),
        ],
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const StatCard({super.key, required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 10, color: kMuted)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.cairo(
            fontSize: 15, fontWeight: FontWeight.w700,
            color: valueColor ?? Colors.white,
          )),
        ],
      ),
    );
  }
}
