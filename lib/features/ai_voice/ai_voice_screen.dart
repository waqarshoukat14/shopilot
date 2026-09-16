import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/app_card.dart';
import '../../providers/ai_provider.dart';
import '../../l10n/app_localizations.dart';

class AiVoiceScreen extends ConsumerStatefulWidget {
  const AiVoiceScreen({super.key});

  @override
  ConsumerState<AiVoiceScreen> createState() => _AiVoiceScreenState();
}

class _AiVoiceScreenState extends ConsumerState<AiVoiceScreen>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isProcessing = false;
  bool _disposed = false;
  String _recognizedText = '';
  String _responseText = '';
  double _level = 0;
  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  final List<_VoiceCommand> _exampleCommands = [
    _VoiceCommand('"Ali ko do chargers bech do"', 'Create invoice for Ali with 2 chargers'),
    _VoiceCommand('"20 Samsung chargers add kar do"', 'Add 20 Samsung chargers to inventory'),
    _VoiceCommand('"Show today sales"', 'View today\'s sales report'),
    _VoiceCommand('"Kitne customers hain"', 'Check total customers'),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _initSpeech();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) {
      setState(fn);
    }
  }

  void _initSpeech() async {
    try {
      await _speech.initialize(
        onError: (e) => _safeSetState(() => _responseText = 'Error: ${e.errorMsg}'),
      );
    } catch (e) {
      _safeSetState(() => _responseText = 'Speech recognition not available');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _speech.stop();
    _animController.dispose();
    super.dispose();
  }

  void _startListening() async {
    try {
      if (!_speech.isAvailable) {
        final available = await _speech.initialize(
          onError: (e) => _safeSetState(() => _responseText = 'Error: ${e.errorMsg}'),
        );
        if (!available || _disposed) {
          _safeSetState(() => _responseText = 'Speech recognition not available');
          return;
        }
      }
      if (_disposed) return;
      _safeSetState(() {
        _isListening = true;
        _recognizedText = '';
        _responseText = '';
      });
      _speech.listen(
        onResult: (result) {
          _safeSetState(() {
            _recognizedText = result.recognizedWords;
            _level = result.confidence;
          });
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
          localeId: 'en_US',
        ),
      );
    } catch (e) {
      _safeSetState(() => _responseText = 'Could not start listening. Please try again.');
    }
  }

  void _stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    if (_disposed) return;
    _safeSetState(() => _isListening = false);
    if (_recognizedText.isNotEmpty) {
      _processCommand(_recognizedText);
    }
  }

  Future<void> _processCommand(String text) async {
    _safeSetState(() => _isProcessing = true);
    try {
      final aiService = ref.read(aiServiceProvider);
      var jsonStr = await aiService.processVoiceCommand(text);

      // Strip markdown code fences if present
      jsonStr = jsonStr.trim();
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.replaceAll(RegExp(r'^```(?:json)?\s*'), '');
        jsonStr = jsonStr.replaceAll(RegExp(r'\s*```$'), '');
      }

      // Extract JSON object even if extra text is present
      final jsonMatch = RegExp(r'\{[^{}]*\}').firstMatch(jsonStr);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(0)!;
      }

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final action = decoded['action'] as String?;

      String message;
      switch (action) {
        case 'show_sales':
          message = 'Opening sales report...';
          if (mounted) context.push('/reports');
        case 'add_product':
          message = 'Opening add product screen...';
          if (mounted) context.push('/products/add');
        case 'create_invoice':
          message = 'Opening invoice creation...';
          if (mounted) context.push('/invoices/create');
        default:
          message = decoded['message'] as String? ?? 'Command received: $text';
      }

      _safeSetState(() => _responseText = message);
    } catch (e) {
      _safeSetState(() => _responseText = 'I understood: "$text"\nBut couldn\'t process it. Please try again.');
    } finally {
      _safeSetState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.aiVoice),
        actions: [
          if (_recognizedText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {
                _recognizedText = '';
                _responseText = '';
              }),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            _buildMicSection(),
            const Spacer(flex: 1),
            _buildStatusText(l10n),
            const Spacer(flex: 1),
            if (_responseText.isNotEmpty) _buildResponseCard(),
            if (_recognizedText.isEmpty && _responseText.isEmpty) _buildExamples(),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildMicSection() {
    return GestureDetector(
      onTapDown: (_) => _startListening(),
      onTapUp: (_) => _stopListening(),
      onTapCancel: _stopListening,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Transform.scale(
          scale: _isListening ? _pulseAnim.value : 1.0,
          child: child,
        ),
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _isListening ? AppColors.primaryGradient : null,
            color: _isListening ? null : AppColors.primarySoft,
            boxShadow: _isListening
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            size: 56,
            color: _isListening ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText(AppLocalizations l10n) {
    if (_isProcessing) {
      return Column(
        children: [
          const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(height: AppDimensions.md),
          Text(l10n.processing, style: AppTextStyles.bodyLarge),
        ],
      );
    }
    if (_isListening) {
      return Column(
        children: [
          Text(l10n.listening, style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppDimensions.sm),
          Text(_recognizedText.isNotEmpty ? _recognizedText : l10n.speakNow, style: AppTextStyles.bodyLarge),
          const SizedBox(height: AppDimensions.sm),
          SizedBox(
            width: 200, height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _level,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
        ],
      );
    }
    return Text(l10n.tapAndHoldToSpeak, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary));
  }

  Widget _buildResponseCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
      child: AppCard(
        color: AppColors.primarySoft,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(child: Text(_responseText, style: AppTextStyles.bodyLarge)),
          ],
        ),
      ),
    );
  }

  Widget _buildExamples() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: AppDimensions.screenPadding,
      child: Column(
        children: [
          Text(l10n.trySaying, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppDimensions.sm),
          ..._exampleCommands.map((cmd) => GestureDetector(
            onTap: () {
              setState(() => _recognizedText = cmd.transcript);
              _processCommand(cmd.transcript);
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppDimensions.sm),
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(cmd.display, style: AppTextStyles.bodyMedium)),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _VoiceCommand {
  final String display;
  final String transcript;
  _VoiceCommand(this.display, this.transcript);
}
