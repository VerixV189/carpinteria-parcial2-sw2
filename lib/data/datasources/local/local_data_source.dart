import 'package:carpinteria_movil_sw2/core/errors/app_exception.dart';
import 'package:carpinteria_movil_sw2/core/storage/local_storage.dart';
import 'package:carpinteria_movil_sw2/data/models/model.dart';
import 'package:carpinteria_movil_sw2/domain/entities/entity.dart';

class LocalDataSource {
  static final List<ProductModel> _mockProducts = [
    const ProductModel(
      id: 'P-001',
      name: 'Mesa de Comedor Imperial (6-8 Personas)',
      category: 'Mesas',
      woodType: 'Roble',
      dimensions: '200 x 100 x 76 cm',
      price: 2200.0,
      estimatedDays: 12,
      stock: 4,
      description:
          'Mesa de comedor principal trabajada en madera roble estacionada, acabado en poliuretano mate resistente a humedad y calor.',
      iconName: 'table_restaurant',
    ),
    const ProductModel(
      id: 'P-002',
      name: 'Juego de Sillas Tapizadas (Set x6)',
      category: 'Sillas',
      woodType: 'Mara',
      dimensions: '48 x 52 x 98 cm c/u',
      price: 2100.0,
      estimatedDays: 10,
      stock: 5,
      description:
          'Sillas reforzadas con espiga y caja, tapizado en lino antimanchas de alta densidad y barnizado natural en mara.',
      iconName: 'chair',
    ),
    const ProductModel(
      id: 'P-003',
      name: 'Ropero 3 Puertas con Espejo y Cajones',
      category: 'Roperos',
      woodType: 'Cedro',
      dimensions: '220 x 65 x 235 cm',
      price: 3800.0,
      estimatedDays: 15,
      stock: 3,
      description:
          'Ropero piso a techo con rieles telescópicos de cierre suave, cajonera interna, maletero superior y espejo central.',
      iconName: 'door_sliding',
    ),
    const ProductModel(
      id: 'P-004',
      name: 'Puerta Principal Tablero Rebajado',
      category: 'Puertas',
      woodType: 'Roble',
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
      name: 'Mueble de Cocina Modular + Estantería',
      category: 'Cocina',
      woodType: 'Melamina',
      dimensions: '320 cm lineales',
      price: 4600.0,
      estimatedDays: 18,
      stock: 2,
      description:
          'Módulos de cocina resistentes a humedad con bisagras cierre lento, pistones a gas y división de cubiertos.',
      iconName: 'countertops',
    ),
    const ProductModel(
      id: 'P-006',
      name: 'Escritorio Ejecutivo con Cajonera (3 Gavetas)',
      category: 'Mesas',
      woodType: 'Pino',
      dimensions: '150 x 70 x 76 cm',
      price: 1400.0,
      estimatedDays: 9,
      stock: 4,
      description:
          'Escritorio gerencial con pasacables oculto, 3 gavetas con llave y acabado satinado de alta durabilidad.',
      iconName: 'desk',
    ),
  ];

  static final List<ClientProfileModel> _mockClients = [
    const ClientProfileModel(
      id: 'CLI-1',
      name: 'Roberto Suárez',
      email: 'cliente@carpinteria.com',
      phone: '+591 70011223',
      address: 'Av. Cristo Redentor 4to Anillo, Santa Cruz',
      segment: 'VIP',
    ),
    const ClientProfileModel(
      id: 'CLI-2',
      name: 'Carlos Mendoza',
      email: 'carlos.mendoza@correo.bo',
      phone: '+591 71044556',
      address: 'Equipetrol Calle 7 Oeste #42',
      segment: 'REGULAR',
    ),
    const ClientProfileModel(
      id: 'CLI-3',
      name: 'Restaurante El Fogón',
      email: 'compras@elfogon.bo',
      phone: '+591 75099881',
      address: 'Av. Las Américas #310',
      segment: 'WHOLESALE',
    ),
  ];

  static final List<CarpenterModel> _mockCarpenters = [
    const CarpenterModel(
      id: 'CARP-1',
      name: 'Héctor Villarroel',
      email: 'carpintero@carpinteria.com',
      phone: '+591 72100991',
      specialty: 'Ebanistería fina y comedores',
      yearsExperience: 12,
      hourlyRate: 55.0,
      active: true,
    ),
    const CarpenterModel(
      id: 'CARP-2',
      name: 'Juan Mamani Quispe',
      email: 'juan.mamani@carpinteria.com',
      phone: '+591 73188442',
      specialty: 'Roperos empotrados y cocinas',
      yearsExperience: 8,
      hourlyRate: 48.0,
      active: true,
    ),
  ];

