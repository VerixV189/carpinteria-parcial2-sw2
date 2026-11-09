import 'dart:typed_data';
import 'package:carpinteria_movil_sw2/domain/entities/entity.dart';

abstract class CarpentryRepository {
  bool get isUsingMock;

  // Auth
  Future<UserEntity> login({
    required String email,
    required String password,
  });

  Future<UserEntity> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  });

  Future<void> logout();

  Future<UserEntity?> getSavedSession();

  // Catálogo e Inventario
  Future<List<ProductEntity>> getProducts();
  Future<List<WoodMaterialEntity>> getMaterials();

  // Marketplace (CRUD Admin/Carpintero + compra directa del cliente)
  Future<ProductEntity> saveMarketplaceProduct(
    Map<String, dynamic> payload, {
    String? id,
  });
  Future<bool> deleteMarketplaceProduct(String id);
  Future<Map<String, dynamic>> checkoutMarketplace(Map<String, dynamic> payload);
  Future<String> uploadImageToS3(String base64, {String fileName = 'mueble.jpg'});

  // Clientes y Segmentación
  Future<List<ClientProfileEntity>> getClients({String? search});
  Future<ClientProfileEntity> createClient({
    required String name,
    required String email,
    String? phone,
    String? address,
    String segment = 'REGULAR',
  });
  Future<ClientProfileEntity> updateClient({
    required String id,
    required String name,
    required String email,
    String? phone,
    String? address,
    String segment = 'REGULAR',
  });
  Future<bool> deleteClient(String id);
  Future<List<ClientClusterEntity>> clusterClients();

  // Carpinteros y Taller
  Future<List<CarpenterEntity>> getCarpenters({bool activeOnly = false});
  Future<CarpenterEntity> createCarpenter({
    required String name,
    required String email,
    String? phone,
    required String specialty,
    int yearsExperience = 3,
    double hourlyRate = 45.0,
    bool active = true,
  });
  Future<CarpenterEntity> updateCarpenter({
    required String id,
    required String name,
    required String email,
    String? phone,
    required String specialty,
    int yearsExperience = 3,
    double hourlyRate = 45.0,
    bool active = true,
  });
  Future<bool> deleteCarpenter(String id);
  Future<List<OrderEntity>> getCarpenterWorkload(String carpenterId);

  // Cotizaciones y Negociación
  Future<AiEstimateEntity> estimateFurniture({
    required String description,
    required String woodType,
    String? imageBase64,
  });
  Future<List<QuotationEntity>> getQuotations({String? status});
  Future<QuotationEntity> createQuotation({
    required String clientId,
    required String description,
    required String woodType,
    required double estimatedPrice,
    int quantity = 1,
    String? photoUrl,
    AiEstimateEntity? aiEstimate,
    String deliveryType = 'DELIVERY',
    String? deliveryAddress,
    double? latitude,
    double? longitude,
  });
  Future<QuotationEntity> respondQuotation({
    required String id,
    required String action, // 'accept' | 'reject' | 'counter'
    double? counterAmount,
    String? message,
  });
  Future<QuotationEntity> sendQuotationFormalPrice({
    required String id,
    required double finalAmount,
    String? notes,
  });
  Future<QuotationEntity> approveQuotation({
    required String id,
    double? finalAmount,
    String? notes,
  });
  Future<QuotationEntity> rejectQuotation({
    required String id,
    String? reason,
  });

  // Pedidos, Pasos de Producción y Entregas
  Future<List<OrderEntity>> getOrders();
  Future<OrderEntity> createOrder({
    required String clientName,
    required String productName,
    required String woodType,
    required String specifications,
    required double totalAmount,
    required double advancePayment,
    required String deliveryDate,
    String? clientId,
    String deliveryType = 'DELIVERY',
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
  });
  Future<OrderEntity> updateOrderStatus(String orderId, String newStatus);
  Future<OrderEntity> assignCarpenter(String orderId, String carpenterId);
  Future<ProductionStepEntity> updateStepStatus(String stepId, String status);
  Future<OrderEntity> linkQuotation(String orderId, String quotationId);

  Future<List<DeliveryEntity>> getDeliveries({String? status});
  Future<DeliveryCapacityEntity> getDeliveryCapacity(String date);
  Future<DeliveryEntity> scheduleDelivery({
    required String orderId,
    required String scheduledDate,
    required String timeSlot,
    required String address,
    String? notes,
    String deliveryType = 'DELIVERY',
    double? latitude,
    double? longitude,
  });
  Future<DeliveryEntity> updateDeliveryStatus(String id, String status);
  Future<DeliveryEntity> rescheduleDelivery({
    required String id,
    required String newDate,
    String? timeSlot,
  });

  // Facturas y Recibos PDF
  Future<List<InvoiceEntity>> getInvoices({String? clientEmail});
  Future<InvoiceEntity> createInvoice({
    required String clientName,
    required String clientNit,
    String? clientEmail,
    String? orderId,
    String? paymentId,
    required List<Map<String, dynamic>> items,
  });
  Future<Uint8List> downloadInvoicePdf(String invoiceId);

  // Pagos y Registro de Transacciones
  Future<PaymentResultEntity> processPayment({
    required String quotationId,
    required double amount,
    required String cardNumber,
    required String cardHolder,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
  });
  Future<List<PaymentLogEntity>> getPaymentLogs(String paymentId);

  // Asistente IA y Reportes
  Future<OnlineAgentReplyEntity> askOnlineAgent({
    required String query,
    String? sessionId,
  });
  Future<OnlineNlReportEntity> generateOnlineReport(String query);
}
