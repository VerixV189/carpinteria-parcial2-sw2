class UserEntity {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'CLIENT' | 'CARPENTER' | 'ADMIN' | 'cliente' | 'carpintero' | 'admin'
  final String? token;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'CARPENTER',
    this.token,
  });

  String get normalizedRole {
    final r = role.trim().toUpperCase();
    if (r == 'CLIENT' || r == 'CLIENTE') return 'CLIENT';
    if (r == 'ADMIN' || r == 'ADMINISTRADOR') return 'ADMIN';
    return 'CARPENTER';
  }

  bool get isClient => normalizedRole == 'CLIENT';
  bool get isAdmin => normalizedRole == 'ADMIN';
  bool get isCarpenter => normalizedRole == 'CARPENTER';
}

class ProductEntity {
  final String id;
  final String name;
  final String category; // 'Mesas', 'Sillas', 'Puertas', 'Roperos', 'Cocina'
  final String woodType; // 'Roble', 'Cedro', 'Mara', 'Pino', 'Melamina'
  final String dimensions;
  final double price;
  final int estimatedDays;
  final int stock;
  final String description;
  final String iconName;
  final String? imageUrl;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.woodType,
    required this.dimensions,
    required this.price,
    required this.estimatedDays,
    required this.stock,
    required this.description,
    this.iconName = 'chair',
    this.imageUrl,
  });
}

// ── Clientes y Segmentación ──────────────────────────────────────────────────

class ClientProfileEntity {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String segment; // 'REGULAR', 'VIP', 'WHOLESALE'

  const ClientProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.address = '',
    this.segment = 'REGULAR',
  });
}

class ClientClusterEntity {
  final int clusterId;
  final String label;
  final int size;
  final List<String> clientIds;
  final Map<String, dynamic> centroid;

  const ClientClusterEntity({
    required this.clusterId,
    required this.label,
    required this.size,
    this.clientIds = const [],
    this.centroid = const {},
  });
}

// ── Carpinteros y Pasos de Producción ────────────────────────────────────────

class CarpenterEntity {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String specialty;
  final int yearsExperience;
  final double hourlyRate;
  final bool active;

  const CarpenterEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.specialty = 'Muebles a medida',
    this.yearsExperience = 3,
    this.hourlyRate = 45.0,
    this.active = true,
  });
}

class ProductionStepEntity {
  final String id;
  final String name;
  final String status; // 'PENDING', 'IN_PROGRESS', 'COMPLETED'
  final int sequence;

  const ProductionStepEntity({
    required this.id,
    required this.name,
    required this.status,
    required this.sequence,
  });

  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
  bool get isInProgress => status.toUpperCase() == 'IN_PROGRESS';
}

// ── Pedidos y Entregas ───────────────────────────────────────────────────────

class OrderItemDetailEntity {
  final String id;
  final String furnitureType;
  final String woodType;
  final String dimensions;
  final int quantity;
  final double unitPrice;

  const OrderItemDetailEntity({
    required this.id,
    required this.furnitureType,
    this.woodType = 'Roble',
    this.dimensions = 'Estándar',
    this.quantity = 1,
    this.unitPrice = 0.0,
  });
}

class DeliveryEntity {
  final String id;
  final String orderId;
  final String scheduledDate;
  final String timeSlot; // 'MORNING', 'AFTERNOON', 'EVENING'
  final String address;
  final String status; // 'SCHEDULED', 'IN_TRANSIT', 'DELIVERED', 'FAILED', 'RESCHEDULED'
  final String notes;
  final String deliveryType; // 'PICKUP' | 'DELIVERY'
  final double? latitude;
  final double? longitude;

  const DeliveryEntity({
    required this.id,
    required this.orderId,
    required this.scheduledDate,
    this.timeSlot = 'MORNING',
    this.address = '',
    this.status = 'SCHEDULED',
    this.notes = '',
    this.deliveryType = 'DELIVERY',
    this.latitude,
    this.longitude,
  });

  bool get isPickup => deliveryType.toUpperCase() == 'PICKUP';

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'SCHEDULED':
        return 'Programada';
      case 'IN_TRANSIT':
        return 'En camino';
      case 'DELIVERED':
        return 'Entregada';
      case 'FAILED':
        return 'Fallida';
      case 'RESCHEDULED':
        return 'Reprogramada';
      default:
        return status;
    }
  }

  String get timeSlotLabel {
    switch (timeSlot.toUpperCase()) {
      case 'MORNING':
        return 'Mañana (08:00-12:00)';
      case 'AFTERNOON':
        return 'Tarde (14:00-18:00)';
      case 'EVENING':
        return 'Noche (18:00-20:00)';
      default:
        return timeSlot;
    }
  }
}

class DeliveryCapacityEntity {
  final String date;
  final int scheduledCount;
  final int maxPerDay;
  final int remainingSlots;
  final bool available;

