import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import 'dart:io';
import '../../shared/widgets/app_button.dart';
import '../../data/models/product.dart';
import '../../data/services/storage_service.dart';
import '../../providers/product_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/currency_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../core/constants/app_constants.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final Product product;
  const EditProductScreen({super.key, required this.product});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _lowStockLimitController;
  late final TextEditingController _barcodeController;
  final _formKey = GlobalKey<FormState>();
  final _storageService = StorageService();

  late String _selectedUnit;
  String? _imageUrl;
  bool _isLoading = false;
  bool _isScanning = false;

  final List<String> _commonCategories = [
    'Mobile Phones',
    'Accessories',
    'Groceries',
    'Electronics',
    'Clothing',
    'Pharmacy',
    'Stationery',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p.name);
    _categoryController = TextEditingController(text: p.category);
    _purchasePriceController =
        TextEditingController(text: p.purchasePrice.toStringAsFixed(2));
    _sellingPriceController =
        TextEditingController(text: p.sellingPrice.toStringAsFixed(2));
    _quantityController =
        TextEditingController(text: p.quantity.toString());
    _lowStockLimitController =
        TextEditingController(text: p.lowStockLimit.toString());
    _barcodeController = TextEditingController(text: p.barcode ?? '');
    _selectedUnit = kProductUnits.contains(p.unit) ? p.unit! : 'Piece';
    _imageUrl = p.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _lowStockLimitController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _scanBarcode() {
    setState(() => _isScanning = true);
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
    if (path.startsWith('/') || path.startsWith('file:')) {
      return Image.file(File(path), fit: BoxFit.cover, width: 120, height: 120);
    }
    return Image.network(path, fit: BoxFit.cover, width: 120, height: 120);
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
      final updated = widget.product.copyWith(
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        purchasePrice:
            double.parse(_purchasePriceController.text.trim()),
        sellingPrice:
            double.parse(_sellingPriceController.text.trim()),
        quantity: int.parse(_quantityController.text.trim()),
        unit: _selectedUnit,
        lowStockLimit:
            int.tryParse(_lowStockLimitController.text.trim()) ?? 5,
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        imageUrl: _imageUrl,
        updatedAt: DateTime.now(),
      );
      await ref.read(productListNotifierProvider.notifier).updateProduct(updated);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isScanning) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(l10n.barcode),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isScanning = false),
            ),
          ],
        ),
        body: MobileScanner(
          onDetect: (capture) {
            final barcode = capture.barcodes.first.rawValue;
            if (barcode != null) {
              _barcodeController.text = barcode;
              setState(() => _isScanning = false);
            }
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Edit Product')),
      body: SingleChildScrollView(
        padding: AppDimensions.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Product Image ──
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
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
                              const Icon(Icons.camera_alt, size: 32, color: AppColors.textSecondary),
                              const SizedBox(height: 4),
                              Text(l10n.addPhoto, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.lg),

              // ── Product Name ──
              Text(l10n.productName, style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              TextFormField(
                controller: _nameController,
                decoration:
                    const InputDecoration(hintText: 'Enter product name'),
                validator: (v) =>
                    v == null || v.isEmpty ? l10n.required_ : null,
              ),
              const SizedBox(height: AppDimensions.md),

              // ── Category ──
              Text(l10n.category, style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                    hintText: 'Select or enter category'),
                validator: (v) =>
                    v == null || v.isEmpty ? l10n.required_ : null,
              ),
              const SizedBox(height: AppDimensions.sm),
              Wrap(
                spacing: AppDimensions.sm,
                runSpacing: AppDimensions.xs,
                children: _commonCategories.map((cat) {
                  final selected = _categoryController.text == cat;
                  return ActionChip(
                    label: Text(cat,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                        )),
                    backgroundColor:
                        selected ? AppColors.primary : null,
                    onPressed: () => setState(
                        () => _categoryController.text = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.md),

              // ── Prices ──
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.purchasePrice,
                            style: AppTextStyles.labelLarge),
                        const SizedBox(height: AppDimensions.sm),
                        TextFormField(
                          controller: _purchasePriceController,
                          decoration: InputDecoration(
                              hintText: '0.00', prefixText: '${currencySymbol(ref.watch(businessProvider).valueOrNull?.currency ?? 'PKR')} '),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? l10n.required_ : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.sellingPrice,
                            style: AppTextStyles.labelLarge),
                        const SizedBox(height: AppDimensions.sm),
                        TextFormField(
                          controller: _sellingPriceController,
                          decoration: InputDecoration(
                              hintText: '0.00', prefixText: '${currencySymbol(ref.watch(businessProvider).valueOrNull?.currency ?? 'PKR')} '),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? l10n.required_ : null,
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
                        Text(l10n.quantity,
                            style: AppTextStyles.labelLarge),
                        const SizedBox(height: AppDimensions.sm),
                        TextFormField(
                          controller: _quantityController,
                          decoration:
                              const InputDecoration(hintText: '0'),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? l10n.required_ : null,
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
                          initialValue: _selectedUnit,
                          isExpanded: true,
                          items: kProductUnits
                              .map((u) => DropdownMenuItem(
                                  value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedUnit = v);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),

              // ── Low Stock Limit ──
              Text('Low Stock Alert Threshold',
                  style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              TextFormField(
                controller: _lowStockLimitController,
                decoration:
                    const InputDecoration(hintText: '5'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppDimensions.md),

              // ── Barcode ──
              Text(l10n.barcode, style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  hintText: 'Scan or enter barcode (optional)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanBarcode,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.xl),

              // ── Save Button ──
              AppButton(
                label: 'Update Product',
                isLoading: _isLoading,
                onPressed: _save,
              ),
              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        ),
      ),
    );
  }
}
