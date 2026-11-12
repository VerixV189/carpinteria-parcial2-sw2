import 'dart:convert';
import 'package:carpinteria_movil_sw2/domain/entities/entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    super.role,
    super.token,
  });

  static Map<String, dynamic> _decodeJwtPayload(String? jwt) {
    if (jwt == null || !jwt.contains('.')) return const {};
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return const {};
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded);
      if (map is Map<String, dynamic>) return map;
    } catch (_) {}
    return const {};
  }

  factory UserModel.fromJson(Map<String, dynamic> json, {String? tokenOverride}) {
    final userObj = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;
    final resolvedToken = tokenOverride ??
        (json['accessToken'] ??
                json['token'] ??
                json['access_token'] ??
                userObj['accessToken'] ??
                userObj['token'])
            ?.toString();
    final jwtClaims = _decodeJwtPayload(resolvedToken);

    final resolvedEmail = (userObj['email'] ??
            userObj['correo'] ??
            jwtClaims['email'] ??
            '')
        .toString();
    final rawRole = (userObj['role'] ??
            userObj['rol'] ??
            jwtClaims['role'] ??
            'CLIENT')
        .toString();
    final fallbackName = resolvedEmail.isNotEmpty
        ? resolvedEmail.split('@').first
        : 'Usuario Carpintería';

    return UserModel(
      id: (userObj['id'] ?? userObj['_id'] ?? jwtClaims['sub'] ?? '1').toString(),
      name: (userObj['name'] ?? userObj['nombre'] ?? fallbackName).toString(),
      email: resolvedEmail,
      phone: (userObj['phone'] ?? userObj['telefono'] ?? '').toString(),
      role: rawRole,
      token: resolvedToken,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nombre': name,
      'email': email,
      'phone': phone,
      'telefono': phone,
      'role': role,
      'rol': role,
      if (token != null) 'accessToken': token,
      if (token != null) 'token': token,
    };
  }
}

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.category,
    required super.woodType,
    required super.dimensions,
    required super.price,
    required super.estimatedDays,
    required super.stock,
    required super.description,
    super.iconName,
    super.imageUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['nombre'] ?? json['name'] ?? '').toString(),
      category: (json['categoria'] ?? json['category'] ?? 'General').toString(),
      woodType: (json['tipo_madera'] ?? json['woodType'] ?? json['wood'] ?? 'Roble').toString(),
      dimensions: (json['dimensiones'] ?? json['dimensions'] ?? 'Estándar').toString(),
      price: double.tryParse((json['precio'] ?? json['price'] ?? 0).toString()) ?? 0.0,
      estimatedDays:
          int.tryParse((json['dias_estimados'] ?? json['estimatedDays'] ?? 7).toString()) ?? 7,
      stock: int.tryParse((json['stock'] ?? 5).toString()) ?? 5,
      description: (json['descripcion'] ?? json['description'] ?? '').toString(),
      iconName: (json['iconName'] ?? json['icono'] ?? 'chair').toString(),
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': name,
        'categoria': category,
        'tipo_madera': woodType,
        'dimensiones': dimensions,
        'precio': price,
        'dias_estimados': estimatedDays,
        'stock': stock,
        'descripcion': description,
        'icono': iconName,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}

class ClientProfileModel extends ClientProfileEntity {
  const ClientProfileModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.address,
    super.segment,
  });

  factory ClientProfileModel.fromJson(Map<String, dynamic> json) {
    return ClientProfileModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['nombre'] ?? 'Cliente').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? json['telefono'] ?? '').toString(),
      address: (json['address'] ?? json['direccion'] ?? '').toString(),
      segment: (json['segment'] ?? 'REGULAR').toString(),
    );
  }
}

class ClientClusterModel extends ClientClusterEntity {
  const ClientClusterModel({
    required super.clusterId,
    required super.label,
    required super.size,
    super.clientIds,
    super.centroid,
  });

