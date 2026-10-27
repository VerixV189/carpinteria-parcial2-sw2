import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:carpinteria_movil_sw2/core/errors/app_exception.dart';
import 'package:carpinteria_movil_sw2/core/storage/local_storage.dart';
import 'package:carpinteria_movil_sw2/data/datasources/local/local_data_source.dart';
import 'package:carpinteria_movil_sw2/data/datasources/remote/api_data_source.dart';
import 'package:carpinteria_movil_sw2/data/models/model.dart';
import 'package:carpinteria_movil_sw2/domain/entities/entity.dart';
import 'package:carpinteria_movil_sw2/domain/repositories/repository.dart';

class CarpentryRepositoryImpl implements CarpentryRepository {
  final ApiDataSource _remote;
  final LocalDataSource _local;
  bool _isUsingMock = false;

  CarpentryRepositoryImpl({
    ApiDataSource? remote,
    LocalDataSource? local,
  })  : _remote = remote ?? ApiDataSource(),
        _local = local ?? LocalDataSource();

  @override
  bool get isUsingMock => _isUsingMock;

  UserModel? _currentSavedUser() {
    final json = LocalStorage.getUser();
    final token = LocalStorage.getToken();
    if (json == null) return null;
    return UserModel.fromJson(json, tokenOverride: token);
  }

