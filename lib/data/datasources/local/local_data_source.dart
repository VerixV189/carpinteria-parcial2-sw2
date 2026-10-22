import 'package:carpinteria_movil_sw2/core/errors/app_exception.dart';
import 'package:carpinteria_movil_sw2/core/storage/local_storage.dart';
import 'package:carpinteria_movil_sw2/data/models/model.dart';

class LocalDataSource {
  static final List<ProductModel> _mockProducts = [
    const ProductModel(
      id: 'P-001',
      name: 'Mesa de Comedor Imperial (8 Personas)',
      category: 'Mesas',
      woodType: 'Roble Macizo',
      dimensions: '240 x 110 x 78 cm',
      price: 3450.0,
      estimatedDays: 12,
      stock: 3,
      description:
          'Mesa de comedor principal trabajada en madera roble estacionada, acabado en poliuretano mate resistente a humedad y calor.',
      iconName: 'table_restaurant',
    ),
    const ProductModel(
      id: 'P-002',
      name: 'Juego de 6 Sillas Ergonómicas Talladas',
      category: 'Sillas',
      woodType: 'Cedro Seleccionado',
      dimensions: '48 x 52 x 98 cm c/u',
      price: 2100.0,
      estimatedDays: 10,
      stock: 5,
      description:
          'Sillas reforzadas con espiga y caja, tapizado en lino antimanchas de alta densidad y barnizado natural en cedro.',
      iconName: 'chair',
    ),
    const ProductModel(
      id: 'P-003',
      name: 'Ropero Empotrado 4 Puertas Corredizas',
      category: 'Roperos',
      woodType: 'Mara / Melamina Texturizada',
      dimensions: '260 x 65 x 240 cm',
      price: 4800.0,
      estimatedDays: 15,
      stock: 2,
      description:
          'Ropero piso a techo con rieles telescópicos de cierre suave, cajonera interna, maletero superior y zapatera extraíble.',
      iconName: 'door_sliding',
    ),
    const ProductModel(
      id: 'P-004',
      name: 'Puerta Principal Tablero Rebajado',
      category: 'Puertas',
      woodType: 'Tajibo / Roble',
      dimensions: '95 x 215 x 4.5 cm',
      price: 1950.0,
      estimatedDays: 8,
      stock: 6,
      description:
          'Puerta maciza para exterior con marco cajón, tratamiento antilluvia, filtro UV y preparación para chapa de seguridad.',
      iconName: 'door_front_door',
    ),
    const ProductModel(
      id: 'P-005',
      name: 'Mueble de Cocina Modular Alto y Bajo',
      category: 'Cocina',
      woodType: 'Melamina RH Hidrófuga 18mm',
      dimensions: '320 cm lineales',
      price: 5600.0,
      estimatedDays: 18,
      stock: 1,
      description:
          'Módulos de cocina resistentes a humedad con bisagras cierre lento, pistones a gas y división de cubiertos.',
      iconName: 'countertops',
    ),
    const ProductModel(
      id: 'P-006',
      name: 'Escritorio Ejecutivo en L con Cajonera',
      category: 'Mesas',
      woodType: 'Cedro y Pino Oregón',
      dimensions: '180 x 150 x 76 cm',
      price: 2350.0,
      estimatedDays: 9,
      stock: 4,
      description:
          'Escritorio gerencial con pasacables oculto, 3 gavetas con llave y acabado satinado de alta durabilidad.',
      iconName: 'desk',
    ),
  ];

  static final List<OrderModel> _mockOrders = [
    const OrderModel(
      id: 'PED-106',
      clientName: 'Carlos Mendoza',
      productName: 'Mesa de Comedor Imperial (8 Personas)',
      woodType: 'Roble Macizo',
      specifications: 'Acabado mate natural, entrega en domicilio.',
      totalAmount: 3450.0,
      advancePayment: 1725.0,
      status: 'En fabricación',
      deliveryDate: '29/10/2026',
      createdAt: '19/10/2026',
    ),
    const OrderModel(
      id: 'COT-107',
      clientName: 'Carlos Mendoza',
      productName: 'Cotización: Ropero a Medida 3 Puertas',
      woodType: 'Cedro Seleccionado',
      specifications: 'Medidas especiales 220x60x230 cm con espejo interior.',
      totalAmount: 4200.0,
      advancePayment: 0.0,
      status: 'Pendiente',
      deliveryDate: '08/11/2026',
      createdAt: '20/10/2026',
    ),
    const OrderModel(
      id: 'PED-104',
      clientName: 'Arq. Roberto Méndez',
      productName: 'Puerta Principal Tablero Rebajado (x2)',
      woodType: 'Roble Macizo',
      specifications: 'Tono nogal oscuro, incluye marco de 15 cm y colocación en obra.',
      totalAmount: 3900.0,
      advancePayment: 2000.0,
      status: 'En fabricación',
      deliveryDate: '28/10/2026',
      createdAt: '15/10/2026',
    ),
    const OrderModel(
      id: 'PED-105',
      clientName: 'Familia Vargas',
      productName: 'Ropero Empotrado 4 Puertas Corredizas',
      woodType: 'Cedro Seleccionado',
      specifications: 'Con espejo central de cuerpo entero e iluminación LED interior.',
      totalAmount: 5100.0,
      advancePayment: 2500.0,
      status: 'Pendiente',
      deliveryDate: '04/11/2026',
      createdAt: '18/10/2026',
    ),
    const OrderModel(
      id: 'PED-102',
      clientName: 'Restaurante El Fogón',
      productName: '8 Mesas rústicas + 32 Sillas reforzadas',
      woodType: 'Tajibo y Roble',
      specifications: 'Barniz marino de alto tráfico resistente a líquidos.',
      totalAmount: 14800.0,
      advancePayment: 14800.0,
      status: 'Listo',
      deliveryDate: '21/10/2026',
      createdAt: '02/10/2026',
    ),
  ];

