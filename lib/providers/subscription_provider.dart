import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SubscriptionTier { free, pro, enterprise }

class SubscriptionState {
  final SubscriptionTier tier;
  final bool isActive;
  final DateTime? expiresAt;

  SubscriptionState({
    this.tier = SubscriptionTier.free,
    this.isActive = true,
    this.expiresAt,
  });

  bool get canUseAi => tier != SubscriptionTier.free;
  bool get canUseVoice => tier != SubscriptionTier.free;
  bool get canExportPdf => tier != SubscriptionTier.free;
  int get maxProducts => tier == SubscriptionTier.free ? 50 : 999999;
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(SubscriptionState());

  void upgradeToPro() => state = SubscriptionState(tier: SubscriptionTier.pro);
  void upgradeToEnterprise() => state = SubscriptionState(tier: SubscriptionTier.enterprise);
  void downgradeToFree() => state = SubscriptionState();
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((_) {
  return SubscriptionNotifier();
});
