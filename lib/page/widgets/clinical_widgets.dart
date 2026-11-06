import 'package:flutter/material.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class ContentPanel extends StatelessWidget {
  const ContentPanel({
    super.key,
    required this.child,
    this.padding = 20,
    this.color,
  });
  final Widget child;
  final double padding;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(padding),
    decoration: AppUi.panelDecoration(
      color: color ?? AppUi.colors(context).surface,
    ),
    child: child,
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppUi.text(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppUi.text(
                    fontSize: 13,
                    color: AppUi.colors(context).secondary,
                  ),
                ),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(
    this.label, {
    super.key,
    this.color = AppUi.primary,
    this.icon,
  });
  final String label;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppUi.colors(context).status(color).withValues(alpha: .12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: AppUi.colors(context).status(color)),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            label,
            style: AppUi.text(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppUi.colors(context).status(color),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    style: AppUi.text(fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      fillColor: AppUi.colors(context).surface,
      prefixIcon: Icon(
        Icons.search_rounded,
        color: AppUi.colors(context).primaryText,
        size: 22,
      ),
      suffixIcon:
          controller.text.isEmpty
              ? null
              : IconButton(
                tooltip: 'Hapus pencarian',
                icon: const Icon(Icons.close_rounded, size: 19),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
    ),
  );
}

class FilterPills extends StatelessWidget {
  const FilterPills({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: List.generate(
        labels.length,
        (i) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(labels[i]),
            selected: selected == i,
            onSelected: (_) => onSelected(i),
            showCheckmark: false,
            labelStyle: AppUi.text(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  selected == i
                      ? Colors.white
                      : AppUi.colors(context).primaryText,
            ),
            backgroundColor: AppUi.colors(context).surface,
            selectedColor: AppUi.primary,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(99),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          ),
        ),
      ),
    ),
  );
}

class DataState extends StatelessWidget {
  const DataState({
    super.key,
    required this.title,
    this.subtitle,
    this.onRetry,
    this.loading = false,
  });
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;
  final bool loading;
  @override
  Widget build(BuildContext context) => ContentPanel(
    child: Column(
      children: [
        if (loading)
          CircularProgressIndicator(
            color: AppUi.colors(context).primaryText,
            strokeWidth: 2,
          )
        else
          Icon(
            Icons.local_pharmacy_outlined,
            size: 32,
            color: AppUi.colors(context).primaryText,
          ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppUi.text(fontWeight: FontWeight.w600),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: AppUi.text(
              fontSize: 12,
              color: AppUi.colors(context).secondary,
            ),
          ),
        ],
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
      ],
    ),
  );
}

class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key, this.photo, this.radius = 20});
  final String? photo;
  final double radius;
  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox.square(
      dimension: radius * 2,
      child:
          photo?.isNotEmpty == true
              ? Image.network(
                photo!,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => _fallback(context),
              )
              : _fallback(context),
    ),
  );
  Widget _fallback(BuildContext context) => Container(
    color: AppUi.colors(context).softTeal,
    child: Icon(
      Icons.person_outline_rounded,
      color: AppUi.colors(context).primaryText,
      size: radius,
    ),
  );
}

class BotBanner extends StatelessWidget {
  const BotBanner({super.key, required this.onTap, this.compact = false});
  final VoidCallback onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 16 : 20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppUi.primaryDark, Color(0xFF14B8A6)],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: AppUi.cardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tanya MediBot AI',
                style: AppUi.text(
                  fontSize: compact ? 17 : 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            if (compact)
              IconButton(
                tooltip: 'Buka MediBot',
                onPressed: onTap,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
              ),
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: 8),
          Text(
            'Cari informasi obat dan apotek sesuai kebutuhan Anda.',
            style: AppUi.text(fontSize: 13, color: Colors.white),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: AppUi.colors(context).surface,
              foregroundColor: AppUi.colors(context).primaryText,
              minimumSize: const Size(48, 42),
            ),
            label: const Text('Mulai Tanya Sekarang'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ],
    ),
  );
}

Future<void> openExternal(BuildContext context, Uri uri) async {
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {}
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tautan belum bisa dibuka. Coba lagi.')),
    );
  }
}

String rupiah(double value) =>
    'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