  static final List<QuotationModel> _mockQuotations = [
    const QuotationModel(
      id: 'COT-101',
      clientId: 'cliente@carpinteria.com',
      status: 'QUOTED',
      description: 'Mesa de comedor para 6 personas con acabado natural mate',
      woodType: 'Roble',
      totalAmount: 2200.0,
      finalAmount: 2150.0,
      notes: 'Incluye transporte e instalación en domicilio.',
      deliveryType: 'DELIVERY',
      deliveryAddress: 'Av. Cristo Redentor 4to Anillo',
      deliveryLatitude: -17.7540,
      deliveryLongitude: -63.1790,
      aiEstimate: AiEstimateModel(
        furnitureType: 'mesa',
        confidence: 0.92,
        estimatedPrice: 2200.0,
      ),
      createdAt: '2026-10-25',
    ),
    const QuotationModel(
      id: 'COT-102',
      clientId: 'cliente@carpinteria.com',
      status: 'DRAFT',
      description: 'Ropero de 3 puertas corredizas con espejo interior',
      woodType: 'Cedro',
      totalAmount: 3650.0,
      deliveryType: 'PICKUP',
      deliveryAddress: 'Recojo en taller central',
      aiEstimate: AiEstimateModel(
        furnitureType: 'ropero',
        confidence: 0.89,
        estimatedPrice: 3650.0,
      ),
      createdAt: '2026-10-26',
    ),
  ];

  static final List<OrderModel> _mockOrders = [
    const OrderModel(
      id: '101',
      clientId: 'CLI-1',
      clientName: 'Roberto Suárez',
      clientEmail: 'cliente@carpinteria.com',
      clientPhone: '+591 70011223',
      productName: 'Mesa de Comedor Imperial (6-8 Personas)',
      woodType: 'Roble',
      specifications: 'Acabado mate natural, entrega en domicilio.',
      totalAmount: 2200.0,
      advancePayment: 1100.0,
      status: 'En fabricación',
      rawStatus: 'IN_PRODUCTION',
      deliveryDate: '2026-10-30',
      createdAt: '2026-10-20',
      deliveryType: 'DELIVERY',
      deliveryAddress: 'Av. Cristo Redentor 4to Anillo, Santa Cruz',
      deliveryLat: -17.7540,
      deliveryLng: -63.1790,
      carpenters: [
        CarpenterModel(
          id: 'CARP-1',
          name: 'Héctor Villarroel',
          email: 'carpintero@carpinteria.com',
          specialty: 'Ebanistería fina y comedores',
        ),
      ],
      steps: [
        ProductionStepModel(
          id: 'STEP-1',
          name: 'Corte y selección de madera',
          status: 'COMPLETED',
          sequence: 1,
        ),
        ProductionStepModel(
          id: 'STEP-2',
          name: 'Armado y espigado estructural',
          status: 'IN_PROGRESS',
          sequence: 2,
        ),
        ProductionStepModel(
          id: 'STEP-3',
          name: 'Lijado fino y sellado de poro',
          status: 'PENDING',
          sequence: 3,
        ),
        ProductionStepModel(
          id: 'STEP-4',
          name: 'Laqueado poliuretano y control de calidad',
          status: 'PENDING',
          sequence: 4,
        ),
      ],
    ),
    const OrderModel(
      id: '102',
      clientId: 'CLI-2',
      clientName: 'Carlos Mendoza',
      clientEmail: 'carlos.mendoza@correo.bo',
      clientPhone: '+591 71044556',
      productName: 'Ropero 3 Puertas con Espejo y Cajones',
      woodType: 'Cedro',
      specifications: 'Con espejo central de cuerpo entero e iluminación LED interior.',
      totalAmount: 3800.0,
      advancePayment: 1900.0,
      status: 'Pendiente',
      rawStatus: 'PENDING',
      deliveryDate: '2026-11-04',
      createdAt: '2026-10-22',
      deliveryType: 'DELIVERY',
      deliveryAddress: 'Equipetrol Calle 7 Oeste #42',
      steps: [
        ProductionStepModel(
          id: 'STEP-5',
          name: 'Corte de tableros de cedro',
          status: 'PENDING',
          sequence: 1,
        ),
        ProductionStepModel(
          id: 'STEP-6',
          name: 'Ensamblado y rieles telescópicos',
          status: 'PENDING',
          sequence: 2,
        ),
      ],
    ),
    const OrderModel(
      id: '103',
      clientId: 'CLI-3',
      clientName: 'Restaurante El Fogón',
      clientEmail: 'compras@elfogon.bo',
      clientPhone: '+591 75099881',
      productName: 'Juego de Sillas Tapizadas (Set x6)',
      woodType: 'Mara',
      specifications: 'Barniz marino de alto tráfico resistente a líquidos.',
      totalAmount: 4200.0,
      advancePayment: 4200.0,
      status: 'Listo',
      rawStatus: 'READY',
      deliveryDate: '2026-10-28',
      createdAt: '2026-10-12',
      deliveryType: 'PICKUP',
      deliveryAddress: 'Recojo en taller central',
      steps: [
        ProductionStepModel(
          id: 'STEP-7',
          name: 'Corte y cepillado',
          status: 'COMPLETED',
          sequence: 1,
        ),
        ProductionStepModel(
          id: 'STEP-8',
          name: 'Tapizado y barnizado final',
          status: 'COMPLETED',
          sequence: 2,
        ),
      ],
    ),
  ];