  static final List<WoodMaterialModel> _mockMaterials = [
    const WoodMaterialModel(
      id: 'MAT-01',
      name: 'Madera Roble Secado al Horno (2")',
      type: 'Madera Maciza',
      quantity: 340,
      unit: 'pie²',
      minStock: 150,
      costPerUnit: 24.5,
    ),
    const WoodMaterialModel(
      id: 'MAT-02',
      name: 'Madera Cedro de Primera (1.5")',
      type: 'Madera Maciza',
      quantity: 95,
      unit: 'pie²',
      minStock: 120,
      costPerUnit: 28.0,
    ),
    const WoodMaterialModel(
      id: 'MAT-03',
      name: 'Plancha Melamina Roble Dakar 18mm',
      type: 'Tablero',
      quantity: 14,
      unit: 'planchas',
      minStock: 6,
      costPerUnit: 310.0,
    ),
    const WoodMaterialModel(
      id: 'MAT-04',
      name: 'Barniz Poliuretano Mate Bicomponente',
      type: 'Acabado/Barniz',
      quantity: 4,
      unit: 'galones',
      minStock: 5,
      costPerUnit: 185.0,
    ),
    const WoodMaterialModel(
      id: 'MAT-05',
      name: 'Rieles Telescópicos Cierre Suave 45cm',
      type: 'Herraje',
      quantity: 28,
      unit: 'pares',
      minStock: 10,
      costPerUnit: 32.0,
    ),
    const WoodMaterialModel(
      id: 'MAT-06',
      name: 'Cola Sintética Carpintero Extra Fuerte',
      type: 'Acabado/Barniz',
      quantity: 8,
      unit: 'kg',
      minStock: 5,
      costPerUnit: 45.0,
    ),
  ];

  Future<UserModel> loginLocal(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final registered = LocalStorage.getRegisteredUsers();
    for (final u in registered) {
      if ((u['email'] as String).toLowerCase() == cleanEmail) {
        if (u['password'] == password) {
          return UserModel.fromJson(u, tokenOverride: 'mock-jwt-token-${u['id']}');
        } else {
          throw const AuthException('Contraseña incorrecta.');
        }
      }
    }

    // Por defecto ingresa como cliente (Marketplace), a menos que el correo sea de admin/maestro
    if (password.length >= 4) {
      final isAdminOrCarpenter = cleanEmail.contains('admin') ||
          cleanEmail.contains('maestro') ||
          cleanEmail.contains('taller');
      return UserModel(
        id: isAdminOrCarpenter ? 'USR-ADMIN-01' : 'USR-CLI-01',
        name: isAdminOrCarpenter
            ? 'Maestro Carpintero (Admin)'
            : (cleanEmail.contains('cliente')
                ? 'Carlos Mendoza'
                : _nameFromEmail(cleanEmail)),
        email: cleanEmail,
        phone: '+591 70012345',
        role: isAdminOrCarpenter ? 'carpintero' : 'cliente',
        token: 'mock-jwt-token-demo',
      );
    }

    throw const AuthException('Credenciales inválidas.');
  }

  Future<UserModel> registerLocal({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final id = 'USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final userMap = {
      'id': id,
      'nombre': name.trim(),
      'email': email.trim().toLowerCase(),
      'telefono': phone.trim(),
      'rol': role,
      'password': password,
      'token': 'mock-jwt-token-$id',
    };
    await LocalStorage.saveRegisteredUser(userMap);
    return UserModel.fromJson(userMap);
  }

  List<ProductModel> getProducts() => List.unmodifiable(_mockProducts);

  List<OrderModel> getOrders() => List.unmodifiable(_mockOrders);

  OrderModel createOrder({
    required String clientName,
    required String productName,
    required String woodType,
    required String specifications,
    required double totalAmount,
    required double advancePayment,
    required String deliveryDate,
  }) {
    final now = DateTime.now();
    final formattedNow =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final newOrder = OrderModel(
      id: 'PED-${108 + _mockOrders.length}',
      clientName: clientName,
      productName: productName,
      woodType: woodType,
      specifications: specifications,
      totalAmount: totalAmount,
      advancePayment: advancePayment,
      status: 'Pendiente',
      deliveryDate: deliveryDate,
      createdAt: formattedNow,
    );
    _mockOrders.insert(0, newOrder);
    return newOrder;
  }

  OrderModel updateOrderStatus(String orderId, String newStatus) {
    final index = _mockOrders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      throw const AppException('Pedido no encontrado');
    }
    final old = _mockOrders[index];
    final updated = OrderModel(
      id: old.id,
      clientName: old.clientName,
      productName: old.productName,
      woodType: old.woodType,
      specifications: old.specifications,
      totalAmount: old.totalAmount,
      advancePayment: old.advancePayment,
      status: newStatus,
      deliveryDate: old.deliveryDate,
      createdAt: old.createdAt,
    );
    _mockOrders[index] = updated;
    return updated;
  }

  List<WoodMaterialModel> getMaterials() => List.unmodifiable(_mockMaterials);

  String _nameFromEmail(String email) {
    final part = email.split('@').first.replaceAll('.', ' ').replaceAll('_', ' ');
    if (part.isEmpty) return 'Cliente Carpintería';
    return part[0].toUpperCase() + part.substring(1);
  }
}
