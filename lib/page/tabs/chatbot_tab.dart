import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
      desc: 'Sirup tetes / Drops',
      icon: Icons.child_care_rounded,
    ),
    AgeOption(
      label: 'Anak-anak',
      category: 'Anak (2-12 tahun)',
      defaultAge: 7,
      desc: 'Sirup anak',
      icon: Icons.escalator_warning_rounded,
    ),
    AgeOption(
      label: 'Dewasa',
      category: 'Dewasa (12-59 tahun)',
      defaultAge: 25,
      desc: 'Tablet & Kapsul',
      icon: Icons.person_rounded,
    ),
    AgeOption(
      label: 'Lansia',
      category: 'Lansia (≥ 60 tahun)',
      defaultAge: 65,
      desc: 'Dosis aman lansia',
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
          'Halo! Saya MediBot, asisten apoteker virtual MediFinder 🩺\n\nAgar rekomendasi obat dan bentuk sediaan (sirup/tablet) tepat dan aman, silakan pilih kelompok usia pasien terlebih dahulu:',
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: AppUi.primary),
            const SizedBox(width: 8),
            Text(
              'Reset Percakapan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin memulai percakapan baru dengan MediBot?',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey[700])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppUi.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            child: Text('Reset', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _isLoading) return;

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
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
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
  List<InlineSpan> _parseMarkdownSpans(String text, TextStyle baseStyle, bool isUser) {
    final List<InlineSpan> spans = [];
    final regex = RegExp(
      r'(\*\*\*(.+?)\*\*\*|\*\*(.+?)\*\*|\*(.+?)\*|__(.+?)__|_(.+?)_|`(.+?)`)',
      dotAll: true,
    );

    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      final matchedText = match.group(0)!;
      if (matchedText.startsWith('***') && matchedText.endsWith('***')) {
        spans.add(TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: isUser ? Colors.white : const Color(0xFF0F172A),
          ),
        ));
      } else if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        spans.add(TextSpan(
          text: match.group(3),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w700,
            color: isUser ? Colors.white : const Color(0xFF0F172A),
          ),
        ));
      } else if (matchedText.startsWith('*') && matchedText.endsWith('*')) {
        spans.add(TextSpan(
          text: match.group(4),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (matchedText.startsWith('__') && matchedText.endsWith('__')) {
        spans.add(TextSpan(
          text: match.group(5),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w700,
            color: isUser ? Colors.white : const Color(0xFF0F172A),
          ),
        ));
      } else if (matchedText.startsWith('_') && matchedText.endsWith('_')) {
        spans.add(TextSpan(
          text: match.group(6),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (matchedText.startsWith('`') && matchedText.endsWith('`')) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: isUser ? Colors.white24 : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              match.group(7) ?? '',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: isUser ? Colors.white : const Color(0xFF0F756B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }

  Widget _buildFormattedText(String text, {required bool isUser}) {
    final baseStyle = GoogleFonts.poppins(
      fontSize: 13,
      height: 1.48,
      color: isUser ? Colors.white : Colors.black87,
    );

    return Text.rich(
      TextSpan(children: _parseMarkdownSpans(text, baseStyle, isUser)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // 1. Header MediBot
          _buildHeader(),

          // 2. Chat Feed
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessageBubble(_messages[index]);
                }
                return _buildTypingIndicator();
              },
            ),
          ),

          // 3. Quick Suggestions (jika tidak sedang loading dan usia sudah dipilih)
          if (!_isLoading && _selectedAgeGroup.isNotEmpty) _buildQuickSuggestions(),

          // 4. Input Box
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F756B), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'MediBot AI',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5F3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AI Asisten',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppUi.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _selectedAgeGroup.isEmpty
                      ? 'Konsultasi Gejala & Rekomendasi Obat'
                      : 'Pasien: $_selectedAgeGroup',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: _selectedAgeGroup.isEmpty ? Colors.grey[600] : AppUi.primary,
                    fontWeight: _selectedAgeGroup.isEmpty ? FontWeight.w400 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Mulai Ulang Chat',
            icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
            onPressed: _resetChat,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.sender == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.only(right: 8, bottom: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F756B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🩺', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isUser ? AppUi.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildFormattedText(msg.text, isUser: isUser),
                ),
              ),
            ],
          ),

          // Opsi kelompok usia jika welcome dan belum memilih usia
          if (msg.id == 'welcome' && _selectedAgeGroup.isEmpty) _buildAgeSelector(),

          // Kartu rekomendasi apotek jika bot mengembalikan apotek
          if (msg.data != null && msg.data!.pharmacies.isNotEmpty)
            _buildPharmacyRecommendations(msg.data!),

          // Notice jika obat tidak tersedia
          if (msg.data != null &&
              msg.data!.availability == 'EMPTY' &&
              msg.data!.medicineName.isNotEmpty)
            _buildEmptyAlert(msg.data!.medicineName),
        ],
      ),
    );
  }

  Widget _buildAgeSelector() {
    return Container(
      margin: const EdgeInsets.only(left: 38, top: 10, right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0F2F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Kelompok Usia Pasien:',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: _ageOptions.map((opt) {
              return InkWell(
                onTap: () => _selectAge(opt),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5F3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFB2DFDB)),
                  ),
                  child: Row(
                    children: [
                      Icon(opt.icon, size: 22, color: AppUi.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              opt.label,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: AppUi.primaryDark,
                              ),
                            ),
                            Text(
                              opt.desc,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyRecommendations(ChatResponseData data) {
    return Container(
      margin: const EdgeInsets.only(left: 38, top: 10, right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: data.isNearby ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: data.isNearby ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  data.isNearby ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 13,
                  color: data.isNearby ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                ),
                const SizedBox(width: 5),
                Text(
                  data.isNearby ? 'Tersedia di Apotek Terdekat' : 'Tersedia di Luar Jangkauan Sekitar',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: data.isNearby ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          ...data.pharmacies.map((pharm) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          pharm.nama,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5F3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${pharm.distanceKm.toStringAsFixed(1)} km',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppUi.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pharm.alamat,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: pharm.isOpen ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pharm.isOpen
                              ? 'Buka (Tutup ${pharm.jamTutup})'
                              : 'Tutup (Buka ${pharm.jamBuka})',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: pharm.isOpen ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Rp ${pharm.harga.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppUi.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Stok: ${pharm.stok}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: const BorderSide(color: AppUi.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            if (pharm.apotekId.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailApotek1(idApotek: pharm.apotekId),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.store_rounded, size: 15, color: AppUi.primary),
                          label: Text(
                            'Detail Apotek',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppUi.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            backgroundColor: AppUi.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _openGoogleMaps(pharm.latitude, pharm.longitude),
                          icon: const Icon(Icons.directions_rounded, size: 15),
                          label: Text(
                            'Rute Maps',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyAlert(String medicineName) {
    return Container(
      margin: const EdgeInsets.only(left: 38, top: 10, right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF57F17), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Stok $medicineName saat ini belum ditemukan di apotek terdekat. Anda dapat mencari apotek lain melalui menu Cari Apotek.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF5D4037),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F756B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('🩺', style: TextStyle(fontSize: 14)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppUi.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'MediBot sedang menganalisis...',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _quickSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _quickSuggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: Colors.white,
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.06),
              side: const BorderSide(color: Color(0xFFB2DFDB)),
              label: Text(
                suggestion,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppUi.primaryDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () => _sendMessage(suggestion),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: _sendMessage,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: _selectedAgeGroup.isEmpty
                        ? 'Pilih usia pasien terlebih dahulu...'
                        : 'Tulis keluhan atau gejala Anda...',
                    hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppUi.primary, Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppUi.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _isLoading ? null : () => _sendMessage(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
