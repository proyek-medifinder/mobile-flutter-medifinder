import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:medifinder/page/widgets/clinical_widgets.dart';
import 'package:medifinder/page/detail_apotek1.dart';
import 'package:medifinder/providers.dart';
import 'package:medifinder/services/chatbot_service.dart';
import 'package:medifinder/services/location_service.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class AgeOption {
  final String label;
  final String category;
  final int defaultAge;
  final String desc;
  final IconData icon;

  const AgeOption({
    required this.label,
    required this.category,
    required this.defaultAge,
    required this.desc,
    required this.icon,
  });
}

class ChatbotTab extends ConsumerStatefulWidget {
  const ChatbotTab({super.key});

  @override
  ConsumerState<ChatbotTab> createState() => _ChatbotTabState();
}

class _ChatbotTabState extends ConsumerState<ChatbotTab> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  String _selectedAgeGroup = '';
  int _selectedAge = 0;
  List<ChatMessage> _messages = [];

  static const List<AgeOption> _ageOptions = [
    AgeOption(
      label: 'Balita',
      category: 'Balita (< 2 tahun)',
      defaultAge: 1,
      desc: '< 2 tahun',
      icon: Icons.child_care_rounded,
    ),
    AgeOption(
      label: 'Anak-anak',
      category: 'Anak (2-12 tahun)',
      defaultAge: 7,
      desc: '2–12 tahun',
      icon: Icons.escalator_warning_rounded,
    ),
    AgeOption(
      label: 'Dewasa',
      category: 'Dewasa (12-59 tahun)',
      defaultAge: 25,
      desc: '12–59 tahun',
      icon: Icons.person_rounded,
    ),
    AgeOption(
      label: 'Lansia',
      category: 'Lansia (≥ 60 tahun)',
      defaultAge: 65,
      desc: '60+ tahun',
      icon: Icons.elderly_rounded,
    ),
  ];

  static const List<String> _quickSuggestions = [
    'Obat flu & batuk berdahak',
    'Asam lambung / maag perih',
    'Sakit kepala & pusing berdenyut',
    'Alergi gatal-gatal pada kulit',
    'Demam tinggi & badan pegal',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialChat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  ChatMessage _createWelcomeMessage() {
    return ChatMessage(
      id: 'welcome',
      sender: 'bot',
      text:
          'Halo! Saya MediBot. Pilih kelompok usia pasien, lalu ceritakan keluhan atau tanyakan informasi obat.',
      timestamp: DateTime.now(),
    );
  }

  Future<void> _loadInitialChat() async {
    final chatbotService = ref.read(chatbotServiceProvider);
    final saved = await chatbotService.loadHistory();

    if (mounted) {
      setState(() {
        if (saved != null && (saved['messages'] as List).isNotEmpty) {
          _messages = saved['messages'] as List<ChatMessage>;
          _selectedAgeGroup = saved['ageGroup'] as String? ?? '';
          _selectedAge = saved['age'] as int? ?? 0;
        } else {
          _messages = [_createWelcomeMessage()];
        }
      });
      _scrollToBottom();
    }
  }

  Future<void> _persistChat() async {
    final chatbotService = ref.read(chatbotServiceProvider);
    await chatbotService.saveHistory(
      messages: _messages,
      ageGroup: _selectedAgeGroup,
      age: _selectedAge,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _selectAge(AgeOption option) {
    setState(() {
      _selectedAgeGroup = option.category;
      _selectedAge = option.defaultAge;
    });

    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'user',
        text: 'Kelompok usia: **${option.label}** (${option.category})',
        timestamp: DateTime.now(),
      ),
    );

    _messages.add(
      ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        sender: 'bot',
        text:
            'Baik, informasi usia pasien dicatat (**${option.label}**).\n\nApa keluhan atau gejala yang sedang dirasakan? Tuliskan dengan jelas agar saya dapat membantu merekomendasikan obat yang sesuai.',
        timestamp: DateTime.now(),
      ),
    );

    _persistChat();
    _scrollToBottom();
  }

  void _resetChat() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.refresh_rounded,
                  color: AppUi.colors(context).primaryText,
                ),
                const SizedBox(width: 8),
                Text(
                  'Reset Percakapan',
                  style: AppUi.text(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ],
            ),
            content: Text(
              'Apakah Anda yakin ingin memulai percakapan baru dengan MediBot?',
              style: AppUi.text(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Batal',
                  style: AppUi.text(color: Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppUi.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final chatbotService = ref.read(chatbotServiceProvider);
                  await chatbotService.clearHistory();
                  if (mounted) {
                    setState(() {
                      _selectedAgeGroup = '';
                      _selectedAge = 0;
                      _messages = [_createWelcomeMessage()];
                    });
                  }
                },
                child: Text(
                  'Reset',
                  style: AppUi.text(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _isLoading || _selectedAgeGroup.isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: 'user',
          text: cleanText,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final userLoc = ref.read(userLocationProvider);
      double lat = userLoc?.lat ?? 0.0;
      double lng = userLoc?.lng ?? 0.0;

      if (lat == 0.0 && lng == 0.0) {
        final pos = await LocationService.getCurrentPosition();
        if (pos != null) {
          lat = pos.latitude;
          lng = pos.longitude;
        }
      }

      final chatbotService = ref.read(chatbotServiceProvider);
      final responseData = await chatbotService.sendMessage(
        message: cleanText,
        ageGroup: _selectedAgeGroup,
        age: _selectedAge,
        latitude: lat,
        longitude: lng,
      );

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
              sender: 'bot',
              text: responseData.reply,
              timestamp: DateTime.now(),
              data: responseData,
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
              sender: 'bot',
              text:
                  'Maaf, terjadi kendala saat memproses permintaan Anda.\nPastikan server backend terhubung dan coba sesaat lagi.',
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _persistChat();
        _scrollToBottom();
      }
    }
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
        );
      }
    }
  }

  // Parser markdown sederhana untuk bold (**teks**), italic (*teks*), dan code (`teks`)
  List<InlineSpan> _parseMarkdownSpans(
    String text,
    TextStyle baseStyle,
    bool isUser,
  ) {
    final List<InlineSpan> spans = [];
    final regex = RegExp(
      r'(\*\*\*(.+?)\*\*\*|\*\*(.+?)\*\*|\*(.+?)\*|__(.+?)__|_(.+?)_|`(.+?)`)',
      dotAll: true,
    );

    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: baseStyle,
          ),
        );
      }

      final matchedText = match.group(0)!;
      if (matchedText.startsWith('***') && matchedText.endsWith('***')) {
        spans.add(
          TextSpan(
            text: match.group(2),
            style: baseStyle.copyWith(
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: isUser ? Colors.white : AppUi.colors(context).ink,
            ),
          ),
        );
      } else if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        spans.add(
          TextSpan(
            text: match.group(3),
            style: baseStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: isUser ? Colors.white : AppUi.colors(context).ink,
            ),
          ),
        );
      } else if (matchedText.startsWith('*') && matchedText.endsWith('*')) {
        spans.add(
          TextSpan(
            text: match.group(4),
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      } else if (matchedText.startsWith('__') && matchedText.endsWith('__')) {
        spans.add(
          TextSpan(
            text: match.group(5),
            style: baseStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: isUser ? Colors.white : AppUi.colors(context).ink,
            ),
          ),
        );
      } else if (matchedText.startsWith('_') && matchedText.endsWith('_')) {
        spans.add(
          TextSpan(
            text: match.group(6),
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      } else if (matchedText.startsWith('`') && matchedText.endsWith('`')) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: isUser ? Colors.white24 : AppUi.colors(context).muted,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                match.group(7) ?? '',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color:
                      isUser ? Colors.white : AppUi.colors(context).primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: baseStyle));
    }

    return spans;
  }

  Widget _buildFormattedText(String text, {required bool isUser}) {
    final baseStyle = AppUi.text(
      fontSize: 13,
      height: 1.48,
      color: isUser ? Colors.white : AppUi.colors(context).ink,
    );

    return Text.rich(
      TextSpan(children: _parseMarkdownSpans(text, baseStyle, isUser)),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          itemCount: _messages.length + 1 + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 14),
                  ContentPanel(
                    padding: 14,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color:
                              AppUi.colors(context).isDark
                                  ? const Color(0xFFFABC2A)
                                  : const Color(0xFF876200),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Informasi bersifat edukatif, bukan pengganti diagnosis atau resep dokter.',
                            style: AppUi.text(
                              fontSize: 12,
                              color: AppUi.colors(context).secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAgeSelector(),
                  const SizedBox(height: 20),
                ],
              );
            }
            if (index <= _messages.length) {
              return _buildMessageBubble(_messages[index - 1]);
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text('MediBot sedang menyiapkan jawaban...')),
                ],
              ),
            );
          },
        ),
      ),
      if (!_isLoading &&
          _selectedAgeGroup.isNotEmpty &&
          MediaQuery.viewInsetsOf(context).bottom == 0)
        _buildQuickSuggestions(),
      _buildInputBar(),
    ],
  );
  Widget _buildHeader() => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppUi.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.smart_toy_outlined,
          color: Colors.white,
          size: 27,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MediBot Asisten AI',
              style: AppUi.text(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppUi.colors(context).primaryText,
              ),
            ),
            Text(
              'Informasi kesehatan & apotek sekitar',
              style: AppUi.text(
                fontSize: 12,
                color: AppUi.colors(context).secondary,
              ),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Mulai percakapan baru',
        onPressed: _isLoading ? null : _resetChat,
        icon: Icon(
          Icons.restart_alt_rounded,
          color: AppUi.colors(context).primaryText,
        ),
      ),
    ],
  );
  Widget _buildAgeSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Profil Pasien Konsultasi',
        style: AppUi.text(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 10),
      LayoutBuilder(
        builder:
            (context, c) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    _ageOptions.map((o) {
                      final selected = _selectedAgeGroup == o.category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Semantics(
                          selected: selected,
                          button: true,
                          child: Material(
                            color:
                                selected
                                    ? AppUi.primary
                                    : AppUi.colors(context).surface,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              onTap: _isLoading ? null : () => _selectAge(o),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width:
                                    ((c.maxWidth - 24) / 4)
                                        .clamp(80, 110)
                                        .toDouble(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 12,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      o.icon,
                                      color:
                                          selected
                                              ? Colors.white
                                              : AppUi.colors(
                                                context,
                                              ).primaryText,
                                      size: 23,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      o.label,
                                      style: AppUi.text(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            selected
                                                ? Colors.white
                                                : AppUi.colors(context).ink,
                                      ),
                                    ),
                                    Text(
                                      o.desc,
                                      style: AppUi.text(
                                        fontSize: 10,
                                        color:
                                            selected
                                                ? Colors.white
                                                : AppUi.colors(
                                                  context,
                                                ).secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
      ),
    ],
  );
  Widget _buildMessageBubble(ChatMessage msg) {
    final user = msg.sender == 'user';
    final time =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}.${msg.timestamp.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment:
            user ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(left: user ? 32 : 0, right: user ? 0 : 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: user ? AppUi.primaryDark : AppUi.colors(context).surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(22),
                topRight: const Radius.circular(22),
                bottomLeft: Radius.circular(user ? 22 : 6),
                bottomRight: Radius.circular(user ? 6 : 22),
              ),
              boxShadow: AppUi.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!user) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.smart_toy_outlined,
                        color: AppUi.colors(context).primaryText,
                        size: 18,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'MediBot',
                          style: AppUi.text(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppUi.colors(context).primaryText,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: AppUi.text(
                          fontSize: 10,
                          color: AppUi.colors(context).secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                _buildFormattedText(msg.text, isUser: user),
                if (msg.data != null && msg.data!.pharmacies.isNotEmpty)
                  _buildPharmacyRecommendations(msg.data!),
                if (msg.data?.availability == 'EMPTY')
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Stok obat belum ditemukan. Hubungi apotek untuk memastikan ketersediaan.',
                      style: AppUi.text(
                        fontSize: 12,
                        color: AppUi.colors(context).secondary,
                      ),
                    ),
                  ),
                if (!user)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Salin jawaban',
                      icon: Icon(
                        Icons.copy_outlined,
                        size: 17,
                        color: AppUi.colors(context).secondary,
                      ),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: msg.text));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Jawaban disalin.')),
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (user)
            Padding(
              padding: const EdgeInsets.only(top: 5, right: 3),
              child: Text(
                time,
                style: AppUi.text(
                  fontSize: 10,
                  color: AppUi.colors(context).secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPharmacyRecommendations(ChatResponseData data) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.medicineName.isEmpty
              ? 'Apotek yang Ditemukan'
              : 'Apotek Penyedia ${data.medicineName}',
          style: AppUi.text(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...data.pharmacies.map(
          (p) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppUi.colors(context).muted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nama,
                  style: AppUi.text(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusPill(
                      p.isOpen ? 'Buka' : 'Tutup',
                      color:
                          p.isOpen
                              ? const Color(0xFF1B8A5A)
                              : const Color(0xFFC0392B),
                    ),
                    StatusPill('${p.distanceKm.toStringAsFixed(1)} km'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Stok ${p.stok} · ${rupiah(p.harga)}',
                  style: AppUi.text(
                    fontSize: 12,
                    color: AppUi.colors(context).primaryText,
                  ),
                ),
                Text(
                  p.alamat,
                  style: AppUi.text(
                    fontSize: 11,
                    color: AppUi.colors(context).secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    TextButton(
                      onPressed:
                          p.apotekId.isEmpty
                              ? null
                              : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          DetailApotek1(idApotek: p.apotekId),
                                ),
                              ),
                      child: const Text('Lihat Apotek'),
                    ),
                    TextButton.icon(
                      onPressed: () => _openGoogleMaps(p.latitude, p.longitude),
                      icon: const Icon(Icons.directions_outlined, size: 17),
                      label: const Text('Rute'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  Widget _buildQuickSuggestions() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
    child: Row(
      children:
          _quickSuggestions
              .take(3)
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(
                      s,
                      style: AppUi.text(
                        fontSize: 11,
                        color: AppUi.colors(context).primaryText,
                      ),
                    ),
                    onPressed: () => _sendMessage(s),
                    backgroundColor: AppUi.colors(context).surface,
                    side: BorderSide.none,
                  ),
                ),
              )
              .toList(),
    ),
  );
  Widget _buildInputBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
    child: Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
      decoration: AppUi.panelDecoration(
        radius: 22,
        color: AppUi.colors(context).surface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              enabled: !_isLoading && _selectedAgeGroup.isNotEmpty,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              style: AppUi.text(fontSize: 13),
              decoration: InputDecoration(
                hintText:
                    _selectedAgeGroup.isEmpty
                        ? 'Pilih usia pasien terlebih dahulu'
                        : 'Tuliskan keluhan atau nama obat...',
                fillColor: AppUi.colors(context).surface,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: IconButton.filled(
              tooltip: 'Kirim pesan',
              onPressed:
                  _isLoading || _selectedAgeGroup.isEmpty
                      ? null
                      : () => _sendMessage(_textController.text),
              style: IconButton.styleFrom(
                backgroundColor: AppUi.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(46, 46),
              ),
              icon:
                  _isLoading
                      ? const SizedBox.square(
                        dimension: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.send_rounded, size: 22),
            ),
          ),
        ],
      ),
    ),
  );
}
