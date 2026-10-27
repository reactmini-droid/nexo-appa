import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NexoApp());
}

class NexoColors {
  // Dark Palette (Default)
  static const darkBg = Color(0xFF0F1115);
  static const darkSurface = Color(0xFF171A21);
  static const darkRaised = Color(0xFF1F2430);
  static const darkBorder = Color(0xFF2A2F3B);
  static const darkText = Color(0xFFE8EAF0);
  static const darkMuted = Color(0xFF9AA3B2);
  static const darkAccent = Color(0xFF4FD1B5);
  static const darkOnAccent = Color(0xFF06241D);
  static const danger = Color(0xFFF28B82);

  // Light Palette
  static const lightBg = Color(0xFFF6F7F9);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightRaised = Color(0xFFEAEEF5);
  static const lightBorder = Color(0xFFDADDE3);
  static const lightText = Color(0xFF14161B);
  static const lightMuted = Color(0xFF5A6270);
  static const lightAccent = Color(0xFF0E8F78);
}

/// Flat "Spark ring" Logo: lightning bolt inside a thick circular ring.
class SparkRingLogo extends StatelessWidget {
  final double size;
  final Color color;
  const SparkRingLogo({super.key, this.size = 28, this.color = NexoColors.darkAccent});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _SparkRingPainter(color),
    );
  }
}

class _SparkRingPainter extends CustomPainter {
  final Color color;
  _SparkRingPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 32.0;
    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * s;

    canvas.drawCircle(Offset(16 * s, 16 * s), 12.5 * s, ringPaint);

    final boltPath = Path()
      ..moveTo(17.2 * s, 7.8 * s)
      ..lineTo(10.2 * s, 17.2 * s)
      ..lineTo(15.5 * s, 17.2 * s)
      ..lineTo(14.8 * s, 24.2 * s)
      ..lineTo(21.8 * s, 14.8 * s)
      ..lineTo(16.5 * s, 14.8 * s)
      ..close();

    final boltPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(boltPath, boltPaint);
  }

  @override
  bool shouldRepaint(covariant _SparkRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

class EndpointConfig {
  String id;
  String name;
  String baseUrl;
  String apiKey;
  bool connected;
  List<String> models;

  EndpointConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    this.connected = true,
    required this.models,
  });
}

class ChatMessage {
  final String role;
  String content;
  int tokens;
  ChatMessage({required this.role, required this.content, this.tokens = 0});
}

class NexoApp extends StatefulWidget {
  const NexoApp({super.key});

  @override
  State<NexoApp> createState() => _NexoAppState();
}

class _NexoAppState extends State<NexoApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  double _textScale = 1.0;
  double _temperature = 0.7;
  int _maxTokens = 4096;
  String _knowAboutYou = '';
  String _howToRespond = 'Provide concise, accurate answers with clean code blocks.';
  bool _streamResponses = true;
  bool _enterToSend = true;
  bool _autoChatTitle = true;
  bool _showTokenCount = true;
  bool _hapticFeedback = true;
  bool _saveHistory = true;

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? NexoColors.darkBg : NexoColors.lightBg;
    final surface = isDark ? NexoColors.darkSurface : NexoColors.lightSurface;
    final border = isDark ? NexoColors.darkBorder : NexoColors.lightBorder;
    final text = isDark ? NexoColors.darkText : NexoColors.lightText;
    final muted = isDark ? NexoColors.darkMuted : NexoColors.lightMuted;
    final accent = isDark ? NexoColors.darkAccent : NexoColors.lightAccent;
    final onAccent = isDark ? NexoColors.darkOnAccent : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: onAccent,
        secondary: accent,
        onSecondary: onAccent,
        error: NexoColors.danger,
        onError: NexoColors.darkBg,
        surface: surface,
        onSurface: text,
        onSurfaceVariant: muted,
        outline: border,
      ),
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).apply(bodyColor: text, displayColor: text),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? NexoColors.darkBg : NexoColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexo',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(_textScale),
        ),
        child: child!,
      ),
      home: NexoChatHome(
        themeMode: _themeMode,
        onThemeChanged: (m) => setState(() => _themeMode = m),
        textScale: _textScale,
        onTextScaleChanged: (v) => setState(() => _textScale = v),
        temperature: _temperature,
        onTemperatureChanged: (v) => setState(() => _temperature = v),
        maxTokens: _maxTokens,
        onMaxTokensChanged: (v) => setState(() => _maxTokens = v),
        knowAboutYou: _knowAboutYou,
        onKnowChanged: (v) => setState(() => _knowAboutYou = v),
        howToRespond: _howToRespond,
        onRespondChanged: (v) => setState(() => _howToRespond = v),
        streamResponses: _streamResponses,
        onStreamChanged: (v) => setState(() => _streamResponses = v),
        enterToSend: _enterToSend,
        onEnterChanged: (v) => setState(() => _enterToSend = v),
        autoChatTitle: _autoChatTitle,
        onAutoTitleChanged: (v) => setState(() => _autoChatTitle = v),
        showTokenCount: _showTokenCount,
        onShowTokensChanged: (v) => setState(() => _showTokenCount = v),
        hapticFeedback: _hapticFeedback,
        onHapticChanged: (v) => setState(() => _hapticFeedback = v),
        saveHistory: _saveHistory,
        onSaveHistoryChanged: (v) => setState(() => _saveHistory = v),
      ),
    );
  }
}