  factory ClientClusterModel.fromJson(Map<String, dynamic> json) {
    final idsRaw = json['clientIds'] ?? json['client_ids'] ?? [];
    final ids = idsRaw is List ? idsRaw.map((e) => e.toString()).toList() : <String>[];
    final cent = json['centroid'] is Map<String, dynamic>
        ? json['centroid'] as Map<String, dynamic>
        : <String, dynamic>{};
    return ClientClusterModel(
      clusterId: int.tryParse((json['clusterId'] ?? json['cluster_id'] ?? 0).toString()) ?? 0,
      label: (json['label'] ?? 'Cluster').toString(),
      size: int.tryParse((json['size'] ?? ids.length).toString()) ?? ids.length,
      clientIds: ids,
      centroid: cent,
    );
  }
}

class CarpenterModel extends CarpenterEntity {
  const CarpenterModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.specialty,
    super.yearsExperience,
    super.hourlyRate,
    super.active,
  });

  factory CarpenterModel.fromJson(Map<String, dynamic> json) {
    return CarpenterModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['nombre'] ?? 'Carpintero').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? json['telefono'] ?? '').toString(),
      specialty: (json['specialty'] ?? json['especialidad'] ?? 'Muebles a medida').toString(),
      yearsExperience:
          int.tryParse((json['yearsExperience'] ?? json['years_experience'] ?? 3).toString()) ?? 3,
      hourlyRate:
          double.tryParse((json['hourlyRate'] ?? json['hourly_rate'] ?? 45).toString()) ?? 45.0,
      active: json['active'] == null ? true : (json['active'] == true),
    );
  }
}

class ProductionStepModel extends ProductionStepEntity {
  const ProductionStepModel({
    required super.id,
    required super.name,
    required super.status,
    required super.sequence,
  });

  factory ProductionStepModel.fromJson(Map<String, dynamic> json) {
    return ProductionStepModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['nombre'] ?? 'Paso').toString(),
      status: (json['status'] ?? json['estado'] ?? 'PENDING').toString(),
      sequence: int.tryParse((json['sequence'] ?? json['orden'] ?? 1).toString()) ?? 1,
    );
  }
}

class OrderItemDetailModel extends OrderItemDetailEntity {
  const OrderItemDetailModel({
    required super.id,
    required super.furnitureType,
    super.woodType,
    super.dimensions,
    super.quantity,
    super.unitPrice,
  });

  factory OrderItemDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderItemDetailModel(
      id: (json['id'] ?? '').toString(),
      furnitureType: (json['furnitureType'] ?? json['description'] ?? 'Mueble').toString(),
      woodType: (json['woodType'] ?? 'Roble').toString(),
      dimensions: (json['dimensions'] ?? 'Estándar').toString(),
      quantity: int.tryParse((json['quantity'] ?? 1).toString()) ?? 1,
      unitPrice: double.tryParse((json['unitPrice'] ?? json['price'] ?? 0).toString()) ?? 0.0,
    );
  }
}

