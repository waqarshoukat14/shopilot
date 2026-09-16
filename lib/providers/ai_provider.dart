import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/ai_service.dart';

final apiKeyProvider = Provider<String>((_) => const String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''));

final aiServiceProvider = Provider<AiService>((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  print('[AI] API key loaded: ${apiKey.isEmpty ? 'EMPTY' : '${apiKey.substring(0, apiKey.length > 6 ? 6 : apiKey.length)}...'}');
  return AiService(apiKey: apiKey);
});