class NexoChatHome extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final double textScale;
  final ValueChanged<double> onTextScaleChanged;
  final double temperature;
  final ValueChanged<double> onTemperatureChanged;
  final int maxTokens;
  final ValueChanged<int> onMaxTokensChanged;
  final String knowAboutYou;
  final ValueChanged<String> onKnowChanged;
  final String howToRespond;
  final ValueChanged<String> onRespondChanged;
  final bool streamResponses;
  final ValueChanged<bool> onStreamChanged;
  final bool enterToSend;
  final ValueChanged<bool> onEnterChanged;
  final bool autoChatTitle;
  final ValueChanged<bool> onAutoTitleChanged;
  final bool showTokenCount;
  final ValueChanged<bool> onShowTokensChanged;
  final bool hapticFeedback;
  final ValueChanged<bool> onHapticChanged;
  final bool saveHistory;
  final ValueChanged<bool> onSaveHistoryChanged;

  const NexoChatHome({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.textScale,
    required this.onTextScaleChanged,
    required this.temperature,
    required this.onTemperatureChanged,
    required this.maxTokens,
    required this.onMaxTokensChanged,
    required this.knowAboutYou,
    required this.onKnowChanged,
    required this.howToRespond,
    required this.onRespondChanged,
    required this.streamResponses,
    required this.onStreamChanged,
    required this.enterToSend,
    required this.onEnterChanged,
    required this.autoChatTitle,
    required this.onAutoTitleChanged,
    required this.showTokenCount,
    required this.onShowTokensChanged,
    required this.hapticFeedback,
    required this.onHapticChanged,
    required this.saveHistory,
    required this.onSaveHistoryChanged,
  });

  @override
  State<NexoChatHome> createState() => _NexoChatHomeState();
}

class _NexoChatHomeState extends State<NexoChatHome> {
  final List<EndpointConfig> _endpoints = [
    EndpointConfig(
      id: 'openrouter',
      name: 'OpenRouter',
      baseUrl: 'https://openrouter.ai/api/v1',
      apiKey: '',
      models: ['anthropic/claude-3.5-sonnet', 'deepseek/deepseek-r1'],
    ),
    EndpointConfig(
      id: 'ollama',
      name: 'Ollama (Local)',
      baseUrl: 'http://10.0.2.2:11434/v1',
      apiKey: '',
      models: ['llama3.3:latest', 'qwen2.5-coder:14b'],
    ),
  ];

  String _selectedModel = 'anthropic/claude-3.5-sonnet';
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  bool _isGenerating = false;
  String? _errorBanner;

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _endpoints.isEmpty) return;

    _inputController.clear();
    setState(() {
      _errorBanner = null;
      _messages.add(ChatMessage(role: 'user', content: text));
      _messages.add(ChatMessage(role: 'assistant', content: ''));
      _isGenerating = true;
    });

    final ep = _endpoints.first;
    try {
      final uri = Uri.parse('${ep.baseUrl}/chat/completions');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (ep.apiKey.isNotEmpty) 'Authorization': 'Bearer ${ep.apiKey}',
        },
        body: jsonEncode({
          'model': _selectedModel,
          'temperature': widget.temperature,
          'messages': _messages
              .where((m) => m.content.isNotEmpty)
              .map((m) => {'role': m.role, 'content': m.content})
              .toList(),
        }),
      );

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final data = jsonDecode(res.body);
      final reply = data['choices']?[0]?['message']?['content'] ?? '';
      setState(() {
        _messages.last.content = reply;
        _messages.last.tokens = (reply.length / 4).round();
      });
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _errorBanner = e.toString();
      });
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: cs.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _endpoints.isEmpty ? cs.onSurfaceVariant : cs.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _endpoints.isEmpty ? 'No endpoint' : _selectedModel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() => _messages.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SparkRingLogo(size: 44, color: cs.primary),
                        const SizedBox(height: 16),
                        const Text(
                          'How can I help?',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final isUser = m.role == 'user';
                      if (isUser) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(6),
                              ),
                              border: Border.all(color: cs.outline),
                            ),
                            child: Text(m.content),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SparkRingLogo(size: 20, color: cs.primary),
                            const SizedBox(width: 10),
                            Expanded(child: Text(m.content)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (_errorBanner != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.error),
              ),
              child: Text(_errorBanner!, style: TextStyle(color: cs.error, fontSize: 12)),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Message Nexo...',
                        filled: true,
                        fillColor: cs.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: cs.outline),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isGenerating ? null : _sendMessage,
                    icon: Icon(_isGenerating ? Icons.stop : Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
