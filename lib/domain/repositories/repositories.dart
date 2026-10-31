import '../entities/entities.dart';

abstract class AccountRepository {
  Future<DemoSnapshot> updateProfile(UserProfile user);
  Future<DemoSnapshot> updatePassword(String password);
  Future<DemoSnapshot> updatePrefs(NotificationPrefs prefs);
  Future<DemoSnapshot> selectContract(String contractId);
  Future<DemoSnapshot> updateContractAddress({
    required String contractId,
    required String address,
    required String sector,
  });
}

abstract class BillingRepository {
  Future<PaymentReceipt> registerPayment({
    required String invoiceId,
    required PaymentMethod method,
    String? cardLast4,
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
  Future<DemoSnapshot> restoreInitial();
}
