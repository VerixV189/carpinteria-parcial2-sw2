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

  factory UserModel.fromJson(Map<String, dynamic> json, {String? tokenOverride}) {
    final userObj = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;
    return UserModel(
      id: (userObj['id'] ?? userObj['_id'] ?? '1').toString(),
      name: (userObj['nombre'] ?? userObj['name'] ?? 'Usuario Carpintería').toString(),
      email: (userObj['email'] ?? userObj['correo'] ?? '').toString(),
      phone: (userObj['telefono'] ?? userObj['phone'] ?? '').toString(),
      role: (userObj['rol'] ?? userObj['role'] ?? 'carpintero').toString(),
      token: tokenOverride ??
          (json['token'] ?? json['access_token'] ?? userObj['token'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'email': email,
      'telefono': phone,
      'rol': role,
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
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['nombre'] ?? json['name'] ?? '').toString(),
      category: (json['categoria'] ?? json['category'] ?? 'General').toString(),
      woodType: (json['tipo_madera'] ?? json['woodType'] ?? 'Roble').toString(),
      dimensions: (json['dimensiones'] ?? json['dimensions'] ?? 'Estándar').toString(),
      price: double.tryParse((json['precio'] ?? json['price'] ?? 0).toString()) ?? 0.0,
      estimatedDays:
          int.tryParse((json['dias_estimados'] ?? json['estimatedDays'] ?? 7).toString()) ?? 7,
      stock: int.tryParse((json['stock'] ?? 1).toString()) ?? 1,
      description: (json['descripcion'] ?? json['description'] ?? '').toString(),
      iconName: (json['iconName'] ?? json['icono'] ?? 'chair').toString(),
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
      };
}

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.clientName,
    required super.productName,
    required super.woodType,
    required super.specifications,
    required super.totalAmount,
    required super.advancePayment,
    required super.status,
    required super.deliveryDate,
    required super.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      clientName: (json['cliente_nombre'] ?? json['clientName'] ?? 'Cliente').toString(),
      productName: (json['producto_nombre'] ?? json['productName'] ?? '').toString(),
      woodType: (json['tipo_madera'] ?? json['woodType'] ?? 'Roble').toString(),
      specifications:
          (json['especificaciones'] ?? json['specifications'] ?? '').toString(),
      totalAmount:
          double.tryParse((json['monto_total'] ?? json['totalAmount'] ?? 0).toString()) ??
              0.0,
      advancePayment:
          double.tryParse((json['adelanto'] ?? json['advancePayment'] ?? 0).toString()) ??
              0.0,
      status: (json['estado'] ?? json['status'] ?? 'Pendiente').toString(),
      deliveryDate: (json['fecha_entrega'] ?? json['deliveryDate'] ?? '').toString(),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? 'Hoy').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cliente_nombre': clientName,
        'producto_nombre': productName,
        'tipo_madera': woodType,
        'especificaciones': specifications,
        'monto_total': totalAmount,
        'adelanto': advancePayment,
        'estado': status,
        'fecha_entrega': deliveryDate,
        'created_at': createdAt,
      };
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