  static final List<DeliveryModel> _mockDeliveries = [
    const DeliveryModel(
      id: 'DEL-1',
      orderId: '101',
      scheduledDate: '2026-10-30',
      timeSlot: 'MORNING',
      address: 'Av. Cristo Redentor 4to Anillo, Santa Cruz',
      status: 'SCHEDULED',
      notes: 'Llamar 30 min antes de llegar',
      deliveryType: 'DELIVERY',
      latitude: -17.7540,
      longitude: -63.1790,
    ),
    const DeliveryModel(
      id: 'DEL-2',
      orderId: '103',
      scheduledDate: '2026-10-28',
      timeSlot: 'AFTERNOON',
      address: 'Recojo en taller central',
      status: 'SCHEDULED',
      notes: 'Cliente recoge con camioneta propia',
      deliveryType: 'PICKUP',
    ),
  ];

  static final List<InvoiceModel> _mockInvoices = [
    const InvoiceModel(
      id: 'INV-1',
      number: '000104',
      series: 'A',
      clientName: 'Roberto Suárez',
      clientNit: '4829102015',
      clientEmail: 'cliente@carpinteria.com',
      orderId: '101',
      paymentId: 'PAY-00104',
      subtotal: 1914.0,
      tax: 286.0,
      total: 2200.0,
      status: 'PAID',
      issuedAt: '2026-10-25 14:30',
      items: [
        InvoiceItemModel(
          description: 'Mesa de Comedor Imperial en Roble',
          quantity: 1,
          unitPrice: 2200.0,
          lineTotal: 2200.0,
        ),
      ],
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

    // 1. Verificar usuarios registrados o sincronizados localmente
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

    // 2. Cuentas semilla principales del sistema (SEED_USERS)
    if (cleanEmail == 'admin@carpinteria.com') {
      if (password != 'admin123') {
        throw const AuthException('Contraseña incorrecta para la cuenta de Administrador.');
      }
      return const UserModel(
        id: 'USR-ADMIN-01',
        name: 'Dirección General',
        email: 'admin@carpinteria.com',
        phone: '+591 70012345',
        role: 'ADMIN',
        token: 'mock-jwt-token-admin',
      );
    }
    if (cleanEmail == 'carpintero@carpinteria.com') {
      if (password != 'carp123' && password != '123456') {
        throw const AuthException('Contraseña incorrecta para la cuenta de Carpintero.');
      }
      return const UserModel(
        id: 'CARP-1',
        name: 'Héctor Villarroel',
        email: 'carpintero@carpinteria.com',
        phone: '+591 72100991',
        role: 'CARPENTER',
        token: 'mock-jwt-token-carpenter',
      );
    }
    if (cleanEmail == 'cliente@carpinteria.com') {
      if (password != 'cliente123' && password != '123456') {
        throw const AuthException('Contraseña incorrecta para la cuenta de Cliente.');
      }
      return const UserModel(
        id: 'CLI-1',
        name: 'Roberto Suárez',
        email: 'cliente@carpinteria.com',
        phone: '+591 70011223',
        role: 'CLIENT',
        token: 'mock-jwt-token-client',
      );
    }

    // 3. Carpinteros registrados en el listado del taller (clave por defecto: carp123 o 123456)
    for (final carp in _mockCarpenters) {
      if (carp.email.trim().toLowerCase() == cleanEmail) {
        if (password == 'carp123' || password == '123456' || password.length >= 4) {
          return UserModel(
            id: carp.id,
            name: carp.name,
            email: carp.email,
            phone: carp.phone,
            role: 'CARPENTER',
            token: 'mock-jwt-token-${carp.id}',
          );
        }
        throw const AuthException('Contraseña incorrecta (clave por defecto: carp123).');
      }
    }

    // 4. Clientes registrados en cartera (clave por defecto: cliente123 o 123456)
    for (final cli in _mockClients) {
      if (cli.email.trim().toLowerCase() == cleanEmail) {
        if (password == 'cliente123' || password == '123456' || password.length >= 4) {
          return UserModel(
            id: cli.id,
            name: cli.name,
            email: cli.email,
            phone: cli.phone,
            role: 'CLIENT',
            token: 'mock-jwt-token-${cli.id}',
          );
        }
        throw const AuthException('Contraseña incorrecta (clave por defecto: cliente123).');
      }
    }

    // 5. Fallback para nuevas cuentas en modo local sin conexión
    if (password.length >= 3) {
      String role = 'CLIENT';
      String name = _nameFromEmail(cleanEmail);
      if (cleanEmail.contains('admin')) {
        role = 'ADMIN';
        name = 'Dirección General';
      } else if (cleanEmail.contains('carpintero') ||
          cleanEmail.contains('maestro') ||
          cleanEmail.contains('taller')) {
        role = 'CARPENTER';
      }
      return UserModel(
        id: 'USR-$role-01',
        name: name,
        email: cleanEmail,
        phone: '+591 70012345',
        role: role,
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
      'name': name.trim(),
      'nombre': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'telefono': phone.trim(),
      'role': role,
      'rol': role,
      'password': password,
      'token': 'mock-jwt-token-$id',
    };
    await LocalStorage.saveRegisteredUser(userMap);
    return UserModel.fromJson(userMap);
  }

  List<ProductModel> getProducts() => List.unmodifiable(_mockProducts);
  List<WoodMaterialModel> getMaterials() => List.unmodifiable(_mockMaterials);

  List<ClientProfileModel> getClients({String? search}) {
    if (search == null || search.trim().isEmpty) {
      return List.unmodifiable(_mockClients);
    }
    final q = search.toLowerCase();
    return _mockClients
        .where((c) =>
            c.name.toLowerCase().contains(q) || c.email.toLowerCase().contains(q))
        .toList();
  }

  ClientProfileModel createClient(ClientProfileModel client) {
    _mockClients.insert(0, client);
    return client;
  }

  ClientProfileModel updateClient(ClientProfileModel client) {
    final idx = _mockClients.indexWhere((c) => c.id == client.id);
    if (idx != -1) _mockClients[idx] = client;
    return client;
  }

  bool deleteClient(String id) {
    _mockClients.removeWhere((c) => c.id == id);
    return true;
  }

  List<CarpenterModel> getCarpenters() => List.unmodifiable(_mockCarpenters);

  CarpenterModel createCarpenter(CarpenterModel carpenter) {
    _mockCarpenters.insert(0, carpenter);
    return carpenter;
  }

  CarpenterModel updateCarpenter(CarpenterModel carpenter) {
    final idx = _mockCarpenters.indexWhere((c) => c.id == carpenter.id);
    if (idx != -1) _mockCarpenters[idx] = carpenter;
    return carpenter;
  }

  bool deleteCarpenter(String id) {
    _mockCarpenters.removeWhere((c) => c.id == id);
    return true;
  }

  List<QuotationModel> getQuotations({String? status}) {
    if (status == null || status.isEmpty) {
      return List.unmodifiable(_mockQuotations);
    }
    return _mockQuotations
        .where((q) => q.status.toUpperCase() == status.toUpperCase())
        .toList();
  }

  QuotationModel addOrUpdateQuotation(QuotationModel quotation) {
    final idx = _mockQuotations.indexWhere((q) => q.id == quotation.id);
    if (idx != -1) {
      _mockQuotations[idx] = quotation;
    } else {
      _mockQuotations.insert(0, quotation);
    }
    return quotation;
  }

  List<OrderModel> getOrders() => List.unmodifiable(_mockOrders);

  OrderModel createOrder({
    required String clientName,
    required String productName,
    required String woodType,
    required String specifications,
    required double totalAmount,
    required double advancePayment,
    required String deliveryDate,
    String deliveryType = 'DELIVERY',
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
  }) {
    final now = DateTime.now();
    final formattedNow =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final newOrder = OrderModel(
      id: '${104 + _mockOrders.length}',
      clientName: clientName,
      productName: productName,
      woodType: woodType,
      specifications: specifications,
      totalAmount: totalAmount,
      advancePayment: advancePayment,
      status: 'Pendiente',
      rawStatus: 'PENDING',
      deliveryDate: deliveryDate,
      createdAt: formattedNow,
      deliveryType: deliveryType,
      deliveryAddress: deliveryAddress ?? '',
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      steps: const [
        ProductionStepModel(
          id: 'S-1',
          name: 'Corte y habilitado de madera',
          status: 'PENDING',
          sequence: 1,
        ),
        ProductionStepModel(
          id: 'S-2',
          name: 'Armado y lijado',
          status: 'PENDING',
          sequence: 2,
        ),
        ProductionStepModel(
          id: 'S-3',
          name: 'Barnizado y acabado final',
          status: 'PENDING',
          sequence: 3,
        ),
      ],
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
      clientId: old.clientId,
      clientName: old.clientName,
      clientEmail: old.clientEmail,
      clientPhone: old.clientPhone,
      productName: old.productName,
      woodType: old.woodType,
      specifications: old.specifications,
      totalAmount: old.totalAmount,
      advancePayment: old.advancePayment,
      status: OrderEntity.toSpanishStatus(newStatus),
      rawStatus: OrderEntity.toBackendStatus(newStatus),
      deliveryDate: old.deliveryDate,
      createdAt: old.createdAt,
      quotationId: old.quotationId,
      deliveryType: old.deliveryType,
      deliveryAddress: old.deliveryAddress,
      deliveryLat: old.deliveryLat,
      deliveryLng: old.deliveryLng,
      items: old.items,
      steps: old.steps,
      carpenters: old.carpenters,
      delivery: old.delivery,
    );
    _mockOrders[index] = updated;
    return updated;
  }

  ProductionStepModel updateStepStatus(String stepId, String status) {
    for (var i = 0; i < _mockOrders.length; i++) {
      final ord = _mockOrders[i];
      final stepIdx = ord.steps.indexWhere((s) => s.id == stepId);
      if (stepIdx != -1) {
        final oldStep = ord.steps[stepIdx];
        final newStep = ProductionStepModel(
          id: oldStep.id,
          name: oldStep.name,
          status: status.toUpperCase(),
          sequence: oldStep.sequence,
        );
        final nextSteps = List<ProductionStepEntity>.from(ord.steps);
        nextSteps[stepIdx] = newStep;
        _mockOrders[i] = OrderModel(
          id: ord.id,
          clientId: ord.clientId,
          clientName: ord.clientName,
          clientEmail: ord.clientEmail,
          clientPhone: ord.clientPhone,
          productName: ord.productName,
          woodType: ord.woodType,
          specifications: ord.specifications,
          totalAmount: ord.totalAmount,
          advancePayment: ord.advancePayment,
          status: ord.status,
          rawStatus: ord.rawStatus,
          deliveryDate: ord.deliveryDate,
          createdAt: ord.createdAt,
          quotationId: ord.quotationId,
          deliveryType: ord.deliveryType,
          deliveryAddress: ord.deliveryAddress,
          deliveryLat: ord.deliveryLat,
          deliveryLng: ord.deliveryLng,
          items: ord.items,
          steps: nextSteps,
          carpenters: ord.carpenters,
          delivery: ord.delivery,
        );
        return newStep;
      }
    }
    return ProductionStepModel(
      id: stepId,
      name: 'Paso actualizado',
      status: status.toUpperCase(),
      sequence: 1,
    );
  }

  List<DeliveryModel> getDeliveries() => List.unmodifiable(_mockDeliveries);

  DeliveryModel addOrUpdateDelivery(DeliveryModel delivery) {
    final idx = _mockDeliveries.indexWhere((d) => d.id == delivery.id);
    if (idx != -1) {
      _mockDeliveries[idx] = delivery;
    } else {
      _mockDeliveries.insert(0, delivery);
    }
    return delivery;
  }

  List<InvoiceModel> getInvoices({String? clientEmail}) {
    if (clientEmail == null || clientEmail.isEmpty) {
      return List.unmodifiable(_mockInvoices);
    }
    return _mockInvoices
        .where((i) =>
            i.clientEmail.isEmpty ||
            i.clientEmail.toLowerCase() == clientEmail.toLowerCase())
        .toList();
  }

  InvoiceModel addInvoice(InvoiceModel invoice) {
    _mockInvoices.insert(0, invoice);
    return invoice;
  }

  String _nameFromEmail(String email) {
    final part = email.split('@').first.replaceAll('.', ' ').replaceAll('_', ' ');
    if (part.isEmpty) return 'Cliente Carpintería';
    return part[0].toUpperCase() + part.substring(1);
  }
}
