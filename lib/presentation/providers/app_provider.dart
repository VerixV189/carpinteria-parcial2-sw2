import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:carpinteria_movil_sw2/core/config/app_config.dart';
import 'package:carpinteria_movil_sw2/core/services/biometric_auth_service.dart';
import 'package:carpinteria_movil_sw2/core/services/push_notification_service.dart';
import 'package:carpinteria_movil_sw2/core/services/realtime_notification_service.dart';
import 'package:carpinteria_movil_sw2/core/storage/local_storage.dart';
import 'package:carpinteria_movil_sw2/core/storage/sqlite_database.dart';
import 'package:carpinteria_movil_sw2/data/repositories/repository_impl.dart';
import 'package:carpinteria_movil_sw2/domain/entities/entity.dart';
import 'package:carpinteria_movil_sw2/domain/repositories/repository.dart';

class AppProvider extends ChangeNotifier {
  final CarpentryRepository _repository;
  final BiometricAuthService _biometricService = BiometricAuthService();
  late final RealtimeNotificationService _realtimeService;
  Timer? _pollingTimer;

  UserEntity? _currentUser;
  List<ProductEntity> _products = [];
  List<OrderEntity> _orders = [];
  List<WoodMaterialEntity> _materials = [];
  List<ClientProfileEntity> _clients = [];
  List<ClientClusterEntity> _clientClusters = [];
  List<CarpenterEntity> _carpenters = [];
  List<QuotationEntity> _quotations = [];
  List<DeliveryEntity> _deliveries = [];
  List<InvoiceEntity> _invoices = [];
  final List<CartItemEntity> _cart = [];
  final List<AppNotificationEntity> _notifications = [];
  AppNotificationEntity? _latestToastNotification;

  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'Todos';
  String _searchQuery = '';

  AppProvider({CarpentryRepository? repository})
      : _repository = repository ?? CarpentryRepositoryImpl() {
    _realtimeService = RealtimeNotificationService(
      onNotification: _handleIncomingRealtimeNotification,
    );
  }

  UserEntity? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  bool get isClientRole {
    final role = (_currentUser?.role ?? 'cliente').trim().toLowerCase();
    return role == 'cliente' || role == 'client';
  }

  bool get isAdminRole {
    final role = (_currentUser?.role ?? '').trim().toLowerCase();
    return role == 'admin' || role == 'administrador';
  }