  const DeliveryCapacityEntity({
    required this.date,
    required this.scheduledCount,
    required this.maxPerDay,
    required this.remainingSlots,
    required this.available,
  });
}

class OrderEntity {
  final String id;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String productName;
  final String woodType;
  final String specifications;
  final double totalAmount;
  final double advancePayment;
  final String status; // 'Pendiente', 'Aprobado', 'En fabricación', 'Listo', 'Entregado', 'Cancelado'
  final String rawStatus; // 'PENDING', 'APPROVED', 'IN_PRODUCTION', 'READY', 'DELIVERED', 'CANCELLED'
  final String deliveryDate;
  final String createdAt;
  final String? quotationId;
  final String deliveryType; // 'DELIVERY' | 'PICKUP'
  final String deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final List<OrderItemDetailEntity> items;
  final List<ProductionStepEntity> steps;
  final List<CarpenterEntity> carpenters;
  final DeliveryEntity? delivery;

  const OrderEntity({
    required this.id,
    this.clientId = '',
    required this.clientName,
    this.clientEmail = '',
    this.clientPhone = '',
    required this.productName,
    required this.woodType,
    required this.specifications,
    required this.totalAmount,
    required this.advancePayment,
    required this.status,
    String? rawStatus,
    required this.deliveryDate,
    required this.createdAt,
    this.quotationId,
    this.deliveryType = 'DELIVERY',
    this.deliveryAddress = '',
    this.deliveryLat,
    this.deliveryLng,
    this.items = const [],
    this.steps = const [],
    this.carpenters = const [],
    this.delivery,
  }) : rawStatus = rawStatus ?? 'PENDING';

  int get completedStepsCount =>
      steps.where((s) => s.status.toUpperCase() == 'COMPLETED').length;

  double get stepsProgress =>
      steps.isEmpty ? 0.0 : completedStepsCount / steps.length;

  static String toSpanishStatus(String raw) {
    final upper = raw.trim().toUpperCase();
    switch (upper) {
      case 'PENDING':
      case 'PENDIENTE':
        return 'Pendiente';
      case 'APPROVED':
      case 'APROBADO':
        return 'Aprobado';
      case 'IN_PRODUCTION':
      case 'EN FABRICACIÓN':
      case 'EN FABRICACION':
        return 'En fabricación';
      case 'READY':
      case 'LISTO':
        return 'Listo';
      case 'DELIVERED':
      case 'ENTREGADO':
        return 'Entregado';
      case 'CANCELLED':
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return raw;
    }
  }

  static String toBackendStatus(String status) {
    final lower = status.trim().toLowerCase();
    if (lower == 'pendiente' || lower == 'pending') return 'PENDING';
    if (lower == 'aprobado' || lower == 'approved') return 'APPROVED';
    if (lower.contains('fabricaci') || lower == 'in_production') {
      return 'IN_PRODUCTION';
    }
    if (lower == 'listo' || lower == 'ready') return 'READY';
    if (lower == 'entregado' || lower == 'delivered') return 'DELIVERED';
    if (lower == 'cancelado' || lower == 'cancelled') return 'CANCELLED';
    return status.toUpperCase();
  }
}

// ── Cotizaciones y Negociación ───────────────────────────────────────────────

class AiEstimateEntity {
  final String furnitureType;
  final double confidence;
  final double estimatedPrice;
  final String currency;
  final Map<String, dynamic> factors;

  const AiEstimateEntity({
    required this.furnitureType,
    required this.confidence,
    required this.estimatedPrice,
    this.currency = 'BOB',
    this.factors = const {},
  });
}

class QuotationEntity {
  final String id;
  final String clientId;
  final String status; // 'DRAFT', 'QUOTED', 'APPROVED', 'REJECTED', 'CONVERTED'
  final String? photoUrl;
  final String description;
  final String woodType;
  final double totalAmount;
  final double? finalAmount;
  final String? notes;
  final String? clientMessage;
  final double? counterAmount;
  final String deliveryType; // 'PICKUP' | 'DELIVERY'
  final String deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final AiEstimateEntity? aiEstimate;
  final String createdAt;

  const QuotationEntity({
    required this.id,
    required this.clientId,
    required this.status,
    this.photoUrl,
    required this.description,
    this.woodType = 'Roble',
    required this.totalAmount,
    this.finalAmount,
    this.notes,
    this.clientMessage,
    this.counterAmount,
    this.deliveryType = 'DELIVERY',
    this.deliveryAddress = '',
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.aiEstimate,
    required this.createdAt,
  });

  bool get hasAdminOffer => finalAmount != null && finalAmount! > 0;

  bool get hasClientCounter =>
      (counterAmount != null && counterAmount! > 0) ||
      (clientMessage != null && clientMessage!.trim().isNotEmpty);

