import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/constants/app_constants.dart';

class AiService {
  final GenerativeModel? _model;
  final bool _enabled;
  final String _apiKey;

  AiService({required String apiKey})
      : _enabled = apiKey.isNotEmpty,
        _apiKey = apiKey,
        _model = apiKey.isNotEmpty
            ? GenerativeModel(
                model: 'gemini-2.0-flash',
                apiKey: apiKey,
                generationConfig: GenerationConfig(
                  responseMimeType: 'application/json',
                ),
              )
            : null;

  Future<String> processVoiceCommand(String transcript) async {
    if (!_enabled || _model == null) {
      return '{"action": "general", "message": "AI service is not configured. Please add a GEMINI_API_KEY."}';
    }
    final prompt = '''
You are a Shopilot AI assistant for a small business management app.
The user said: "$transcript"

Interpret the command and return a JSON response in one of these formats:

1. For adding products:
{"action": "add_product", "name": "...", "quantity": number, "category": "..."}

2. For creating invoice:
{"action": "create_invoice", "customer": "...", "items": [{"name": "...", "quantity": number}]}

3. For showing sales:
{"action": "show_sales", "period": "daily|weekly|monthly"}

4. For general queries:
{"action": "general", "message": "..."}

Return ONLY valid JSON, no other text.
''';
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? '{"action": "general", "message": "I didn\'t understand that."}';
    } on GenerativeAIException {
      // If JSON mode fails, retry without it
      final fallbackModel = GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);
      final response = await fallbackModel.generateContent([Content.text(prompt)]);
      return response.text ?? '{"action": "general", "message": "I didn\'t understand that."}';
    }
  }

  /// Extracts add-product form fields from a spoken transcript. The user
  /// may speak in Urdu (script or Roman/Urdish) or English — Gemini
  /// understands both natively, so no language needs to be picked upfront.
  /// Returns strict JSON; fields the speaker didn't mention come back null
  /// so the UI can leave them for the user to fill in manually.
  Future<String> extractProductFromVoice(String transcript) async {
    if (!_enabled || _model == null) {
      return '{"understood": false, "reason": "AI service is not configured. Please add a GEMINI_API_KEY."}';
    }
    final prompt = '''
You are a Shopilot AI assistant for a small shop's inventory app. A shopkeeper
spoke the following to describe a product they want to add. They may speak in
English, Urdu (Urdu script), or Roman Urdu (Urdu words spelled in English
letters) — sometimes mixing languages in one sentence. Understand it regardless
of language or script.

Transcript: "$transcript"

Extract these product fields and return ONLY this JSON shape, no other text:
{
  "understood": true|false,
  "name": "..."|null,
  "category": "..."|null,
  "purchasePrice": number|null,
  "sellingPrice": number|null,
  "quantity": number|null,
  "unit": "..."|null,
  "barcode": "..."|null,
  "lowStockLimit": number|null
}

Rules:
- Be generous, not strict. This transcript came from on-device speech recognition, so it will often have misheard words, missing spaces, or odd phonetic spellings (especially for Roman Urdu) — work around that noise rather than rejecting it. If you can identify even just a plausible product name, treat it as understood and fill in whatever other fields you can; leave the rest null for the user to complete themselves.
- Set "understood" to false ONLY when the transcript is empty, pure noise/gibberish, or clearly about something other than describing a product (e.g. "what are today's sales"). When in doubt, prefer true.
- purchasePrice is the cost/buying price (Urdu: "khareed price", "cost"); sellingPrice is the sale price (Urdu: "bechne ka price", "sale price"). If the speaker only gives one price with no buy/sell distinction, put it in sellingPrice and leave purchasePrice null.
- quantity is how many units are in stock right now.
- unit must be one of exactly: ${kProductUnits.join(', ')} — pick the closest match (e.g. "dabba"/"box" → Box, "kilo"/"kg" → Kg, "dozen"/"darjan" → Dozen). Default to "Piece" only if quantity is given but no unit is implied.
- category: a short shop category like Electronics, Groceries, Mobile Phones, Clothing, Pharmacy, Stationery — infer a reasonable one from the product if the speaker doesn't state it explicitly, or null if you truly can't guess.
- Translate any extracted text values (name, category) to a clear English/Roman form suitable for display in a UI — do not return Urdu script.
- Only leave a numeric field (price/quantity/lowStockLimit) null if no number for it was stated or clearly implied — never invent one, but don't let uncertainty about one field stop you from returning the others.
''';
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? '{"understood": false, "reason": "I didn\'t understand that."}';
    } on GenerativeAIException {
      final fallbackModel = GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);
      final response = await fallbackModel.generateContent([Content.text(prompt)]);
      return response.text ?? '{"understood": false, "reason": "I didn\'t understand that."}';
    }
  }

  Future<String> getBusinessInsight(String salesData) async {
    if (!_enabled || _model == null) return 'AI service is not configured. Please add a GEMINI_API_KEY.';
    final prompt = '''
You are a Shopilot AI analytics assistant. Here is the business data:
$salesData

Provide 3 short, actionable insights in bullet points. Keep it simple and in plain English.
Focus on: sales trends, low stock alerts, top products, and payment collections.
''';
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? 'No insights available yet.';
  }

  Future<String> generateInvoiceSummary(String invoiceData) async {
    if (!_enabled || _model == null) return '';
    final prompt = '''
Summarize this invoice in simple English:
$invoiceData

Include: customer name, total items, total amount, and payment status.
''';
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? '';
  }
}