  // ── Auth ────────────────────────────────────────────────────────────────────

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remote.login(email, password);
      _isUsingMock = false;
      if (user.token != null) {
        await LocalStorage.saveToken(user.token!);
      }
      await LocalStorage.saveUser(user.toJson());
      return user;
    } on AuthException {
      rethrow;
    } catch (_) {
      // Fallback híbrido cuando el backend no está alcanzable
      _isUsingMock = true;
      final localUser = await _local.loginLocal(email, password);
      if (localUser.token != null) {
        await LocalStorage.saveToken(localUser.token!);
      }
      await LocalStorage.saveUser(localUser.toJson());
      return localUser;
    }
  }

  @override
  Future<UserEntity> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      final user = await _remote.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      _isUsingMock = false;
      if (user.token != null) {
        await LocalStorage.saveToken(user.token!);
      }
      await LocalStorage.saveUser(user.toJson());
      return user;
    } on AuthException {
      rethrow;
    } catch (_) {
      _isUsingMock = true;
      final localUser = await _local.registerLocal(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      if (localUser.token != null) {
        await LocalStorage.saveToken(localUser.token!);
      }
      await LocalStorage.saveUser(localUser.toJson());
      return localUser;
    }
  }

  @override
  Future<void> logout() async {
    await LocalStorage.clearSession();
  }

  @override
  Future<UserEntity?> getSavedSession() async {
    await LocalStorage.init();
    final json = LocalStorage.getUser();
    final token = LocalStorage.getToken();
    if (json == null) return null;
    _isUsingMock = token != null && token.startsWith('mock-jwt-token');
    return UserModel.fromJson(json, tokenOverride: token);
  }

  // ── Catálogo e Inventario ───────────────────────────────────────────────────

  @override
  Future<List<ProductEntity>> getProducts() async {
    // En la arquitectura web (Frontend1-React-Portal/src/catalog.ts),
    // el catálogo base es servido directamente al cliente y taller.
    return _local.getProducts();
  }

  @override
  Future<List<WoodMaterialEntity>> getMaterials() async {
    return _local.getMaterials();
  }

  // ── CU1: Clientes & Segmentación IA ─────────────────────────────────────────

  @override
  Future<List<ClientProfileEntity>> getClients({String? search}) async {
    try {
      final list = await _remote.getClients(search: search);
      _isUsingMock = false;
      return list;
    } catch (_) {
      return _local.getClients(search: search);
    }
  }

  @override
  Future<ClientProfileEntity> createClient({
    required String name,
    required String email,
    String? phone,
    String? address,
    String segment = 'REGULAR',
  }) async {
    try {
      final created = await _remote.createClient({
        'name': name,
        'email': email,
        'phone': ?phone,
        'address': ?address,
        'segment': segment,
      });
      _isUsingMock = false;
      return created;
    } catch (_) {
      final model = ClientProfileModel(
        id: 'CLI-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
        name: name,
        email: email,
        phone: phone ?? '',
        address: address ?? '',
        segment: segment,
      );
      return _local.createClient(model);
    }
  }

  @override
  Future<ClientProfileEntity> updateClient({
    required String id,
    required String name,
    required String email,
    String? phone,
    String? address,
    String segment = 'REGULAR',
  }) async {
    try {
      final updated = await _remote.updateClient(id, {
        'name': name,
        'email': email,
        'phone': ?phone,
        'address': ?address,
        'segment': segment,
      });
      _isUsingMock = false;
      return updated;
    } catch (_) {
      final model = ClientProfileModel(
        id: id,
        name: name,
        email: email,
        phone: phone ?? '',
        address: address ?? '',
        segment: segment,
      );
      return _local.updateClient(model);
    }
  }

  @override
  Future<bool> deleteClient(String id) async {
    try {
      return await _remote.deleteClient(id);
    } catch (_) {
      return _local.deleteClient(id);
    }
  }

  @override
  Future<List<ClientClusterEntity>> clusterClients() async {
    try {
      return await _remote.clusterClients();
    } catch (_) {
      final clients = _local.getClients();
      return [
        ClientClusterModel(
          clusterId: 0,
          label: 'Clientes Frecuentes / VIP',
          size: clients.where((c) => c.segment == 'VIP').length,
          clientIds:
              clients.where((c) => c.segment == 'VIP').map((c) => c.id).toList(),
          centroid: const {'orders_avg': 3.5, 'spend_avg': 4200},
        ),
        ClientClusterModel(
          clusterId: 1,
          label: 'Compras Residenciales (Regular)',
          size: clients.where((c) => c.segment == 'REGULAR').length,
          clientIds: clients
              .where((c) => c.segment == 'REGULAR')
              .map((c) => c.id)
              .toList(),
          centroid: const {'orders_avg': 1.2, 'spend_avg': 2100},
        ),
        ClientClusterModel(
          clusterId: 2,
          label: 'Corporativos / Mayoristas',
          size: clients.where((c) => c.segment == 'WHOLESALE').length,
          clientIds: clients
              .where((c) => c.segment == 'WHOLESALE')
              .map((c) => c.id)
              .toList(),
          centroid: const {'orders_avg': 6.0, 'spend_avg': 11500},
        ),
      ];
    }
  }

  // ── CU2: Carpinteros & Taller ───────────────────────────────────────────────

  @override
  Future<List<CarpenterEntity>> getCarpenters({bool activeOnly = false}) async {
    try {
      final list = await _remote.getCarpenters(activeOnly: activeOnly);
      _isUsingMock = false;
      return list;
    } catch (_) {
      return _local.getCarpenters();
    }
  }

  @override
  Future<CarpenterEntity> createCarpenter({
    required String name,
    required String email,
    String? phone,
    required String specialty,
    int yearsExperience = 3,
    double hourlyRate = 45.0,
    bool active = true,
  }) async {
    try {
      return await _remote.createCarpenter({
        'name': name,
        'email': email,
        'phone': ?phone,
        'specialty': specialty,
        'yearsExperience': yearsExperience,
        'hourlyRate': hourlyRate,
        'active': active,
      });
    } catch (_) {
      final model = CarpenterModel(
        id: 'CARP-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
        name: name,
        email: email,
        phone: phone ?? '',
        specialty: specialty,
        yearsExperience: yearsExperience,
        hourlyRate: hourlyRate,
        active: active,
      );
      return _local.createCarpenter(model);
    }
  }

  @override
  Future<CarpenterEntity> updateCarpenter({
    required String id,
    required String name,
    required String email,
    String? phone,
    required String specialty,
    int yearsExperience = 3,
    double hourlyRate = 45.0,
    bool active = true,
  }) async {
    try {
      return await _remote.updateCarpenter(id, {
        'name': name,
        'email': email,
        'phone': ?phone,
        'specialty': specialty,
        'yearsExperience': yearsExperience,
        'hourlyRate': hourlyRate,
        'active': active,
      });
    } catch (_) {
      final model = CarpenterModel(
        id: id,
        name: name,
        email: email,
        phone: phone ?? '',
        specialty: specialty,
        yearsExperience: yearsExperience,
        hourlyRate: hourlyRate,
        active: active,
      );
      return _local.updateCarpenter(model);
    }
  }

  @override
  Future<bool> deleteCarpenter(String id) async {
    try {
      return await _remote.deleteCarpenter(id);
    } catch (_) {
      return _local.deleteCarpenter(id);
    }
  }

  @override
  Future<List<OrderEntity>> getCarpenterWorkload(String carpenterId) async {
    try {
      return await _remote.getCarpenterWorkload(carpenterId);
    } catch (_) {
      return _local
          .getOrders()
          .where((o) => o.carpenters.any((c) => c.id == carpenterId))
          .toList();
    }
  }

  // ── CU3: Cotizaciones con IA & Negociación ──────────────────────────────────

  @override
  Future<AiEstimateEntity> estimateFurniture({
    required String description,
    required String woodType,
    String? imageBase64,
  }) async {
    try {
      final res = await _remote.estimateFurniture(
        description: description,
        woodType: woodType,
        imageBase64: imageBase64,
      );
      _isUsingMock = false;
      return res;
    } catch (_) {
      // Estimador heurístico local si el microservicio Python no responde
      final lower = description.toLowerCase();
      String type = 'mueble a medida';
      double basePrice = 1800.0;
      if (lower.contains('ropero') || lower.contains('closet')) {
        type = 'ropero';
        basePrice = 3600.0;
      } else if (lower.contains('cocina')) {
        type = 'mueble de cocina';
        basePrice = 4500.0;
      } else if (lower.contains('mesa')) {
        type = 'mesa';
        basePrice = 2200.0;
      } else if (lower.contains('silla')) {
        type = 'juego de sillas';
        basePrice = 1600.0;
      } else if (lower.contains('puerta')) {
        type = 'puerta';
        basePrice = 1850.0;
      } else if (lower.contains('escritorio')) {
        type = 'escritorio';
        basePrice = 1500.0;
      }
      final woodFactor = woodType.toLowerCase().contains('roble') ||
              woodType.toLowerCase().contains('mara')
          ? 1.2
          : (woodType.toLowerCase().contains('cedro') ? 1.15 : 1.0);
      return AiEstimateModel(
        furnitureType: type,
        confidence: 0.88,
        estimatedPrice: (basePrice * woodFactor).roundToDouble(),
        currency: 'BOB',
        factors: {
          'woodType': woodType,
          'woodMultiplier': woodFactor,
          'mode': 'local_fallback',
        },
      );
    }
  }

  @override
  Future<List<QuotationEntity>> getQuotations({String? status}) async {
    try {
      final list = await _remote.getQuotations(status: status);
      _isUsingMock = false;
      return list;
    } catch (_) {
      return _local.getQuotations(status: status);
    }
  }

  @override
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
  }) async {
    final payload = <String, dynamic>{
      'clientId': clientId,
      'photoUrl': photoUrl,
      'aiEstimate': aiEstimate != null
          ? {
              'furnitureType': aiEstimate.furnitureType,
              'confidence': aiEstimate.confidence,
              'estimatedPrice': aiEstimate.estimatedPrice,
              'currency': aiEstimate.currency,
              'factors': aiEstimate.factors,
            }
          : null,
      'delivery': {
        'type': deliveryType,
        'address': deliveryType == 'DELIVERY' ? (deliveryAddress ?? '') : null,
        'latitude': deliveryType == 'DELIVERY' ? latitude : null,
        'longitude': deliveryType == 'DELIVERY' ? longitude : null,
      },
      'items': [
        {
          'description': description,
          'woodType': woodType,
          'quantity': quantity,
          'estimatedPrice': estimatedPrice,
        },
      ],
    };

    try {
      final created = await _remote.createQuotation(payload);
      _isUsingMock = false;
      return created;
    } catch (_) {
      final localQ = QuotationModel(
        id: 'Q-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        clientId: clientId,
        status: 'DRAFT',
        photoUrl: photoUrl,
        description: description,
        woodType: woodType,
        totalAmount: estimatedPrice * quantity,
        deliveryType: deliveryType,
        deliveryAddress: deliveryAddress ?? '',
        deliveryLatitude: latitude,
        deliveryLongitude: longitude,
        aiEstimate: aiEstimate,
        createdAt: DateTime.now().toIso8601String().substring(0, 10),
      );
      return _local.addOrUpdateQuotation(localQ);
    }
  }

  @override
  Future<QuotationEntity> respondQuotation({
    required String id,
    required String action,
    double? counterAmount,
    String? message,
  }) async {
    try {
      final updated = await _remote.respondQuotation(
        id: id,
        action: action,
        counterAmount: counterAmount,
        message: message,
      );
      _isUsingMock = false;
      return updated;
    } catch (_) {
      final existing = _local.getQuotations().firstWhere(
            (q) => q.id == id,
            orElse: () => _local.getQuotations().first,
          );
      final newStatus = action == 'accept'
          ? 'APPROVED'
          : (action == 'reject' ? 'REJECTED' : 'DRAFT');
      final updated = QuotationModel(
        id: existing.id,
        clientId: existing.clientId,
        status: newStatus,
        photoUrl: existing.photoUrl,
        description: existing.description,
        woodType: existing.woodType,
        totalAmount: existing.totalAmount,
        finalAmount: existing.finalAmount,
        notes: existing.notes,
        clientMessage: message ?? existing.clientMessage,
        counterAmount: counterAmount ?? existing.counterAmount,
        deliveryType: existing.deliveryType,
        deliveryAddress: existing.deliveryAddress,
        deliveryLatitude: existing.deliveryLatitude,
        deliveryLongitude: existing.deliveryLongitude,
        aiEstimate: existing.aiEstimate,
        createdAt: existing.createdAt,
      );
      return _local.addOrUpdateQuotation(updated);
    }
  }

  @override
  Future<QuotationEntity> sendQuotationFormalPrice({
    required String id,
    required double finalAmount,
    String? notes,
  }) async {
    try {
      final updated = await _remote.sendQuotationFormalPrice(
        id: id,
        finalAmount: finalAmount,
        notes: notes,
      );
      _isUsingMock = false;
      return updated;
    } catch (_) {
      final existing = _local.getQuotations().firstWhere((q) => q.id == id);
      final updated = QuotationModel(
        id: existing.id,
        clientId: existing.clientId,
        status: 'QUOTED',
        photoUrl: existing.photoUrl,
        description: existing.description,
        woodType: existing.woodType,
        totalAmount: existing.totalAmount,
        finalAmount: finalAmount,
        notes: notes ?? existing.notes,
        clientMessage: existing.clientMessage,
        counterAmount: existing.counterAmount,
        deliveryType: existing.deliveryType,
        deliveryAddress: existing.deliveryAddress,
        deliveryLatitude: existing.deliveryLatitude,
        deliveryLongitude: existing.deliveryLongitude,
        aiEstimate: existing.aiEstimate,
        createdAt: existing.createdAt,
      );
      return _local.addOrUpdateQuotation(updated);
    }
  }

  @override
  Future<QuotationEntity> approveQuotation({
    required String id,
    double? finalAmount,
    String? notes,
  }) async {
    try {
      return await _remote.approveQuotation(
        id: id,
        finalAmount: finalAmount,
        notes: notes,
      );
    } catch (_) {
      final existing = _local.getQuotations().firstWhere((q) => q.id == id);
      final updated = QuotationModel(
        id: existing.id,
        clientId: existing.clientId,
        status: 'APPROVED',
        photoUrl: existing.photoUrl,
        description: existing.description,
        woodType: existing.woodType,
        totalAmount: existing.totalAmount,
        finalAmount: finalAmount ?? existing.finalAmount ?? existing.totalAmount,
        notes: notes ?? existing.notes,
        deliveryType: existing.deliveryType,
        deliveryAddress: existing.deliveryAddress,
        createdAt: existing.createdAt,
      );
      return _local.addOrUpdateQuotation(updated);
    }
  }

  @override
  Future<QuotationEntity> rejectQuotation({
    required String id,
    String? reason,
  }) async {
    try {
      return await _remote.rejectQuotation(id: id, reason: reason);
    } catch (_) {
      final existing = _local.getQuotations().firstWhere((q) => q.id == id);
      final updated = QuotationModel(
        id: existing.id,
        clientId: existing.clientId,
        status: 'REJECTED',
        photoUrl: existing.photoUrl,
        description: existing.description,
        woodType: existing.woodType,
        totalAmount: existing.totalAmount,
        finalAmount: existing.finalAmount,
        notes: reason ?? existing.notes,
        deliveryType: existing.deliveryType,
        deliveryAddress: existing.deliveryAddress,
        createdAt: existing.createdAt,
      );
      return _local.addOrUpdateQuotation(updated);
    }
  }

  // ── CU4: Pedidos, Pasos de Producción y Entregas ────────────────────────────

  @override
  Future<List<OrderEntity>> getOrders() async {
    final user = _currentSavedUser();
    // Si el usuario es CLIENT, el endpoint /graphql está restringido por RBAC en el Gateway.
    // Obtenemos sus cotizaciones/pedidos desde /api/quotations y /api/invoices en modo Online.
    if (user != null && user.isClient) {
      try {
        final quotes = await _remote.getQuotations();
        _isUsingMock = false;
        return quotes.map((q) {
          final isPaid = q.status.toUpperCase() == 'CONVERTED';
          final isReadyToPay = q.status.toUpperCase() == 'APPROVED' ||
              q.status.toUpperCase() == 'QUOTED';
          return OrderModel(
            id: q.id,
            clientId: q.clientId,
            clientName: user.name,
            clientEmail: user.email,
            clientPhone: user.phone,
            productName: q.description,
            woodType: q.woodType,
            specifications: q.notes ??
                (q.deliveryType == 'PICKUP'
                    ? 'Recojo en taller'
                    : 'Entrega en ${q.deliveryAddress}'),
            totalAmount: q.payableAmount,
            advancePayment: isPaid ? q.payableAmount : 0.0,
            status: isPaid
                ? 'En fabricación'
                : (isReadyToPay ? 'Aprobado' : 'Pendiente'),
            rawStatus: isPaid
                ? 'IN_PRODUCTION'
                : (isReadyToPay ? 'APPROVED' : 'PENDING'),
            deliveryDate: q.createdAt,
            createdAt: q.createdAt,
            quotationId: q.id,
            deliveryType: q.deliveryType,
            deliveryAddress: q.deliveryAddress,
            deliveryLat: q.deliveryLatitude,
            deliveryLng: q.deliveryLongitude,
          );
        }).toList();
      } catch (_) {
        _isUsingMock = true;
        return _local.getOrders();
      }
    }

    try {
      final list = await _remote.getOrders();
      _isUsingMock = false;
      return list;
    } catch (_) {
      _isUsingMock = true;
      return _local.getOrders();
    }
  }

  @override
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
  }) async {
    final user = _currentSavedUser();
    // Si es un CLIENT comprando o cotizando en modo Online, creamos la cotización en Backend2
    if (user != null && user.isClient) {
      try {
        final q = await createQuotation(
          clientId: user.email.isNotEmpty ? user.email : user.id,
          description: '$productName — $specifications',
          woodType: woodType,
          estimatedPrice: totalAmount,
          deliveryType: deliveryType,
          deliveryAddress: deliveryAddress ?? specifications,
          latitude: deliveryLat,
          longitude: deliveryLng,
        );
        _isUsingMock = false;
        return OrderModel(
          id: q.id,
          clientId: q.clientId,
          clientName: clientName,
          clientEmail: user.email,
          productName: productName,
          woodType: woodType,
          specifications: specifications,
          totalAmount: totalAmount,
          advancePayment: advancePayment,
          status: 'Pendiente',
          rawStatus: 'PENDING',
          deliveryDate: deliveryDate,
          createdAt: q.createdAt,
          quotationId: q.id,
          deliveryType: deliveryType,
          deliveryAddress: deliveryAddress ?? '',
          deliveryLat: deliveryLat,
          deliveryLng: deliveryLng,
        );
      } catch (_) {}
    }

    // Si es ADMIN o CARPENTER, creamos el pedido en Backend1 via GraphQL
    try {
      String resolvedClientId = clientId ?? '';
      if (resolvedClientId.isEmpty) {
        final clients = await _remote.getClients();
        if (clients.isNotEmpty) {
          final match = clients.where(
            (c) => c.name.toLowerCase().contains(clientName.toLowerCase()),
          );
          resolvedClientId =
              match.isNotEmpty ? match.first.id : clients.first.id;
        } else {
          final createdCli = await _remote.createClient({
            'name': clientName,
            'email':
                '${clientName.toLowerCase().replaceAll(' ', '.')}@cliente.bo',
            'segment': 'REGULAR',
          });
          resolvedClientId = createdCli.id;
        }
      }

      // Convertir DD/MM/YYYY a YYYY-MM-DD si es necesario para GraphQL Date
      String isoDate = deliveryDate;
      if (deliveryDate.contains('/')) {
        final parts = deliveryDate.split('/');
        if (parts.length == 3) {
          isoDate =
              '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
        }
      }

      final created = await _remote.createOrderGraphql({
        'clientId': resolvedClientId,
        'description': '$productName — $specifications',
        'estimatedDeliveryDate': isoDate,
        'deliveryType': deliveryType,
        'deliveryAddress': deliveryAddress,
        'deliveryLat': deliveryLat,
        'deliveryLng': deliveryLng,
        'items': [
          {
            'furnitureType': productName,
            'woodType': woodType,
            'dimensions': 'Estándar',
            'quantity': 1,
            'unitPrice': totalAmount,
          },
        ],
      });
      _isUsingMock = false;
      return created;
    } catch (_) {
      _isUsingMock = true;
      return _local.createOrder(
        clientName: clientName,
        productName: productName,
        woodType: woodType,
        specifications: specifications,
        totalAmount: totalAmount,
        advancePayment: advancePayment,
        deliveryDate: deliveryDate,
        deliveryType: deliveryType,
        deliveryAddress: deliveryAddress,
        deliveryLat: deliveryLat,
        deliveryLng: deliveryLng,
      );
    }
  }

  @override
  Future<OrderEntity> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final updated = await _remote.updateOrderStatus(orderId, newStatus);
      _isUsingMock = false;
      return updated;
    } catch (_) {
      return _local.updateOrderStatus(orderId, newStatus);
    }
  }

  @override
  Future<OrderEntity> assignCarpenter(
    String orderId,
    String carpenterId,
  ) async {
    return _remote.assignCarpenter(orderId, carpenterId);
  }

  @override
  Future<ProductionStepEntity> updateStepStatus(
    String stepId,
    String status,
  ) async {
    try {
      return await _remote.updateStepStatus(stepId, status);
    } catch (_) {
      return _local.updateStepStatus(stepId, status);
    }
  }

  @override
  Future<OrderEntity> linkQuotation(
    String orderId,
    String quotationId,
  ) async {
    return _remote.linkQuotation(orderId, quotationId);
  }

  @override
  Future<List<DeliveryEntity>> getDeliveries({String? status}) async {
    try {
      final list = await _remote.getDeliveries(status: status);
      _isUsingMock = false;
      return list;
    } catch (_) {
      return _local.getDeliveries();
    }
  }

  @override
  Future<DeliveryCapacityEntity> getDeliveryCapacity(String date) async {
    try {
      return await _remote.getDeliveryCapacity(date);
    } catch (_) {
      return DeliveryCapacityModel(
        date: date,
        scheduledCount: 1,
        maxPerDay: 5,
        remainingSlots: 4,
        available: true,
      );
    }
  }

  @override
  Future<DeliveryEntity> scheduleDelivery({
    required String orderId,
    required String scheduledDate,
    required String timeSlot,
    required String address,
    String? notes,
    String deliveryType = 'DELIVERY',
    double? latitude,
    double? longitude,
  }) async {
    try {
      return await _remote.scheduleDelivery({
        'orderId': orderId,
        'scheduledDate': scheduledDate,
        'timeSlot': timeSlot,
        'address': address,
        'notes': ?notes,
        'deliveryType': deliveryType,
        'latitude': ?latitude,
        'longitude': ?longitude,
      });
    } catch (_) {
      final del = DeliveryModel(
        id: 'DEL-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
        orderId: orderId,
        scheduledDate: scheduledDate,
        timeSlot: timeSlot,
        address: address,
        status: 'SCHEDULED',
        notes: notes ?? '',
        deliveryType: deliveryType,
        latitude: latitude,
        longitude: longitude,
      );
      return _local.addOrUpdateDelivery(del);
    }
  }

  @override
  Future<DeliveryEntity> updateDeliveryStatus(String id, String status) async {
    try {
      return await _remote.updateDeliveryStatus(id, status);
    } catch (_) {
      final existing = _local.getDeliveries().firstWhere((d) => d.id == id);
      final updated = DeliveryModel(
        id: existing.id,
        orderId: existing.orderId,
        scheduledDate: existing.scheduledDate,
        timeSlot: existing.timeSlot,
        address: existing.address,
        status: status.toUpperCase(),
        notes: existing.notes,
        deliveryType: existing.deliveryType,
        latitude: existing.latitude,
        longitude: existing.longitude,
      );
      return _local.addOrUpdateDelivery(updated);
    }
  }

  @override
  Future<DeliveryEntity> rescheduleDelivery({
    required String id,
    required String newDate,
    String? timeSlot,
  }) async {
    try {
      return await _remote.rescheduleDelivery(
        id: id,
        newDate: newDate,
        timeSlot: timeSlot,
      );
    } catch (_) {
      final existing = _local.getDeliveries().firstWhere((d) => d.id == id);
      final updated = DeliveryModel(
        id: existing.id,
        orderId: existing.orderId,
        scheduledDate: newDate,
        timeSlot: timeSlot ?? existing.timeSlot,
        address: existing.address,
        status: 'RESCHEDULED',
        notes: existing.notes,
        deliveryType: existing.deliveryType,
        latitude: existing.latitude,
        longitude: existing.longitude,
      );
      return _local.addOrUpdateDelivery(updated);
    }
  }

  // ── CU5: Facturas y Recibos PDF ─────────────────────────────────────────────

  @override
  Future<List<InvoiceEntity>> getInvoices({String? clientEmail}) async {
    try {
      final list = await _remote.getInvoices(clientEmail: clientEmail);
      _isUsingMock = false;
      return list;
    } catch (_) {
      return _local.getInvoices(clientEmail: clientEmail);
    }
  }

  @override
  Future<InvoiceEntity> createInvoice({
    required String clientName,
    required String clientNit,
    String? clientEmail,
    String? orderId,
    String? paymentId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final created = await _remote.createInvoice({
        'client_name': clientName,
        'client_nit': clientNit,
        if (clientEmail != null && clientEmail.isNotEmpty)
          'client_email': clientEmail,
        if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
        if (paymentId != null && paymentId.isNotEmpty) 'payment_id': paymentId,
        'items': items,
      });
      _isUsingMock = false;
      return created;
    } catch (_) {
      double total = 0;
      final parsedItems = <InvoiceItemModel>[];
      for (final item in items) {
        final q = int.tryParse((item['quantity'] ?? 1).toString()) ?? 1;
        final u =
            double.tryParse((item['unit_price'] ?? 0).toString()) ?? 0.0;
        total += q * u;
        parsedItems.add(
          InvoiceItemModel(
            description: (item['description'] ?? 'Mueble').toString(),
            quantity: q,
            unitPrice: u,
            lineTotal: q * u,
          ),
        );
      }
      final inv = InvoiceModel(
        id: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        number: '000${105 + _local.getInvoices().length}',
        series: 'A',
        clientName: clientName,
        clientNit: clientNit,
        clientEmail: clientEmail ?? '',
        orderId: orderId,
        paymentId: paymentId,
        subtotal: (total * 0.87).roundToDouble(),
        tax: (total * 0.13).roundToDouble(),
        total: total,
        status: 'PAID',
        issuedAt: DateTime.now().toIso8601String().substring(0, 16),
        items: parsedItems,
      );
      return _local.addInvoice(inv);
    }
  }

  @override
  Future<Uint8List> downloadInvoicePdf(String invoiceId) async {
    try {
      return await _remote.downloadInvoicePdf(invoiceId);
    } catch (_) {
      // Fallback: genera el recibo PDF localmente con el paquete `pdf`
      final inv = _local.getInvoices().firstWhere(
            (i) => i.id == invoiceId,
            orElse: () => _local.getInvoices().first,
          );
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RECIBO / FACTURA OFICIAL — CARPINTERÍA SW2',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Factura N°: ${inv.series}-${inv.number}'),
                pw.Text('Fecha de emisión: ${inv.issuedAt}'),
                pw.Text('Cliente: ${inv.clientName} (NIT/CI: ${inv.clientNit})'),
                if (inv.clientEmail.isNotEmpty)
                  pw.Text('Correo: ${inv.clientEmail}'),
                pw.Divider(height: 24),
                ...inv.items.map(
                  (it) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text('${it.quantity}x ${it.description}'),
                        ),
                        pw.Text('Bs ${it.lineTotal.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
                pw.Divider(height: 24),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Subtotal: Bs ${inv.subtotal.toStringAsFixed(2)}'),
                      pw.Text('IVA (13%): Bs ${inv.tax.toStringAsFixed(2)}'),
                      pw.Text(
                        'TOTAL PAGADO: Bs ${inv.total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return doc.save();
    }
  }

  // ── CU6: Pagos y Auditoría DynamoDB ─────────────────────────────────────────

  @override
  Future<PaymentResultEntity> processPayment({
    required String quotationId,
    required double amount,
    required String cardNumber,
    required String cardHolder,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
  }) async {
    try {
      final res = await _remote.processPayment({
        'quotationId': quotationId,
        'amount': amount,
        'cardNumber': cardNumber,
        'cardHolder': cardHolder,
        'expiryMonth': expiryMonth,
        'expiryYear': expiryYear,
        'cvv': cvv,
      });
      _isUsingMock = false;
      return res;
    } catch (_) {
      final cleanCard = cardNumber.replaceAll(' ', '');
      final last4 = cleanCard.length >= 4
          ? cleanCard.substring(cleanCard.length - 4)
          : '4242';
      final payId =
          'PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      return PaymentResultModel(
        id: payId,
        quotationId: quotationId,
        amount: amount,
        currency: 'BOB',
        status: 'CAPTURED',
        cardLast4: last4,
        gatewayTransactionId: 'TXN-$nowMs',
        logs: [
          PaymentLogModel(
            paymentId: payId,
            timestamp: nowMs - 800,
            stage: 'INITIATED',
            detail: {'quotationId': quotationId, 'amount': amount},
          ),
          PaymentLogModel(
            paymentId: payId,
            timestamp: nowMs - 300,
            stage: 'AUTHORIZED',
            detail: {'cardLast4': last4, 'holder': cardHolder},
          ),
          PaymentLogModel(
            paymentId: payId,
            timestamp: nowMs,
            stage: 'CAPTURED',
            detail: {'status': 'CAPTURED', 'invoiceIssued': true},
          ),
        ],
      );
    }
  }

  @override
  Future<List<PaymentLogEntity>> getPaymentLogs(String paymentId) async {
    try {
      return await _remote.getPaymentLogs(paymentId);
    } catch (_) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      return [
        PaymentLogModel(
          paymentId: paymentId,
          timestamp: nowMs - 500,
          stage: 'AUTHORIZED',
          detail: const {'gateway': 'NestJS PaymentService'},
        ),
        PaymentLogModel(
          paymentId: paymentId,
          timestamp: nowMs,
          stage: 'CAPTURED',
          detail: const {'dynamoDbTable': 'PaymentLogs'},
        ),
      ];
    }
  }

  // ── CU7: Agente IA Online & Reportes NL Online ──────────────────────────────

  @override
  Future<OnlineAgentReplyEntity> askOnlineAgent({
    required String query,
    String? sessionId,
  }) async {
    final res = await _remote.askOnlineAgent(
      query: query,
      sessionId: sessionId,
    );
    _isUsingMock = false;
    return res;
  }

  @override
  Future<OnlineNlReportEntity> generateOnlineReport(String query) async {
    final res = await _remote.generateOnlineReport(query);
    _isUsingMock = false;
    return res;
  }
}