class DeliveryModel extends DeliveryEntity {
  const DeliveryModel({
    required super.id,
    required super.orderId,
    required super.scheduledDate,
    super.timeSlot,
    super.address,
    super.status,
    super.notes,
    super.deliveryType,
    super.latitude,
    super.longitude,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json, {String? fallbackOrderId}) {
    final orderObj = json['order'] is Map<String, dynamic>
        ? json['order'] as Map<String, dynamic>
        : null;
    return DeliveryModel(
      id: (json['id'] ?? '').toString(),
      orderId: (orderObj?['id'] ?? json['orderId'] ?? fallbackOrderId ?? '').toString(),
      scheduledDate: (json['scheduledDate'] ?? json['date'] ?? '').toString(),
      timeSlot: (json['timeSlot'] ?? 'MORNING').toString(),
      address: (json['address'] ?? '').toString(),
      status: (json['status'] ?? 'SCHEDULED').toString(),
      notes: (json['notes'] ?? '').toString(),
      deliveryType: (json['deliveryType'] ?? 'DELIVERY').toString(),
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }
}

class DeliveryCapacityModel extends DeliveryCapacityEntity {
  const DeliveryCapacityModel({
    required super.date,
    required super.scheduledCount,
    required super.maxPerDay,
    required super.remainingSlots,
    required super.available,
  });

  factory DeliveryCapacityModel.fromJson(Map<String, dynamic> json) {
    final scheduled =
        int.tryParse((json['scheduledCount'] ?? json['scheduled_count'] ?? 0).toString()) ?? 0;
    final maxPerDay =
        int.tryParse((json['maxPerDay'] ?? json['max_per_day'] ?? 5).toString()) ?? 5;
    final remaining = int.tryParse((json['remainingSlots'] ??
                json['remaining_slots'] ??
                (maxPerDay - scheduled))
            .toString()) ??
        (maxPerDay - scheduled);
    return DeliveryCapacityModel(
      date: (json['date'] ?? '').toString(),
      scheduledCount: scheduled,
      maxPerDay: maxPerDay,
      remainingSlots: remaining < 0 ? 0 : remaining,
      available: json['available'] == null ? remaining > 0 : (json['available'] == true),
    );
  }
}

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    super.clientId,
    required super.clientName,
    super.clientEmail,
    super.clientPhone,
    required super.productName,
    required super.woodType,
    required super.specifications,
    required super.totalAmount,
    required super.advancePayment,
    required super.status,
    super.rawStatus,
    required super.deliveryDate,
    required super.createdAt,
    super.quotationId,
    super.deliveryType,
    super.deliveryAddress,
    super.deliveryLat,
    super.deliveryLng,
    super.items,
    super.steps,
    super.carpenters,
    super.delivery,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final clientMap = json['client'] is Map<String, dynamic>
        ? json['client'] as Map<String, dynamic>
        : null;
    final itemsList = (json['items'] is List)
        ? (json['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map(OrderItemDetailModel.fromJson)
            .toList()
        : <OrderItemDetailModel>[];
    final stepsList = (json['steps'] is List)
        ? (json['steps'] as List)
            .whereType<Map<String, dynamic>>()
            .map(ProductionStepModel.fromJson)
            .toList()
        : <ProductionStepModel>[];
    stepsList.sort((a, b) => a.sequence.compareTo(b.sequence));

    final carpentersList = (json['carpenters'] is List)
        ? (json['carpenters'] as List)
            .whereType<Map<String, dynamic>>()
            .map(CarpenterModel.fromJson)
            .toList()
        : <CarpenterModel>[];

    final orderId = (json['id'] ?? json['_id'] ?? '').toString();
    final deliveryObj = json['delivery'] is Map<String, dynamic>
        ? DeliveryModel.fromJson(
            json['delivery'] as Map<String, dynamic>,
            fallbackOrderId: orderId,
          )
        : null;

    final rawStat = (json['status'] ?? json['estado'] ?? 'PENDING').toString();
    final backendStat = OrderEntity.toBackendStatus(rawStat);
    final spanishStat = OrderEntity.toSpanishStatus(rawStat);

    String computedProductName =
        (json['producto_nombre'] ?? json['productName'] ?? '').toString();
    if (computedProductName.isEmpty && itemsList.isNotEmpty) {
      computedProductName = itemsList
          .map((i) => i.quantity > 1 ? '${i.furnitureType} (x${i.quantity})' : i.furnitureType)
          .join(', ');
    }
    if (computedProductName.isEmpty) {
      computedProductName = (json['description'] ?? 'Pedido a medida').toString();
    }

    String computedWood = (json['tipo_madera'] ?? json['woodType'] ?? '').toString();
    if (computedWood.isEmpty && itemsList.isNotEmpty) {
      computedWood = itemsList.map((i) => i.woodType).toSet().join(' / ');
    }
    if (computedWood.isEmpty) computedWood = 'Roble';

    final total =
        double.tryParse((json['totalAmount'] ?? json['monto_total'] ?? 0).toString()) ?? 0.0;
    final advance = double.tryParse((json['advancePayment'] ??
                json['adelanto'] ??
                (backendStat == 'DELIVERED' || backendStat == 'READY' ? total : total * 0.5))
            .toString()) ??
        0.0;

    return OrderModel(
      id: orderId,
      clientId: (clientMap?['id'] ?? json['clientId'] ?? '').toString(),
      clientName:
          (clientMap?['name'] ?? json['cliente_nombre'] ?? json['clientName'] ?? 'Cliente')
              .toString(),
      clientEmail: (clientMap?['email'] ?? json['clientEmail'] ?? '').toString(),
      clientPhone: (clientMap?['phone'] ?? json['clientPhone'] ?? '').toString(),
      productName: computedProductName,
      woodType: computedWood,
      specifications:
          (json['description'] ?? json['especificaciones'] ?? json['specifications'] ?? '')
              .toString(),
      totalAmount: total,
      advancePayment: advance,
      status: spanishStat,
      rawStatus: backendStat,
      deliveryDate: (deliveryObj?.scheduledDate.isNotEmpty == true
              ? deliveryObj!.scheduledDate
              : (json['estimatedDeliveryDate'] ??
                  json['fecha_entrega'] ??
                  json['deliveryDate'] ??
                  ''))
          .toString(),
      createdAt: (json['createdAt'] ?? json['created_at'] ?? 'Hoy').toString(),
      quotationId: json['quotationId']?.toString(),
      deliveryType:
          (json['deliveryType'] ?? deliveryObj?.deliveryType ?? 'DELIVERY').toString(),
      deliveryAddress:
          (json['deliveryAddress'] ?? deliveryObj?.address ?? clientMap?['address'] ?? '')
              .toString(),
      deliveryLat: json['deliveryLat'] != null
          ? double.tryParse(json['deliveryLat'].toString())
          : deliveryObj?.latitude,
      deliveryLng: json['deliveryLng'] != null
          ? double.tryParse(json['deliveryLng'].toString())
          : deliveryObj?.longitude,
      items: itemsList,
      steps: stepsList,
      carpenters: carpentersList,
      delivery: deliveryObj,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'cliente_nombre': clientName,
        'producto_nombre': productName,
        'tipo_madera': woodType,
        'especificaciones': specifications,
        'monto_total': totalAmount,
        'adelanto': advancePayment,
        'estado': status,
        'rawStatus': rawStatus,
        'fecha_entrega': deliveryDate,
        'created_at': createdAt,
      };
}

class AiEstimateModel extends AiEstimateEntity {
  const AiEstimateModel({
    required super.furnitureType,
    required super.confidence,
    required super.estimatedPrice,
    super.currency,
    super.factors,
  });

  factory AiEstimateModel.fromJson(Map<String, dynamic> json) {
    return AiEstimateModel(
      furnitureType:
          (json['furnitureType'] ?? json['furniture_type'] ?? 'Mueble a medida').toString(),
      confidence: double.tryParse((json['confidence'] ?? 0.85).toString()) ?? 0.85,
      estimatedPrice:
          double.tryParse((json['estimatedPrice'] ?? json['estimated_price'] ?? 0).toString()) ??
              0.0,
      currency: (json['currency'] ?? 'BOB').toString(),
      factors: json['factors'] is Map<String, dynamic>
          ? json['factors'] as Map<String, dynamic>
          : <String, dynamic>{},
    );
  }
}

class QuotationModel extends QuotationEntity {
  const QuotationModel({
    required super.id,
    required super.clientId,
    required super.status,
    super.photoUrl,
    required super.description,
    super.woodType,
    required super.totalAmount,
    super.finalAmount,
    super.notes,
    super.clientMessage,
    super.counterAmount,
    super.deliveryType,
    super.deliveryAddress,
    super.deliveryLatitude,
    super.deliveryLongitude,
    super.aiEstimate,
    required super.createdAt,
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    final items = json['items'] is List ? json['items'] as List : const [];
    final firstItem =
        items.isNotEmpty && items.first is Map ? items.first as Map<String, dynamic> : null;
    final aiEst = json['aiEstimate'] is Map<String, dynamic>
        ? AiEstimateModel.fromJson(json['aiEstimate'] as Map<String, dynamic>)
        : null;
    final deliv = json['delivery'] is Map<String, dynamic>
        ? json['delivery'] as Map<String, dynamic>
        : null;

    final desc = (firstItem?['description'] ??
            json['description'] ??
            aiEst?.furnitureType ??
            'Cotización de mueble a medida')
        .toString();
    final wood = (firstItem?['woodType'] ??
            json['woodType'] ??
            aiEst?.factors['woodType'] ??
            'Roble')
        .toString();

    return QuotationModel(
      id: (json['id'] ?? '').toString(),
      clientId: (json['clientId'] ?? json['client_id'] ?? '').toString(),
      status: (json['status'] ?? 'DRAFT').toString(),
      photoUrl: json['photoUrl']?.toString(),
      description: desc,
      woodType: wood,
      totalAmount: double.tryParse((json['totalAmount'] ??
                      json['payableAmount'] ??
                      firstItem?['unitPrice'] ??
                      firstItem?['estimatedPrice'] ??
                      0)
                  .toString()) ??
          0.0,
      finalAmount: json['finalAmount'] != null
          ? double.tryParse(json['finalAmount'].toString())
          : null,
      notes: json['notes']?.toString(),
      clientMessage: json['clientMessage']?.toString(),
      counterAmount: json['counterAmount'] != null
          ? double.tryParse(json['counterAmount'].toString())
          : null,
      deliveryType: (deliv?['type'] ?? json['deliveryType'] ?? 'DELIVERY').toString(),
      deliveryAddress: (deliv?['address'] ?? json['deliveryAddress'] ?? '').toString(),
      deliveryLatitude: (deliv?['lat'] ?? deliv?['latitude']) != null
          ? double.tryParse((deliv?['lat'] ?? deliv?['latitude']).toString())
          : null,
      deliveryLongitude: (deliv?['lng'] ?? deliv?['longitude']) != null
          ? double.tryParse((deliv?['lng'] ?? deliv?['longitude']).toString())
          : null,
      aiEstimate: aiEst,
      createdAt: (json['createdAt'] ?? json['updatedAt'] ?? 'Hoy').toString(),
    );
  }
}

class InvoiceItemModel extends InvoiceItemEntity {
  const InvoiceItemModel({
    required super.description,
    super.quantity,
    required super.unitPrice,
    required super.lineTotal,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    final qty = int.tryParse((json['quantity'] ?? 1).toString()) ?? 1;
    final unit =
        double.tryParse((json['unit_price'] ?? json['unitPrice'] ?? 0).toString()) ?? 0.0;
    final line = double.tryParse(
            (json['line_total'] ?? json['lineTotal'] ?? (qty * unit)).toString()) ??
        (qty * unit);
    return InvoiceItemModel(
      description: (json['description'] ?? 'Mueble').toString(),
      quantity: qty,
      unitPrice: unit,
      lineTotal: line,
    );
  }
}

class InvoiceModel extends InvoiceEntity {
  const InvoiceModel({
    required super.id,
    required super.number,
    super.series,
    required super.clientName,
    super.clientNit,
    super.clientEmail,
    super.orderId,
    super.paymentId,
    required super.subtotal,
    required super.tax,
    required super.total,
    super.status,
    required super.issuedAt,
    super.items,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] is List)
        ? (json['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map(InvoiceItemModel.fromJson)
            .toList()
        : <InvoiceItemModel>[];

    return InvoiceModel(
      id: (json['id'] ?? '').toString(),
      number: (json['number'] ?? 'F-0001').toString(),
      series: (json['series'] ?? 'A').toString(),
      clientName: (json['client_name'] ?? json['clientName'] ?? 'Cliente').toString(),
      clientNit: (json['client_nit'] ?? json['clientNit'] ?? '0').toString(),
      clientEmail: (json['client_email'] ?? json['clientEmail'] ?? '').toString(),
      orderId: json['order_id']?.toString() ?? json['orderId']?.toString(),
      paymentId: json['payment_id']?.toString() ?? json['paymentId']?.toString(),
      subtotal: double.tryParse((json['subtotal'] ?? 0).toString()) ?? 0.0,
      tax: double.tryParse((json['tax'] ?? 0).toString()) ?? 0.0,
      total: double.tryParse((json['total'] ?? 0).toString()) ?? 0.0,
      status: (json['status'] ?? 'PAID').toString(),
      issuedAt: (json['issued_at'] ?? json['issuedAt'] ?? json['created_at'] ?? 'Hoy').toString(),
      items: itemsList,
    );
  }
}

class PaymentLogModel extends PaymentLogEntity {
  const PaymentLogModel({
    required super.paymentId,
    required super.timestamp,
    required super.stage,
    super.detail,
  });

  factory PaymentLogModel.fromJson(Map<String, dynamic> json) {
    return PaymentLogModel(
      paymentId: (json['paymentId'] ?? '').toString(),
      timestamp: int.tryParse((json['timestamp'] ?? 0).toString()) ?? 0,
      stage: (json['stage'] ?? 'PROCESSED').toString(),
      detail: json['detail'] is Map<String, dynamic>
          ? json['detail'] as Map<String, dynamic>
          : <String, dynamic>{},
    );
  }
}

class PaymentResultModel extends PaymentResultEntity {
  const PaymentResultModel({
    required super.id,
    required super.quotationId,
    required super.amount,
    super.currency,
    required super.status,
    super.cardLast4,
    super.gatewayTransactionId,
    super.logs,
  });

  factory PaymentResultModel.fromJson(Map<String, dynamic> json) {
    final logsList = (json['logs'] is List)
        ? (json['logs'] as List)
            .whereType<Map<String, dynamic>>()
            .map(PaymentLogModel.fromJson)
            .toList()
        : <PaymentLogModel>[];

    return PaymentResultModel(
      id: (json['id'] ?? '').toString(),
      quotationId: (json['quotationId'] ?? '').toString(),
      amount: double.tryParse((json['amount'] ?? 0).toString()) ?? 0.0,
      currency: (json['currency'] ?? 'BOB').toString(),
      status: (json['status'] ?? 'CAPTURED').toString(),
      cardLast4: (json['cardLast4'] ?? '4242').toString(),
      gatewayTransactionId: (json['gatewayTransactionId'] ?? '').toString(),
      logs: logsList,
    );
  }
}

class OnlineAgentReplyModel extends OnlineAgentReplyEntity {
  const OnlineAgentReplyModel({
    required super.answer,
    super.tool,
    super.data,
    super.source,
    super.steps,
  });

  factory OnlineAgentReplyModel.fromJson(Map<String, dynamic> json) {
    final stepsRaw = json['steps'] is List ? json['steps'] as List : const [];
    return OnlineAgentReplyModel(
      answer: (json['answer'] ?? 'Sin respuesta del agente.').toString(),
      tool: json['tool']?.toString(),
      data: json['data'],
      source: (json['source'] ?? 'online').toString(),
      steps: stepsRaw.whereType<Map<String, dynamic>>().toList(),
    );
  }
}

class OnlineNlReportModel extends OnlineNlReportEntity {
  const OnlineNlReportModel({
    required super.query,
    required super.sql,
    required super.rows,
    required super.narrative,
    super.source,
  });

  factory OnlineNlReportModel.fromJson(Map<String, dynamic> json) {
    final rowsRaw = json['rows'] is List ? json['rows'] as List : const [];
    final rows = rowsRaw
        .map((r) => r is Map ? Map<String, dynamic>.from(r) : <String, dynamic>{})
        .toList();
    return OnlineNlReportModel(
      query: (json['query'] ?? '').toString(),
      sql: (json['sql'] ?? '').toString(),
      rows: rows,
      narrative: (json['narrative'] ?? '').toString(),
      source: (json['source'] ?? 'postgres').toString(),
    );
  }
}

class WoodMaterialModel extends WoodMaterialEntity {
  const WoodMaterialModel({
    required super.id,
    required super.name,
    required super.type,
    required super.quantity,
    required super.unit,
    required super.minStock,
    required super.costPerUnit,
  });

  factory WoodMaterialModel.fromJson(Map<String, dynamic> json) {
    return WoodMaterialModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['nombre'] ?? json['name'] ?? '').toString(),
      type: (json['tipo'] ?? json['type'] ?? 'Madera Maciza').toString(),
      quantity:
          double.tryParse((json['cantidad'] ?? json['quantity'] ?? 0).toString()) ?? 0.0,
      unit: (json['unidad'] ?? json['unit'] ?? 'pie2').toString(),
      minStock:
          double.tryParse((json['stock_minimo'] ?? json['minStock'] ?? 10).toString()) ??
              10.0,
      costPerUnit:
          double.tryParse((json['costo_unitario'] ?? json['costPerUnit'] ?? 0).toString()) ??
              0.0,
    );
  }
}
