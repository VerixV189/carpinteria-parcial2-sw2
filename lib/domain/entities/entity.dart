class UserEntity {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'cliente' | 'carpintero' | 'admin'
  final String? token;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'carpintero',
    this.token,
  });
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
  });
}

class OrderEntity {
  final String id;
  final String clientName;
  final String productName;
  final String woodType;
  final String specifications;
  final double totalAmount;
  final double advancePayment;
  final String status; // 'Pendiente', 'En fabricación', 'Listo', 'Entregado'
  final String deliveryDate;
  final String createdAt;

  const OrderEntity({
    required this.id,
    required this.clientName,
    required this.productName,
    required this.woodType,
    required this.specifications,
    required this.totalAmount,
    required this.advancePayment,
    required this.status,
    required this.deliveryDate,
    required this.createdAt,
  });
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
