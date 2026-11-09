import 'dart:typed_data';
import 'package:carpinteria_movil_sw2/core/constants/api_constants.dart';
import 'package:carpinteria_movil_sw2/core/network/api_client.dart';
import 'package:carpinteria_movil_sw2/data/models/model.dart';
import 'package:carpinteria_movil_sw2/domain/entities/entity.dart';

class ApiDataSource {
  final ApiClient _apiClient;

  ApiDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // ── Autenticación ───────────────────────────────────────────────────────────

  Future<UserModel> login(String email, String password) async {
    final res = await _apiClient.post(
      ApiConstants.login,
      withAuth: false,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );
    return UserModel.fromJson(res as Map<String, dynamic>);
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final res = await _apiClient.post(
      ApiConstants.register,
      withAuth: false,
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
      },
    );
    return UserModel.fromJson(res as Map<String, dynamic>);
  }

  // ── Catálogo y Compras Directas ─────────────────────────────────────────────

  Future<List<ProductModel>> getMarketplaceProducts() async {
    final res = await _apiClient.get(ApiConstants.marketplaceProducts);
    return _extractList(res)
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }

  Future<ProductModel> upsertMarketplaceProduct(
    Map<String, dynamic> payload, {
    String? id,
  }) async {
    final res = id == null
        ? await _apiClient.post(ApiConstants.marketplaceProducts, body: payload)
        : await _apiClient.put('${ApiConstants.marketplaceProducts}/$id',
            body: payload);
    return ProductModel.fromJson(res as Map<String, dynamic>);
  }

  Future<bool> deleteMarketplaceProduct(String id) async {
    await _apiClient.delete('${ApiConstants.marketplaceProducts}/$id');
    return true;
  }

  Future<Map<String, dynamic>> checkoutMarketplace(
    Map<String, dynamic> payload,
  ) async {
    final res = await _apiClient.post(
      ApiConstants.marketplaceCheckout,
      body: payload,
      timeout: ApiConstants.aiTimeout,
    );
    return res as Map<String, dynamic>;
  }

  /// Sube una imagen (base64) al bucket AWS S3 vía Gateway; devuelve la URL pública.
  Future<String> uploadImageToS3({
    required String base64,
    String fileName = 'mueble.jpg',
    String mimeType = 'image/jpeg',
    String folder = 'marketplace',
  }) async {
    final res = await _apiClient.post(
      ApiConstants.uploadS3,
      body: {
        'base64': base64,
        'fileName': fileName,
        'mimeType': mimeType,
        'folder': folder,
      },
      timeout: ApiConstants.aiTimeout,
    );
    return (res as Map<String, dynamic>)['url'].toString();
  }

  // ── Clientes y Segmentación ─────────────────────────────────────────────────

  Future<List<ClientProfileModel>> getClients({String? search}) async {
    const query = r'''
      query ($search: String) {
        clients(search: $search, page: 0, size: 100) {
          id name email phone address segment
        }
      }
    ''';
    final data = await _apiClient.graphql(
      query,
      variables: {if (search != null && search.isNotEmpty) 'search': search},
    );
    final list = _extractList(data['clients']);
    return list
        .whereType<Map<String, dynamic>>()
        .map(ClientProfileModel.fromJson)
        .toList();
  }

  Future<ClientProfileModel> createClient(Map<String, dynamic> input) async {
    const mutation = r'''
      mutation ($input: ClientInput!) {
        createClient(input: $input) {
          id name email phone address segment
        }
      }
    ''';
    final data = await _apiClient.graphql(mutation, variables: {'input': input});
    return ClientProfileModel.fromJson(
      data['createClient'] as Map<String, dynamic>,
    );
  }

  Future<ClientProfileModel> updateClient(
    String id,
    Map<String, dynamic> input,
  ) async {
    const mutation = r'''
      mutation ($id: ID!, $input: ClientInput!) {
        updateClient(id: $id, input: $input) {
          id name email phone address segment
        }
      }
    ''';
    final data = await _apiClient.graphql(
      mutation,
      variables: {'id': id, 'input': input},
    );
    return ClientProfileModel.fromJson(
      data['updateClient'] as Map<String, dynamic>,
    );
  }

  Future<bool> deleteClient(String id) async {
    const mutation = r'''
      mutation ($id: ID!) {
        deleteClient(id: $id)
      }
    ''';
    final data = await _apiClient.graphql(mutation, variables: {'id': id});
    return data['deleteClient'] == true;
  }

  Future<List<ClientClusterModel>> clusterClients() async {
    final res = await _apiClient.post(ApiConstants.aiClusterClients, body: {});
    if (res is Map<String, dynamic> && res['clusters'] is List) {
      return (res['clusters'] as List)
          .whereType<Map<String, dynamic>>()
          .map(ClientClusterModel.fromJson)
          .toList();
    }
    return [];
  }

  // ── Carpinteros y Taller ────────────────────────────────────────────────────

  Future<List<CarpenterModel>> getCarpenters({bool activeOnly = false}) async {
    const query = r'''
      query ($activeOnly: Boolean) {
        carpenters(activeOnly: $activeOnly) {
          id name email phone specialty yearsExperience hourlyRate active
        }
      }
    ''';
    final data = await _apiClient.graphql(
      query,
      variables: {'activeOnly': activeOnly},
    );
    final list = _extractList(data['carpenters']);
    return list
        .whereType<Map<String, dynamic>>()
        .map(CarpenterModel.fromJson)
        .toList();
  }

  Future<CarpenterModel> createCarpenter(Map<String, dynamic> input) async {
    const mutation = r'''
      mutation ($input: CarpenterInput!) {
        createCarpenter(input: $input) {
          id name email phone specialty yearsExperience hourlyRate active
        }
      }
    ''';
    final data = await _apiClient.graphql(mutation, variables: {'input': input});
    return CarpenterModel.fromJson(
      data['createCarpenter'] as Map<String, dynamic>,
    );
  }

  Future<CarpenterModel> updateCarpenter(
    String id,
    Map<String, dynamic> input,
  ) async {
    const mutation = r'''
      mutation ($id: ID!, $input: CarpenterInput!) {
        updateCarpenter(id: $id, input: $input) {
          id name email phone specialty yearsExperience hourlyRate active
        }
      }
    ''';
    final data = await _apiClient.graphql(
      mutation,
      variables: {'id': id, 'input': input},
    );
    return CarpenterModel.fromJson(
      data['updateCarpenter'] as Map<String, dynamic>,
    );
  }

  Future<bool> deleteCarpenter(String id) async {
    const mutation = r'''
      mutation ($id: ID!) {
        deleteCarpenter(id: $id)
      }
    ''';
    final data = await _apiClient.graphql(mutation, variables: {'id': id});
    return data['deleteCarpenter'] == true;
  }

  Future<List<OrderModel>> getCarpenterWorkload(String carpenterId) async {
    const query = r'''
      query ($id: ID!) {
        carpenterWorkload(id: $id) {
          id status description totalAmount estimatedDeliveryDate
          client { id name email phone }
          steps { id name status sequence }
        }
      }
    ''';
    final data = await _apiClient.graphql(query, variables: {'id': carpenterId});
    final list = _extractList(data['carpenterWorkload']);
    return list
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();
  }

  // ── Cotizaciones y Negociación ──────────────────────────────────────────────

  Future<AiEstimateModel> estimateFurniture({
    required String description,
    required String woodType,
    String? imageBase64,
  }) async {
    final res = await _apiClient.post(
      ApiConstants.aiEstimate,
      body: {
        'description': description,
        'woodType': woodType,
        'imageBase64': imageBase64,
      },
    );
    return AiEstimateModel.fromJson(res as Map<String, dynamic>);
  }

  Future<List<QuotationModel>> getQuotations({String? status}) async {
    final res = await _apiClient.get(
      ApiConstants.quotations,
      queryParams: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final list = _extractList(res);
    return list
        .whereType<Map<String, dynamic>>()
        .map(QuotationModel.fromJson)
        .toList();
  }

  Future<QuotationModel> createQuotation(Map<String, dynamic> payload) async {
    final res = await _apiClient.post(ApiConstants.quotations, body: payload);
    return QuotationModel.fromJson(res as Map<String, dynamic>);
  }

  Future<QuotationModel> respondQuotation({
    required String id,
    required String action,
    double? counterAmount,
    String? message,
  }) async {
    final res = await _apiClient.post(
      '${ApiConstants.quotations}/$id/respond',
      body: {
        'action': action,
        'counterAmount': ?counterAmount,
        if (message != null && message.isNotEmpty) 'message': message,
      },
    );
    return QuotationModel.fromJson(res as Map<String, dynamic>);
  }

  Future<QuotationModel> sendQuotationFormalPrice({
    required String id,
    required double finalAmount,
    String? notes,
  }) async {
    final res = await _apiClient.post(
      '${ApiConstants.quotations}/$id/send',
      body: {
        'finalAmount': finalAmount,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return QuotationModel.fromJson(res as Map<String, dynamic>);
  }

  Future<QuotationModel> approveQuotation({
    required String id,
    double? finalAmount,
    String? notes,
  }) async {
    final res = await _apiClient.post(
      '${ApiConstants.quotations}/$id/approve',
      body: {
        'finalAmount': ?finalAmount,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return QuotationModel.fromJson(res as Map<String, dynamic>);
  }

  Future<QuotationModel> rejectQuotation({
    required String id,
    String? reason,
  }) async {
    final res = await _apiClient.post(
      '${ApiConstants.quotations}/$id/reject',
      body: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return QuotationModel.fromJson(res as Map<String, dynamic>);
  }

  // ── Pedidos, Pasos de Producción y Entregas ─────────────────────────────────

  Future<List<OrderModel>> getOrders() async {
    const query = r'''
      query {
        orders(page: 0, size: 100) {
          id status description totalAmount createdAt estimatedDeliveryDate
          quotationId deliveryType deliveryAddress deliveryLat deliveryLng
          client { id name email phone address }
          items { id furnitureType woodType dimensions quantity unitPrice }
          steps { id name status sequence }
          carpenters { id name specialty }
          delivery { id scheduledDate timeSlot address status notes deliveryType latitude longitude }
        }
      }
    ''';
    final data = await _apiClient.graphql(query);
    final list = _extractList(data['orders']);
    return list
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();
  }

  Future<OrderModel> createOrderGraphql(Map<String, dynamic> input) async {
    const mutation = r'''
      mutation ($input: OrderInput!) {
        createOrder(input: $input) {
          id status description totalAmount createdAt estimatedDeliveryDate
          quotationId deliveryType deliveryAddress deliveryLat deliveryLng
          client { id name email phone address }
          items { id furnitureType woodType dimensions quantity unitPrice }
          steps { id name status sequence }
          carpenters { id name specialty }
        }
      }
    ''';
    final data = await _apiClient.graphql(mutation, variables: {'input': input});
    return OrderModel.fromJson(data['createOrder'] as Map<String, dynamic>);
  }

  Future<OrderModel> updateOrderStatus(String orderId, String newStatus) async {
    const mutation = r'''
      mutation ($id: ID!, $status: OrderStatus!) {
        updateOrderStatus(id: $id, status: $status) {
          id status description totalAmount createdAt estimatedDeliveryDate
          quotationId deliveryType deliveryAddress deliveryLat deliveryLng
          client { id name email phone address }
          items { id furnitureType woodType dimensions quantity unitPrice }
          steps { id name status sequence }
          carpenters { id name specialty }
          delivery { id scheduledDate timeSlot address status notes deliveryType latitude longitude }
        }
      }
    ''';
    final backendStatus = OrderEntity.toBackendStatus(newStatus);
    final data = await _apiClient.graphql(
      mutation,
      variables: {'id': orderId, 'status': backendStatus},
    );
    return OrderModel.fromJson(
      data['updateOrderStatus'] as Map<String, dynamic>,
    );
  }

  Future<OrderModel> assignCarpenter(String orderId, String carpenterId) async {
    const mutation = r'''
      mutation ($orderId: ID!, $carpenterId: ID!) {
        assignCarpenter(orderId: $orderId, carpenterId: $carpenterId) {
          id status description totalAmount createdAt estimatedDeliveryDate
          client { id name email phone address }
          items { id furnitureType woodType dimensions quantity unitPrice }
          steps { id name status sequence }
          carpenters { id name specialty }
        }
      }
    ''';
    final data = await _apiClient.graphql(
      mutation,
      variables: {'orderId': orderId, 'carpenterId': carpenterId},
    );
    return OrderModel.fromJson(data['assignCarpenter'] as Map<String, dynamic>);
  }

  Future<ProductionStepModel> updateStepStatus(
    String stepId,
    String status,
  ) async {
    const mutation = r'''
      mutation ($stepId: ID!, $status: StepStatus!) {
        updateStepStatus(stepId: $stepId, status: $status) {
          id name status sequence
        }
      }
    ''';
    final data = await _apiClient.graphql(
      mutation,
      variables: {'stepId': stepId, 'status': status.toUpperCase()},
    );
    return ProductionStepModel.fromJson(
      data['updateStepStatus'] as Map<String, dynamic>,
    );
  }

  Future<OrderModel> linkQuotation(String orderId, String quotationId) async {
    const mutation = r'''
      mutation ($orderId: ID!, $quotationId: String!) {
        linkQuotation(orderId: $orderId, quotationId: $quotationId) {
          id quotationId status
        }
      }
    ''';
    final data = await _apiClient.graphql(
      mutation,
      variables: {'orderId': orderId, 'quotationId': quotationId},
    );
    return OrderModel.fromJson(data['linkQuotation'] as Map<String, dynamic>);
  }

  Future<List<DeliveryModel>> getDeliveries({String? status}) async {
    const query = r'''
      query ($status: DeliveryStatus) {
        deliveries(status: $status) {
          id scheduledDate timeSlot address status notes deliveryType latitude longitude
          order { id status description totalAmount client { id name phone } }
        }
      }
    ''';
    final data = await _apiClient.graphql(
      query,
      variables: {if (status != null && status.isNotEmpty) 'status': status},
    );
    final list = _extractList(data['deliveries']);
    return list
        .whereType<Map<String, dynamic>>()
        .map(DeliveryModel.fromJson)
        .toList();
  }

  Future<DeliveryCapacityModel> getDeliveryCapacity(String date) async {
    try {
      const query = r'''
        query ($date: Date!) {
          deliveryCapacity(date: $date) {
            date scheduledCount maxPerDay remainingSlots available
          }
        }
      ''';
      final data = await _apiClient.graphql(query, variables: {'date': date});
      return DeliveryCapacityModel.fromJson(
        data['deliveryCapacity'] as Map<String, dynamic>,
      );
    } catch (_) {
      final res = await _apiClient.get(
        ApiConstants.aiDeliveryCheck,
        queryParams: {'date': date},
      );
      return DeliveryCapacityModel.fromJson(res as Map<String, dynamic>);
    }
  }

  Future<DeliveryModel> scheduleDelivery(Map<String, dynamic> input) async {
    const mutation = r'''
      mutation ($input: DeliveryInput!) {
        scheduleDelivery(input: $input) {
          id scheduledDate timeSlot address status notes deliveryType latitude longitude
          order { id }
        }
      }
    ''';
    final data = await _apiClient.graphql(mutation, variables: {'input': input});
    return DeliveryModel.fromJson(
      data['scheduleDelivery'] as Map<String, dynamic>,
    );
  }

  Future<DeliveryModel> updateDeliveryStatus(String id, String status) async {
    const mutation = r'''
      mutation ($id: ID!, $status: DeliveryStatus!) {
        updateDeliveryStatus(id: $id, status: $status) {
          id status scheduledDate timeSlot address notes deliveryType latitude longitude
          order { id }
        }
      }
    ''';
    final data = await _apiClient.graphql(
      mutation,
      variables: {'id': id, 'status': status.toUpperCase()},
    );
    return DeliveryModel.fromJson(
      data['updateDeliveryStatus'] as Map<String, dynamic>,
    );
  }

  Future<DeliveryModel> rescheduleDelivery({
    required String id,
    required String newDate,
    String? timeSlot,
  }) async {
    const mutation = r'''
      mutation ($id: ID!, $newDate: Date!, $timeSlot: String) {
        rescheduleDelivery(id: $id, newDate: $newDate, timeSlot: $timeSlot) {
          id scheduledDate timeSlot status address notes deliveryType latitude longitude
          order { id }
        }
      }
    ''';
    final data = await _apiClient.graphql(
      mutation,
      variables: {
        'id': id,
        'newDate': newDate,
        'timeSlot': ?timeSlot,
      },
    );
    return DeliveryModel.fromJson(
      data['rescheduleDelivery'] as Map<String, dynamic>,
    );
  }

  // ── Facturas y Recibos PDF ──────────────────────────────────────────────────

  Future<List<InvoiceModel>> getInvoices({String? clientEmail}) async {
    final res = await _apiClient.get(
      ApiConstants.invoices,
      queryParams: {
        if (clientEmail != null && clientEmail.isNotEmpty)
          'client_email': clientEmail,
      },
    );
    final list = _extractList(res);
    return list
        .whereType<Map<String, dynamic>>()
        .map(InvoiceModel.fromJson)
        .toList();
  }

  Future<InvoiceModel> createInvoice(Map<String, dynamic> payload) async {
    final res = await _apiClient.post(ApiConstants.invoices, body: payload);
    return InvoiceModel.fromJson(res as Map<String, dynamic>);
  }

  Future<Uint8List> downloadInvoicePdf(String invoiceId) async {
    return _apiClient.getBytes('${ApiConstants.invoices}/$invoiceId/download');
  }

  // ── Pagos y Registro de Transacciones ───────────────────────────────────────

  Future<PaymentResultModel> processPayment(Map<String, dynamic> payload) async {
    final res = await _apiClient.post(ApiConstants.payments, body: payload);
    return PaymentResultModel.fromJson(res as Map<String, dynamic>);
  }

  Future<List<PaymentLogModel>> getPaymentLogs(String paymentId) async {
    final res = await _apiClient.get('${ApiConstants.payments}/$paymentId/logs');
    final list = _extractList(res);
    return list
        .whereType<Map<String, dynamic>>()
        .map(PaymentLogModel.fromJson)
        .toList();
  }

  // ── Asistente Inteligente y Reportes ────────────────────────────────────────

  Future<OnlineAgentReplyModel> askOnlineAgent({
    required String query,
    String? sessionId,
  }) async {
    final res = await _apiClient.post(
      ApiConstants.aiAgent,
      body: {
        'query': query,
        'session_id': ?sessionId,
      },
    );
    return OnlineAgentReplyModel.fromJson(res as Map<String, dynamic>);
  }

  Future<OnlineNlReportModel> generateOnlineReport(String query) async {
    final res = await _apiClient.post(
      ApiConstants.aiReport,
      body: {'query': query},
    );
    return OnlineNlReportModel.fromJson(res as Map<String, dynamic>);
  }

  List<dynamic> _extractList(dynamic res) {
    if (res is List) return res;
    if (res is Map<String, dynamic>) {
      if (res['data'] is List) return res['data'] as List<dynamic>;
      if (res['items'] is List) return res['items'] as List<dynamic>;
      if (res['results'] is List) return res['results'] as List<dynamic>;
    }
    return [];
  }
}