  double get payableAmount {
    final st = status.toUpperCase();
    if (st == 'QUOTED' && finalAmount != null && finalAmount! > 0) {
      return finalAmount!;
    }
    if (st == 'DRAFT' && counterAmount != null && counterAmount! > 0) {
      return counterAmount!;
    }
    if (finalAmount != null && finalAmount! > 0) {
      return finalAmount!;
    }
    if (counterAmount != null && counterAmount! > 0) {
      return counterAmount!;
    }
    return totalAmount;
  }

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return hasClientCounter
            ? 'Contraoferta enviada'
            : 'En revisión del taller';
      case 'QUOTED':
        return hasClientCounter
            ? 'Contraoferta del Taller'
            : 'Oferta del Taller';
      case 'APPROVED':
        return 'Aprobada';
      case 'REJECTED':
        return 'Rechazada';
      case 'CONVERTED':
        return 'Pagada / En taller';
      default:
        return status;
    }
  }
}

// ── Facturas y Recibos PDF ───────────────────────────────────────────────────

class InvoiceItemEntity {
  final String description;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  const InvoiceItemEntity({
    required this.description,
    this.quantity = 1,
    required this.unitPrice,
    required this.lineTotal,
  });
}

class InvoiceEntity {
  final String id;
  final String number;
  final String series;
  final String clientName;
  final String clientNit;
  final String clientEmail;
  final String? orderId;
  final String? paymentId;
  final double subtotal;
  final double tax;
  final double total;
  final String status; // 'ISSUED', 'PAID', 'CANCELLED'
  final String issuedAt;
  final List<InvoiceItemEntity> items;

  const InvoiceEntity({
    required this.id,
    required this.number,
    this.series = 'A',
    required this.clientName,
    this.clientNit = '0',
    this.clientEmail = '',
    this.orderId,
    this.paymentId,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.status = 'PAID',
    required this.issuedAt,
    this.items = const [],
  });
}

// ── Pagos y Registro de Transacciones ────────────────────────────────────────

class PaymentLogEntity {
  final String paymentId;
  final int timestamp;
  final String stage;
  final Map<String, dynamic> detail;

  const PaymentLogEntity({
    required this.paymentId,
    required this.timestamp,
    required this.stage,
    this.detail = const {},
  });
}

class PaymentResultEntity {
  final String id;
  final String quotationId;
  final double amount;
  final String currency;
  final String status; // 'CAPTURED', 'FAILED', 'PENDING'
  final String cardLast4;
  final String gatewayTransactionId;
  final List<PaymentLogEntity> logs;

  const PaymentResultEntity({
    required this.id,
    required this.quotationId,
    required this.amount,
    this.currency = 'BOB',
    required this.status,
    this.cardLast4 = '4242',
    this.gatewayTransactionId = '',
    this.logs = const [],
  });
}

// ── Asistente Inteligente y Reportes ─────────────────────────────────────────

class OnlineAgentReplyEntity {
  final String answer;
  final String? tool;
  final dynamic data;
  final String source;
  final List<Map<String, dynamic>> steps;

  const OnlineAgentReplyEntity({
    required this.answer,
    this.tool,
    this.data,
    this.source = 'online',
    this.steps = const [],
  });
}

class OnlineNlReportEntity {
  final String query;
  final String sql;
  final List<Map<String, dynamic>> rows;
  final String narrative;
  final String source;

  const OnlineNlReportEntity({
    required this.query,
    required this.sql,
    required this.rows,
    required this.narrative,
    this.source = 'postgres',
  });
}

// ── Notificaciones en Tiempo Real ────────────────────────────────────────────

class AppNotificationEntity {
  final String id;
  final String title;
  final String body;
  final String? orderId;
  final String? status;
  final DateTime timestamp;
  final bool read;

  const AppNotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    this.orderId,
    this.status,
    required this.timestamp,
    this.read = false,
  });

  AppNotificationEntity copyWith({bool? read}) {
    return AppNotificationEntity(
      id: id,
      title: title,
      body: body,
      orderId: orderId,
      status: status,
      timestamp: timestamp,
      read: read ?? this.read,
    );
  }
}

class WoodMaterialEntity {
  final String id;
  final String name;
  final String type; // 'Madera Maciza', 'Tablero', 'Acabado/Barniz', 'Herraje'
  final double quantity;
  final String unit; // 'pie2', 'planchas', 'litros', 'unidades'
  final double minStock;
  final double costPerUnit;

  const WoodMaterialEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.quantity,
    required this.unit,
    required this.minStock,
    required this.costPerUnit,
  });

  bool get isLowStock => quantity <= minStock;
}

class CartItemEntity {
  final ProductEntity product;
  final int quantity;

  const CartItemEntity({
    required this.product,
    this.quantity = 1,
  });

  double get subtotal => product.price * quantity;

  CartItemEntity copyWith({int? quantity}) {
    return CartItemEntity(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }
}
