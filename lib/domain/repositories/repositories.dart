import '../entities/entities.dart';

abstract class AccountRepository {
  Future<DemoSnapshot> updateProfile(UserProfile user);
  Future<DemoSnapshot> updatePassword(String password);
  Future<DemoSnapshot> updatePrefs(NotificationPrefs prefs);
  Future<DemoSnapshot> selectContract(String contractId);
  Future<DemoSnapshot> updateAlias({required String contractId, required String alias});
  Future<DemoSnapshot> linkContract({
    required ContractAccount contract,
    required List<Invoice> invoices,
    required List<ConsumptionMonth> months,
    required String alias,
  });
  Future<DemoSnapshot> unlinkContract(String contractId);
  Future<DemoSnapshot> addCard(SavedCard card);
  Future<DemoSnapshot> removeCard({required String cardId, String? replacementDefaultId});
  Future<DemoSnapshot> setDefaultCard(String cardId);
}

abstract class BillingRepository {
  Future<PaymentTransaction> settle({
    required List<String> invoiceIds,
    required PaymentMethod method,
    required PaymentStatus status,
    CardBrand? cardBrand,
    String? cardLast4,
    String? cardHolder,
    CardFunding? cardFunding,
    String? message,
  });
}

abstract class OutageRepository {
  Future<OutageReport> create(OutageReport report);
  Future<OutageReport> advance(String id);
}

abstract class RequestRepository {
  Future<ServiceRequest> create(ServiceRequest request);
  Future<ServiceRequest> advance(String id);
}

abstract class NotificationRepository {
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

abstract class AssistantRepository {
  Future<List<ChatMessage>> send(String text);
}

abstract class DemoControlsRepository {
  Future<DemoSnapshot> applyScenario(DemoScenario scenario, {required bool keepAccount});
  Future<DemoSnapshot> applyPortfolio(PortfolioPreset portfolio);
  Future<DemoSnapshot> restoreInitial();
}