  bool get isCarpenterRole {
    final role = (_currentUser?.role ?? '').trim().toLowerCase();
    return role == 'carpintero' || role == 'carpenter' || role == 'taller';
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUsingMock => _repository.isUsingMock;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  List<String> get categories =>
      const ['Todos', 'Mesas', 'Sillas', 'Roperos', 'Puertas', 'Cocina'];

  List<ProductEntity> get filteredProducts {
    return _products.where((p) {
      final matchesCategory =
          _selectedCategory == 'Todos' || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.woodType.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<ProductEntity> get availableMarketplaceProducts {
    return filteredProducts.where((p) => p.stock > 0).toList();
  }

  List<ProductEntity> get allProducts => _products;
  List<OrderEntity> get orders => _orders;
  List<WoodMaterialEntity> get materials => _materials;
  List<ClientProfileEntity> get clients => _clients;
  List<ClientClusterEntity> get clientClusters => _clientClusters;
  List<CarpenterEntity> get carpenters => _carpenters;
  List<QuotationEntity> get quotations => _quotations;
  List<DeliveryEntity> get deliveries => _deliveries;
  List<InvoiceEntity> get invoices => _invoices;

  List<AppNotificationEntity> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.read).length;

  AppNotificationEntity? get latestToastNotification =>
      _latestToastNotification;

  void clearLatestToast() {
    _latestToastNotification = null;
  }

  void markAllNotificationsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(read: true);
    }
    notifyListeners();
  }

  void pushNotification({
    required String title,
    required String body,
    String? orderId,
    String? status,
  }) {
    final notif = AppNotificationEntity(
      id: 'N-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      orderId: orderId,
      status: status,
      timestamp: DateTime.now(),
    );
    _notifications.insert(0, notif);
    _latestToastNotification = notif;
    notifyListeners();
    PushNotificationService.showSystemPush(title: title, body: body);
  }

  void _handleIncomingRealtimeNotification(AppNotificationEntity notif) {
    _notifications.insert(0, notif);
    _latestToastNotification = notif;
    notifyListeners();
    PushNotificationService.showSystemPush(
      title: notif.title,
      body: notif.body,
    );
    // Refrescar pedidos y cotizaciones silenciosamente
    refreshSilent();
  }

  /// Pedidos y cotizaciones que pertenecen al cliente actual
  List<OrderEntity> get clientOrders {
    if (isClientRole) {
      final userEmail = (_currentUser?.email ?? '').trim().toLowerCase();
      final userName = (_currentUser?.name ?? '').trim().toLowerCase();
      final matching = _orders.where((o) {
        if (userEmail.isNotEmpty &&
            (o.clientEmail.toLowerCase() == userEmail ||
                o.clientId.toLowerCase() == userEmail)) {
          return true;
        }
        return userName.isNotEmpty &&
            o.clientName.trim().toLowerCase() == userName;
      }).toList();
      return matching.isNotEmpty ? matching : _orders;
    }
    return _orders;
  }

  // ── Carrito de Compras del Cliente ────────────────────────────────────────

  List<CartItemEntity> get cartItems => List.unmodifiable(_cart);

  int get cartItemCount =>
      _cart.fold<int>(0, (sum, item) => sum + item.quantity);

  double get cartTotal =>
      _cart.fold<double>(0.0, (sum, item) => sum + item.subtotal);

  void addToCart(ProductEntity product, {int quantity = 1}) {
    final index = _cart.indexWhere((c) => c.product.id == product.id);
    if (index != -1) {
      final current = _cart[index];
      final nextQty = (current.quantity + quantity).clamp(1, product.stock);
      _cart[index] = current.copyWith(quantity: nextQty);
    } else {
      _cart.add(CartItemEntity(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void updateCartQuantity(String productId, int newQuantity) {
    final index = _cart.indexWhere((c) => c.product.id == productId);
    if (index == -1) return;
    if (newQuantity <= 0) {
      _cart.removeAt(index);
    } else {
      final maxStock = _cart[index].product.stock;
      _cart[index] = _cart[index].copyWith(
        quantity: newQuantity.clamp(1, maxStock),
      );
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((c) => c.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<bool> checkoutCart({
    required double advancePayment,
    required String deliveryNotes,
    String deliveryType = 'DELIVERY',
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
  }) async {
    if (_cart.isEmpty) return false;

    // 1) Checkout real del Marketplace: cobra, descuenta stock, crea pedido
    //    auto-asignado al carpintero y genera el recibo PDF.
    if (!isUsingMock) {
      try {
        await _repository.checkoutMarketplace({
          'items': _cart
              .map((c) => {'productId': c.product.id, 'quantity': c.quantity})
              .toList(),
          'deliveryType': deliveryType,
          'deliveryAddress': deliveryType == 'DELIVERY'
              ? (deliveryAddress ?? deliveryNotes)
              : 'Recojo en taller',
          'deliveryLat': ?deliveryLat,
          'deliveryLng': ?deliveryLng,
          if (deliveryNotes.isNotEmpty) 'notes': deliveryNotes,
          // Pasarela mock: tarjetas 4242… aprueban
          'cardNumber': '4242424242424242',
          'cardHolder': (_currentUser?.name ?? 'CLIENTE').toUpperCase(),
          'expiryMonth': 12,
          'expiryYear': 2028,
          'cvv': '123',
        });
        _cart.clear();
        await loadCarpentryData();
        pushNotification(
          title: 'Compra confirmada',
          body: 'Tu pedido entró a producción y el recibo PDF se está generando.',
        );
        return true;
      } catch (e) {
        _errorMessage = e.toString();
        notifyListeners();
        return false;
      }
    }

    // 2) Modo offline: pedido local como antes
    final clientName = _currentUser?.name ?? 'Cliente';
    final summaryNames =
        _cart.map((c) => '${c.product.name} (x${c.quantity})').join(', ');
    final woods = _cart.map((c) => c.product.woodType).toSet().join(' / ');
    final total = cartTotal;
    final maxDays = _cart
        .map((c) => c.product.estimatedDays)
        .fold<int>(7, (a, b) => a > b ? a : b);
    final estDate = DateTime.now().add(Duration(days: maxDays));
    final dateStr =
        '${estDate.year}-${estDate.month.toString().padLeft(2, '0')}-${estDate.day.toString().padLeft(2, '0')}';

    final ok = await createOrder(
      clientName: clientName,
      productName: summaryNames,
      woodType: woods,
      specifications: deliveryNotes.isEmpty
          ? 'Compra desde Catálogo Móvil'
          : deliveryNotes,
      totalAmount: total,
      advancePayment: advancePayment,
      deliveryDate: dateStr,
      deliveryType: deliveryType,
      deliveryAddress: deliveryAddress ?? deliveryNotes,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
    );
    if (ok) {
      _cart.clear();
      notifyListeners();
    }
    return ok;
  }

  // ── Marketplace CRUD (Admin / Carpintero) ─────────────────────────────────

  Future<bool> saveMarketplaceProduct({
    String? id,
    required String name,
    required String category,
    required String woodType,
    required String dimensions,
    required double price,
    required int stock,
    required int estimatedDays,
    required String description,
    String? imageUrl,
    String? imageBase64,
  }) async {
    try {
      var url = imageUrl;
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        url = await _repository.uploadImageToS3(imageBase64);
      }
      await _repository.saveMarketplaceProduct({
        'name': name,
        'category': category,
        'woodType': woodType,
        'dimensions': dimensions,
        'price': price,
        'stock': stock,
        'estimatedDays': estimatedDays,
        'description': description,
        if (url != null && url.isNotEmpty) 'imageUrl': url,
      }, id: id);
      _products = await _repository.getProducts();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMarketplaceProduct(String id) async {
    try {
      await _repository.deleteMarketplaceProduct(id);
      _products = await _repository.getProducts();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Sesión, Tiempo Real y Sincronización ──────────────────────────────────

  Future<void> initializeSession() async {
    await LocalStorage.init();
    final savedUrl = LocalStorage.getCustomBaseUrl();
    if (savedUrl != null && savedUrl.isNotEmpty) {
      final normalized = AppConfig.normalizeBaseUrl(savedUrl);
      AppConfig.setCustomBaseUrl(normalized);
      if (normalized != savedUrl) {
        await LocalStorage.saveCustomBaseUrl(normalized);
      }
    }
    _currentUser = await _repository.getSavedSession();
    if (_currentUser != null) {
      await loadCarpentryData();
      _startRealtimeServices();
    }
    notifyListeners();
  }

  void _startRealtimeServices() {
    _realtimeService.connect(includeGraphqlSubscription: !isClientRole);
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 18), (_) {
      if (isAuthenticated) {
        refreshSilent();
      }
    });
  }

  void _stopRealtimeServices() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _realtimeService.disconnect();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _repository.login(email: email, password: password);
      if (_currentUser != null) {
        await LocalStorage.saveSessionPassword(password);
        await PushNotificationService.requestPermissionIfNeeded();
      }
      await loadCarpentryData();
      _startRealtimeServices();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Map<String, dynamic>? get savedBiometricAccount =>
      LocalStorage.getBiometricCredentials();

  DateTime? get sessionExpiresAt => LocalStorage.getSessionExpiresAt();

  bool get isCurrentUserBiometricEnabled {
    final email = _currentUser?.email ?? '';
    if (email.isEmpty) return false;
    return LocalStorage.isBiometricEnrolledForEmail(email);
  }

  String _defaultPasswordForEmail(String email) {
    final lower = email.trim().toLowerCase();
    if (lower == 'admin@carpinteria.com') return 'admin123';
    if (lower == 'carpintero@carpinteria.com') return 'carp123';
    if (lower == 'cliente@carpinteria.com') return 'cliente123';
    for (final reg in LocalStorage.getRegisteredUsers()) {
      if ((reg['email'] as String?)?.trim().toLowerCase() == lower) {
        return (reg['password'] as String?) ?? 'cliente123';
      }
    }
    return 'cliente123';
  }

  Future<bool> configureBiometricForCurrentUser() async {
    final user = _currentUser;
    if (user == null) return false;
    _errorMessage = null;

    final bioResult = await _biometricService.authenticateWithFingerprint(
      reason:
          'Coloca tu huella dactilar para vincularla a tu cuenta (${user.email})',
    );

    if (!bioResult.authenticated) {
      _errorMessage = bioResult.error;
      notifyListeners();
      return false;
    }

    final password =
        LocalStorage.getSessionPassword() ?? _defaultPasswordForEmail(user.email);
    await LocalStorage.saveBiometricCredentials(
      email: user.email,
      password: password,
      name: user.name,
      role: user.role,
    );
    pushNotification(
      title: 'Huella dactilar configurada',
      body:
          'Ahora puedes iniciar sesión solo ingresando tu correo (${user.email}) y tu huella dactilar.',
    );
    notifyListeners();
    return true;
  }

  Future<void> disableBiometricForCurrentUser() async {
    final user = _currentUser;
    if (user == null) return;
    await LocalStorage.removeBiometricForEmail(user.email);
    pushNotification(
      title: 'Huella dactilar desvinculada',
      body: 'Se desactivó el acceso con huella para la cuenta ${user.email}.',
    );
    notifyListeners();
  }

  Future<bool> loginWithBiometrics({
    String? preferredEmail,
    String? preferredPassword,
  }) async {
    _errorMessage = null;
    final typedEmail = (preferredEmail ?? '').trim();
    if (typedEmail.isEmpty) {
      _errorMessage =
          'Ingresa primero tu correo electrónico para desbloquear con tu huella dactilar.';
      notifyListeners();
      return false;
    }

    final savedForEmail = LocalStorage.getBiometricAccountForEmail(typedEmail);
    if (savedForEmail == null) {
      _errorMessage =
          'La cuenta $typedEmail aún no tiene huella configurada. Inicia sesión con tu contraseña y actívala en Mi Perfil.';
      notifyListeners();
      return false;
    }

    final email = (savedForEmail['email'] as String?) ?? typedEmail;
    final password =
        (savedForEmail['password'] as String?) ?? _defaultPasswordForEmail(email);
    final displayName = (savedForEmail['name'] as String?) ?? email;

    final bioResult = await _biometricService.authenticateWithFingerprint(
      reason:
          'Verifica tu huella dactilar para ingresar como $displayName ($email)',
    );

    if (!bioResult.authenticated) {
      _errorMessage = bioResult.error;
      notifyListeners();
      return false;
    }

    return login(email, password);
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _repository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      if (_currentUser != null) {
        await LocalStorage.saveSessionPassword(password);
        await PushNotificationService.requestPermissionIfNeeded();
      }
      await loadCarpentryData();
      _startRealtimeServices();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _stopRealtimeServices();
    await _repository.logout();
    _currentUser = null;
    _cart.clear();
    _notifications.clear();
    notifyListeners();
  }

  Future<void> loadCarpentryData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getProducts(),
        _repository.getOrders(),
        _repository.getMaterials(),
        _repository.getQuotations(),
        _repository.getInvoices(
          clientEmail: isClientRole ? _currentUser?.email : null,
        ),
      ]);
      _products = results[0] as List<ProductEntity>;
      _orders = results[1] as List<OrderEntity>;
      _materials = results[2] as List<WoodMaterialEntity>;
      _quotations = results[3] as List<QuotationEntity>;
      _invoices = results[4] as List<InvoiceEntity>;

      if (!isClientRole) {
        final adminResults = await Future.wait([
          _repository.getClients(),
          _repository.getCarpenters(),
          _repository.getDeliveries(),
        ]);
        _clients = adminResults[0] as List<ClientProfileEntity>;
        _carpenters = adminResults[1] as List<CarpenterEntity>;
        _deliveries = adminResults[2] as List<DeliveryEntity>;
      }

      await SqliteDatabase.syncAll(
        products: _products,
        orders: _orders,
        materials: _materials,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSilent() async {
    try {
      final prevOrderStatus = {for (final o in _orders) o.id: o.status};
      final prevQuoteStatus = {for (final q in _quotations) q.id: q.status};

      final nextOrders = await _repository.getOrders();
      final nextQuotes = await _repository.getQuotations();
      final nextInvoices = await _repository.getInvoices(
        clientEmail: isClientRole ? _currentUser?.email : null,
      );

      for (final o in nextOrders) {
        final prev = prevOrderStatus[o.id];
        if (prev != null && prev != o.status) {
          pushNotification(
            title: 'Pedido #${o.id} actualizado',
            body: '${o.productName} pasó a estado: ${o.status}',
            orderId: o.id,
            status: o.status,
          );
        }
      }

      for (final q in nextQuotes) {
        final prev = prevQuoteStatus[q.id];
        if (prev != null && prev != q.status) {
          pushNotification(
            title: 'Cotización #${q.id.substring(0, q.id.length.clamp(0, 8))}',
            body:
                '${q.description} ahora está: ${q.statusLabel} (Bs ${q.payableAmount.toStringAsFixed(0)})',
            orderId: q.id,
            status: q.status,
          );
        }
      }

      _orders = nextOrders;
      _quotations = nextQuotes;
      _invoices = nextInvoices;

      if (!isClientRole) {
        _deliveries = await _repository.getDeliveries();
      }
      notifyListeners();
    } catch (_) {}
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ── Clientes y Segmentación ───────────────────────────────────────────────

  Future<bool> createClient({
    required String name,
    required String email,
    String? phone,
    String? address,
    String segment = 'REGULAR',
  }) async {
    try {
      final created = await _repository.createClient(
        name: name,
        email: email,
        phone: phone,
        address: address,
        segment: segment,
      );
      _clients = [created, ..._clients];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateClient({
    required String id,
    required String name,
    required String email,
    String? phone,
    String? address,
    String segment = 'REGULAR',
  }) async {
    try {
      final updated = await _repository.updateClient(
        id: id,
        name: name,
        email: email,
        phone: phone,
        address: address,
        segment: segment,
      );
      _clients = _clients.map((c) => c.id == id ? updated : c).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteClient(String id) async {
    try {
      await _repository.deleteClient(id);
      _clients = _clients.where((c) => c.id != id).toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ClientClusterEntity>> runClientClustering() async {
    final clusters = await _repository.clusterClients();
    _clientClusters = clusters;
    notifyListeners();
    return clusters;
  }

  // ── Carpinteros y Taller ──────────────────────────────────────────────────

  Future<bool> createCarpenter({
    required String name,
    required String email,
    String? phone,
    required String specialty,
    int yearsExperience = 3,
    double hourlyRate = 45.0,
    bool active = true,
  }) async {
    try {
      final created = await _repository.createCarpenter(
        name: name,
        email: email,
        phone: phone,
        specialty: specialty,
        yearsExperience: yearsExperience,
        hourlyRate: hourlyRate,
        active: active,
      );
      _carpenters = [created, ..._carpenters];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCarpenter({
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
      final updated = await _repository.updateCarpenter(
        id: id,
        name: name,
        email: email,
        phone: phone,
        specialty: specialty,
        yearsExperience: yearsExperience,
        hourlyRate: hourlyRate,
        active: active,
      );
      _carpenters = _carpenters.map((c) => c.id == id ? updated : c).toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCarpenter(String id) async {
    try {
      await _repository.deleteCarpenter(id);
      _carpenters = _carpenters.where((c) => c.id != id).toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<OrderEntity>> getCarpenterWorkload(String carpenterId) {
    return _repository.getCarpenterWorkload(carpenterId);
  }

  // ── Cotizaciones y Negociación ────────────────────────────────────────────

  Future<AiEstimateEntity> estimateFurniture({
    required String description,
    required String woodType,
    String? imageBase64,
  }) {
    return _repository.estimateFurniture(
      description: description,
      woodType: woodType,
      imageBase64: imageBase64,
    );
  }

  Future<QuotationEntity?> createQuotation({
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
    try {
      final clientId = (_currentUser?.email.isNotEmpty == true)
          ? _currentUser!.email
          : (_currentUser?.id ?? 'cliente@carpinteria.com');
      final created = await _repository.createQuotation(
        clientId: clientId,
        description: description,
        woodType: woodType,
        estimatedPrice: estimatedPrice,
        quantity: quantity,
        photoUrl: photoUrl,
        aiEstimate: aiEstimate,
        deliveryType: deliveryType,
        deliveryAddress: deliveryAddress,
        latitude: latitude,
        longitude: longitude,
      );
      _quotations = [created, ..._quotations];
      pushNotification(
        title: 'Nueva cotización solicitada',
        body:
            'Se registró la cotización de "${created.description}" (${created.woodType}) por Bs ${created.payableAmount.toStringAsFixed(0)}.',
        orderId: created.id,
        status: created.status,
      );
      await loadCarpentryData();
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<QuotationEntity?> respondQuotation({
    required String id,
    required String action,
    double? counterAmount,
    String? message,
  }) async {
    try {
      final updated = await _repository.respondQuotation(
        id: id,
        action: action,
        counterAmount: counterAmount,
        message: message,
      );
      _quotations = _quotations.map((q) => q.id == id ? updated : q).toList();
      pushNotification(
        title: action == 'counter'
            ? 'Contraoferta enviada al taller'
            : 'Cotización actualizada',
        body: action == 'counter'
            ? 'Propusiste Bs ${(counterAmount ?? updated.payableAmount).toStringAsFixed(0)} para "${updated.description}".'
            : 'La cotización "${updated.description}" pasó a estado: ${updated.statusLabel}.',
        orderId: id,
        status: updated.status,
      );
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> sendQuotationFormalPrice({
    required String id,
    required double finalAmount,
    String? notes,
  }) async {
    try {
      final updated = await _repository.sendQuotationFormalPrice(
        id: id,
        finalAmount: finalAmount,
        notes: notes,
      );
      _quotations = _quotations.map((q) => q.id == id ? updated : q).toList();
      pushNotification(
        title: 'Cotización enviada al cliente',
        body:
            'Precio formal Bs ${finalAmount.toStringAsFixed(0)} enviado para ${updated.description}',
        orderId: id,
        status: 'QUOTED',
      );
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> approveQuotation({
    required String id,
    double? finalAmount,
    String? notes,
  }) async {
    try {
      final updated = await _repository.approveQuotation(
        id: id,
        finalAmount: finalAmount,
        notes: notes,
      );
      _quotations = _quotations.map((q) => q.id == id ? updated : q).toList();
      pushNotification(
        title: 'Cotización aprobada',
        body:
            'La cotización "${updated.description}" fue aprobada por Bs ${updated.payableAmount.toStringAsFixed(0)}.',
        orderId: id,
        status: updated.status,
      );
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectQuotation({
    required String id,
    String? reason,
  }) async {
    try {
      final updated = await _repository.rejectQuotation(
        id: id,
        reason: reason,
      );
      _quotations = _quotations.map((q) => q.id == id ? updated : q).toList();
      pushNotification(
        title: 'Cotización rechazada',
        body:
            'La cotización "${updated.description}" fue marcada como rechazada.',
        orderId: id,
        status: updated.status,
      );
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Pedidos, Pasos de Producción y Entregas ───────────────────────────────

  Future<bool> createOrder({
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
    try {
      final created = await _repository.createOrder(
        clientName: clientName,
        productName: productName,
        woodType: woodType,
        specifications: specifications,
        totalAmount: totalAmount,
        advancePayment: advancePayment,
        deliveryDate: deliveryDate,
        clientId: clientId,
        deliveryType: deliveryType,
        deliveryAddress: deliveryAddress,
        deliveryLat: deliveryLat,
        deliveryLng: deliveryLng,
      );
      _orders = [created, ..._orders];
      pushNotification(
        title: 'Nuevo pedido registrado (#${created.id})',
        body:
            '$productName en madera $woodType para $clientName (Bs ${totalAmount.toStringAsFixed(0)}).',
        orderId: created.id,
        status: created.status,
      );
      await SqliteDatabase.syncAll(
        products: _products,
        orders: _orders,
        materials: _materials,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final updated = await _repository.updateOrderStatus(orderId, newStatus);
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        final copy = List<OrderEntity>.from(_orders);
        copy[idx] = updated;
        _orders = copy;
        pushNotification(
          title: 'Pedido #$orderId actualizado',
          body: '${updated.productName} ahora está en: ${updated.status}',
          orderId: orderId,
          status: updated.status,
        );
        await SqliteDatabase.syncAll(
          products: _products,
          orders: _orders,
          materials: _materials,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> assignCarpenter(String orderId, String carpenterId) async {
    try {
      final updated = await _repository.assignCarpenter(orderId, carpenterId);
      _orders = _orders.map((o) => o.id == orderId ? updated : o).toList();
      pushNotification(
        title: 'Maestro carpintero asignado',
        body:
            'El pedido #$orderId (${updated.productName}) fue asignado a ${updated.carpenters.isNotEmpty ? updated.carpenters.first.name : "taller"}.',
        orderId: orderId,
        status: updated.status,
      );
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStepStatus(String stepId, String status) async {
    try {
      await _repository.updateStepStatus(stepId, status);
      await loadCarpentryData();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> linkQuotation(String orderId, String quotationId) async {
    try {
      await _repository.linkQuotation(orderId, quotationId);
      await loadCarpentryData();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<DeliveryCapacityEntity> checkDeliveryCapacity(String date) {
    return _repository.getDeliveryCapacity(date);
  }

  Future<bool> scheduleDelivery({
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
      final created = await _repository.scheduleDelivery(
        orderId: orderId,
        scheduledDate: scheduledDate,
        timeSlot: timeSlot,
        address: address,
        notes: notes,
        deliveryType: deliveryType,
        latitude: latitude,
        longitude: longitude,
      );
      _deliveries = [created, ..._deliveries];
      pushNotification(
        title: 'Despacho programado',
        body:
            'Entrega del pedido #$orderId agendada para el $scheduledDate ($timeSlot) en $address.',
        orderId: orderId,
        status: created.status,
      );
      await loadCarpentryData();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDeliveryStatus(String id, String status) async {
    try {
      final updated = await _repository.updateDeliveryStatus(id, status);
      _deliveries = _deliveries.map((d) => d.id == id ? updated : d).toList();
      pushNotification(
        title: 'Estado de entrega actualizado',
        body:
            'El despacho hacia ${updated.address} cambió a estado: ${updated.statusLabel}.',
        orderId: updated.orderId,
        status: updated.status,
      );
      await loadCarpentryData();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rescheduleDelivery({
    required String id,
    required String newDate,
    String? timeSlot,
  }) async {
    try {
      final updated = await _repository.rescheduleDelivery(
        id: id,
        newDate: newDate,
        timeSlot: timeSlot,
      );
      _deliveries = _deliveries.map((d) => d.id == id ? updated : d).toList();
      pushNotification(
        title: 'Entrega reprogramada',
        body:
            'El despacho hacia ${updated.address} fue reprogramado para el $newDate.',
        orderId: updated.orderId,
        status: updated.status,
      );
      await loadCarpentryData();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Facturas y Recibos PDF ────────────────────────────────────────────────

  Future<bool> createManualInvoice({
    required String clientName,
    required String clientNit,
    String? clientEmail,
    String? orderId,
    required String description,
    required int quantity,
    required double unitPrice,
  }) async {
    try {
      final created = await _repository.createInvoice(
        clientName: clientName,
        clientNit: clientNit,
        clientEmail: clientEmail,
        orderId: orderId,
        items: [
          {
            'description': description,
            'quantity': quantity,
            'unit_price': unitPrice,
          }
        ],
      );
      _invoices = [created, ..._invoices];
      pushNotification(
        title: 'Factura oficial emitida',
        body:
            'Factura ${created.series}-${created.number} emitida para $clientName por Bs ${created.total.toStringAsFixed(2)}.',
      );
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List> downloadInvoicePdf(String invoiceId) {
    return _repository.downloadInvoicePdf(invoiceId);
  }

  // ── Pagos y Registro de Transacciones ─────────────────────────────────────

  Future<PaymentResultEntity?> processPayment({
    required String quotationId,
    required double amount,
    required String cardNumber,
    required String cardHolder,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
  }) async {
    try {
      final res = await _repository.processPayment(
        quotationId: quotationId,
        amount: amount,
        cardNumber: cardNumber,
        cardHolder: cardHolder,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvv: cvv,
      );
      pushNotification(
        title: 'Pago aprobado y factura emitida',
        body:
            'Transacción ${res.gatewayTransactionId} por Bs ${res.amount.toStringAsFixed(2)}',
        orderId: quotationId,
        status: 'CONVERTED',
      );
      await loadCarpentryData();
      return res;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<List<PaymentLogEntity>> getPaymentLogs(String paymentId) {
    return _repository.getPaymentLogs(paymentId);
  }

  // ── Asistente Inteligente y Reportes ──────────────────────────────────────

  Future<OnlineAgentReplyEntity> askOnlineAgent({
    required String query,
    String? sessionId,
  }) {
    return _repository.askOnlineAgent(query: query, sessionId: sessionId);
  }

  Future<OnlineNlReportEntity> generateOnlineReport(String query) async {
    final res = await _repository.generateOnlineReport(query);
    pushNotification(
      title: 'Informe ejecutivo generado',
      body:
          'Se generó el informe para "$query" (${res.rows.length} registros listos para exportar).',
    );
    return res;
  }

  Future<void> updateBackendUrl(String url) async {
    final normalized = AppConfig.normalizeBaseUrl(url);
    AppConfig.setCustomBaseUrl(normalized);
    await LocalStorage.saveCustomBaseUrl(normalized);
    await loadCarpentryData();
    if (isAuthenticated) {
      _startRealtimeServices();
    }
  }

  @override
  void dispose() {
    _stopRealtimeServices();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppProvider> {
  const AppScope({
    super.key,
    required AppProvider provider,
    required super.child,
  }) : super(notifier: provider);

  static AppProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!.notifier!;
  }
}
