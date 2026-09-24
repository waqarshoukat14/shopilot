import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../data/models/product.dart';
import '../../data/services/storage_service.dart';
import '../../providers/product_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ai_provider.dart';
import '../../core/utils/currency_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _lowStockLimitController = TextEditingController(text: '5');
  final _storageService = StorageService();
  String? _imageUrl;
  bool _isLoading = false;
  String _selectedUnit = 'Piece';

  double get _totalPrice {
    final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    return sellingPrice * quantity;
  }

  final List<String> _commonCategories = [
    'Mobile Phones', 'Accessories', 'Groceries', 'Electronics',
    'Clothing', 'Pharmacy', 'Stationery', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _sellingPriceController.addListener(_onPriceOrQuantityChanged);
    _quantityController.addListener(_onPriceOrQuantityChanged);
  }

  void _onPriceOrQuantityChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _sellingPriceController.removeListener(_onPriceOrQuantityChanged);
    _quantityController.removeListener(_onPriceOrQuantityChanged);
    _nameController.dispose();
    _categoryController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _lowStockLimitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final url = await _storageService.pickAndUploadImage(
      'products',
      token: ref.read(apiTokenProvider),
    );
    if (url != null) {
      setState(() => _imageUrl = url);
    }
  }

  Widget _buildImage(String path) {
    // If it's a local file path
    if (path.startsWith('/') || path.startsWith('file:')) {
      return Image.file(File(path), fit: BoxFit.cover, width: 120, height: 120);
    }
    // Otherwise treat as network URL
    return Image.network(path, fit: BoxFit.cover, width: 120, height: 120);
  }

  Future<void> _openVoiceInput() async {
    final data = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _VoiceInputSheet(),
    );
    if (data == null || !mounted) return;
    _applyVoiceData(data);
  }

  void _applyVoiceData(Map<String, dynamic> data) {
    setState(() {
      final name = data['name'] as String?;
      if (name != null && name.trim().isNotEmpty) _nameController.text = name.trim();

      final category = data['category'] as String?;
      if (category != null && category.trim().isNotEmpty) _categoryController.text = category.trim();

      final purchasePrice = data['purchasePrice'];
      if (purchasePrice is num) _purchasePriceController.text = purchasePrice.toString();

      final sellingPrice = data['sellingPrice'];
      if (sellingPrice is num) _sellingPriceController.text = sellingPrice.toString();

      final quantity = data['quantity'];
      if (quantity is num) _quantityController.text = quantity.round().toString();

      final unit = data['unit'] as String?;
      if (unit != null && kProductUnits.contains(unit)) _selectedUnit = unit;

      final lowStockLimit = data['lowStockLimit'];
      if (lowStockLimit is num) _lowStockLimitController.text = lowStockLimit.round().toString();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filled from voice — please review before saving.')),
    );
  }

  Future<void> _showMissingFieldsAlert(String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Missing Information'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final formValid = _formKey.currentState!.validate();
    if (!formValid) {
      await _showMissingFieldsAlert('Please fill in all required fields before saving the product.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final product = Product(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        purchasePrice: double.parse(_purchasePriceController.text.trim()),
        sellingPrice: double.parse(_sellingPriceController.text.trim()),
        quantity: int.parse(_quantityController.text.trim()),
        unit: _selectedUnit,
        lowStockLimit: int.tryParse(_lowStockLimitController.text.trim()) ?? 5,
        imageUrl: _imageUrl,
      );
      await ref.read(productListNotifierProvider.notifier).addProduct(product);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.newProduct)),
      body: SingleChildScrollView(
        padding: AppDimensions.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imageUrl != null
                        ? _buildImage(_imageUrl!)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 32, color: AppColors.textSecondary),
                              const SizedBox(height: 4),
                              Text(l10n.addPhoto, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.lg),
              Text(l10n.productName, style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Enter product name'),
                validator: (v) => v == null || v.isEmpty ? l10n.required_ : null,
              ),
              const SizedBox(height: AppDimensions.md),
              Text(l10n.category, style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(hintText: 'Select or enter category'),
                validator: (v) => v == null || v.isEmpty ? l10n.required_ : null,
              ),
              const SizedBox(height: AppDimensions.sm),
              Wrap(
                spacing: AppDimensions.sm,
                runSpacing: AppDimensions.xs,
                children: _commonCategories.map((cat) {
                  final selected = _categoryController.text == cat;
                  return ActionChip(
                    label: Text(cat, style: AppTextStyles.labelSmall.copyWith(
                      color: selected ? Colors.white : AppColors.textPrimary,
                    )),
                    backgroundColor: selected ? AppColors.primary : null,
                    onPressed: () => setState(() => _categoryController.text = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.purchasePrice, style: AppTextStyles.labelLarge),
                        const SizedBox(height: AppDimensions.sm),
                        TextFormField(
                          controller: _purchasePriceController,
                          decoration: InputDecoration(hintText: '0.00', prefixText: '${currencySymbol(ref.watch(businessProvider).valueOrNull?.currency ?? 'PKR')} '),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? l10n.required_ : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.sellingPrice, style: AppTextStyles.labelLarge),
                        const SizedBox(height: AppDimensions.sm),
                        TextFormField(
                          controller: _sellingPriceController,
                          decoration: InputDecoration(hintText: '0.00', prefixText: '${currencySymbol(ref.watch(businessProvider).valueOrNull?.currency ?? 'PKR')} '),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? l10n.required_ : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              // ── Quantity & Unit ──
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.quantity, style: AppTextStyles.labelLarge),
                        const SizedBox(height: AppDimensions.sm),
                        TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(hintText: '0'),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? l10n.required_ : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Unit', style: AppTextStyles.labelLarge),
                        const SizedBox(height: AppDimensions.sm),
                        DropdownButtonFormField<String>(
                          key: ValueKey('unit_$_selectedUnit'),
                          initialValue: _selectedUnit,
                          isExpanded: true,
                          items: kProductUnits
                              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedUnit = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              // ── Total Price ──
              if (_totalPrice > 0)
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calculate, color: AppColors.success, size: 20),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Value', style: AppTextStyles.labelMedium),
                            const SizedBox(height: 2),
                            Text(
                              formatPrice(_totalPrice, ref.watch(businessProvider).valueOrNull?.currency ?? 'PKR'),
                              style: AppTextStyles.titleLarge.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppDimensions.md),
              // ── Low Stock Limit ──
              Text('Low Stock Alert Threshold', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              TextFormField(
                controller: _lowStockLimitController,
                decoration: const InputDecoration(hintText: '5'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppDimensions.xl),
              AppButton(
                label: l10n.saveProduct,
                isLoading: _isLoading,
                onPressed: _save,
              ),
              const SizedBox(height: AppDimensions.md),
              AppButton(
                label: l10n.useVoiceInput,
                isOutlined: true,
                icon: Icons.mic,
                onPressed: _openVoiceInput,
              ),
              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet: tap-and-hold the mic, speak the product details in Urdu or
/// English. After releasing, the transcript is shown in an editable field —
/// speech recognition is never perfect, so the user gets a chance to fix
/// any misheard words before Gemini extracts the add-product form fields.
/// Pops with the extracted data (or null if cancelled) for the caller to
/// apply to its own controllers — the sheet never touches the form directly.
class _VoiceInputSheet extends ConsumerStatefulWidget {
  const _VoiceInputSheet();

  @override
  ConsumerState<_VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends ConsumerState<_VoiceInputSheet> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final _transcriptController = TextEditingController();
  bool _speechReady = false;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _disposed = false;
  // Once the user has recorded (and can review/edit) at least once.
  bool _hasRecorded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _disposed = true;
    _speech.stop();
    _transcriptController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) setState(fn);
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onError: (e) => _safeSetState(() => _error = e.errorMsg),
      );
      _safeSetState(() => _speechReady = available);
    } catch (_) {
      _safeSetState(() {
        _speechReady = false;
        _error = 'Speech recognition not available on this device.';
      });
    }
  }

  /// Uses the device's own configured recognition language (Urdu or
  /// English) rather than a hardcoded locale, so no manual language picker
  /// is needed — on-device speech recognition can't auto-detect the spoken
  /// language mid-utterance, but it can use whichever of the two the
  /// device/user already has set as their system input language.
  Future<String> _resolveLocale() async {
    try {
      final system = await _speech.systemLocale();
      final id = system?.localeId;
      if (id != null && (id.toLowerCase().startsWith('ur') || id.toLowerCase().startsWith('en'))) {
        return id;
      }
    } catch (_) {}
    return 'en_US';
  }

  Future<void> _startListening() async {
    if (!_speechReady) return;
    _safeSetState(() {
      _isListening = true;
      _transcriptController.clear();
      _error = null;
    });
    final localeId = await _resolveLocale();
    if (_disposed) return;
    try {
      await _speech.listen(
        onResult: (result) => _safeSetState(() => _transcriptController.text = result.recognizedWords),
        listenOptions: stt.SpeechListenOptions(
          // Generous timings — describing name/price/quantity/unit takes
          // longer than a short command, and natural pauses mid-sentence
          // shouldn't cut the recording off early.
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          localeId: localeId,
        ),
      );
    } catch (e) {
      _safeSetState(() {
        _isListening = false;
        _error = 'Could not start listening. Please try again.';
      });
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    if (_disposed) return;
    _safeSetState(() {
      _isListening = false;
      _hasRecorded = true;
    });
  }

  Future<void> _confirmTranscript() async {
    final transcript = _transcriptController.text.trim();
    if (transcript.isEmpty) return;
    _safeSetState(() {
      _isProcessing = true;
      _error = null;
    });
    try {
      final aiService = ref.read(aiServiceProvider);
      var jsonStr = await aiService.extractProductFromVoice(transcript);

      jsonStr = jsonStr.trim();
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.replaceAll(RegExp(r'^```(?:json)?\s*'), '');
        jsonStr = jsonStr.replaceAll(RegExp(r'\s*```$'), '');
      }
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(jsonStr);
      if (jsonMatch != null) jsonStr = jsonMatch.group(0)!;

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (decoded['understood'] != true) {
        final reason = decoded['reason'] as String?;
        _safeSetState(() {
          _isProcessing = false;
          _error = reason != null && reason.isNotEmpty
              ? reason
              : 'Couldn\'t pick out product details from that — edit the text above or try recording again.';
        });
        return;
      }
      if (mounted) Navigator.of(context).pop(decoded);
    } catch (e) {
      debugPrint('_VoiceInputSheet._confirmTranscript: $e');
      _safeSetState(() {
        _isProcessing = false;
        _error = 'Could not process that: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.lg, AppDimensions.md, AppDimensions.lg,
        MediaQuery.of(context).viewInsets.bottom + AppDimensions.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          Text('Speak Product Details', style: AppTextStyles.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Speak in Urdu or English — name, price, quantity. You can edit the text before we fill the form.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.xl),
          Center(
            child: GestureDetector(
              onTapDown: (_) => _startListening(),
              onTapUp: (_) => _stopListening(),
              onTapCancel: _stopListening,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isListening ? AppColors.primaryGradient : null,
                  color: _isListening ? null : AppColors.primarySoft,
                  boxShadow: _isListening
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 24, spreadRadius: 4)]
                      : null,
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 44,
                  color: _isListening ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          Center(
            child: _isListening
                ? Text('Listening… release to finish', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary))
                : !_speechReady
                    ? Text('Preparing microphone…', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary))
                    : Text(
                        _hasRecorded ? 'Tap and hold to re-record' : 'Tap and hold to speak',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
          ),
          if (_hasRecorded && !_isListening) ...[
            const SizedBox(height: AppDimensions.lg),
            Text('What we heard — edit if anything\'s wrong:', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppDimensions.sm),
            TextField(
              controller: _transcriptController,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(hintText: 'Product details...'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppDimensions.sm),
              Text(_error!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: AppDimensions.md),
            AppButton(
              label: 'Fill Form',
              isLoading: _isProcessing,
              onPressed: _confirmTranscript,
            ),
          ],
          const SizedBox(height: AppDimensions.lg),
        ],
      ),
    );
  }
}
