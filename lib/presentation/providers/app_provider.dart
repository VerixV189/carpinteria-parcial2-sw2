import 'package:flutter/material.dart';
import 'package:carpinteria_movil_sw2/core/config/app_config.dart';
import 'package:carpinteria_movil_sw2/core/storage/local_storage.dart';
import 'package:carpinteria_movil_sw2/core/storage/sqlite_database.dart';
import 'package:carpinteria_movil_sw2/data/repositories/repository_impl.dart';
import 'package:carpinteria_movil_sw2/domain/entities/entity.dart';
import 'package:carpinteria_movil_sw2/domain/repositories/repository.dart';

class AppProvider extends ChangeNotifier {
  final CarpentryRepository _repository;

  UserEntity? _currentUser;
  List<ProductEntity> _products = [];
  List<OrderEntity> _orders = [];
  List<WoodMaterialEntity> _materials = [];
  final List<CartItemEntity> _cart = [];

  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'Todos';
  String _searchQuery = '';

  AppProvider({CarpentryRepository? repository})
      : _repository = repository ?? CarpentryRepositoryImpl();

  UserEntity? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isClientRole =>
      (_currentUser?.role.toLowerCase() ?? 'cliente') == 'cliente';
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

  /// Solo muebles disponibles a la venta (stock > 0) para el Marketplace del cliente
  List<ProductEntity> get availableMarketplaceProducts {
    return filteredProducts.where((p) => p.stock > 0).toList();
  }

  List<ProductEntity> get allProducts => _products;
  List<OrderEntity> get orders => _orders;
  List<WoodMaterialEntity> get materials => _materials;

  /// Pedidos y cotizaciones que pertenecen exclusivamente al cliente actual
  List<OrderEntity> get clientOrders {
    final userName = (_currentUser?.name ?? '').trim().toLowerCase();
    if (userName.isEmpty) return [];
    return _orders
        .where((o) => o.clientName.trim().toLowerCase() == userName)
        .toList();
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
  }) async {
    if (_cart.isEmpty) return false;
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
        '${estDate.day.toString().padLeft(2, '0')}/${estDate.month.toString().padLeft(2, '0')}/${estDate.year}';

    final ok = await createOrder(
      clientName: clientName,
      productName: summaryNames,
      woodType: woods,
      specifications: deliveryNotes.isEmpty
          ? 'Compra desde Marketplace Móvil'
          : deliveryNotes,
      totalAmount: total,
      advancePayment: advancePayment,
      deliveryDate: dateStr,
    );
    if (ok) {
      _cart.clear();
      notifyListeners();
    }
    return ok;
  }

  // ── Sesión y Datos ────────────────────────────────────────────────────────

  Future<void> initializeSession() async {
    await LocalStorage.init();
    final savedUrl = LocalStorage.getCustomBaseUrl();
    if (savedUrl != null && savedUrl.isNotEmpty) {
      AppConfig.setCustomBaseUrl(savedUrl);
    }
    _currentUser = await _repository.getSavedSession();
    if (_currentUser != null) {
      await loadCarpentryData();
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _repository.login(email: email, password: password);
      await loadCarpentryData();
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
      await loadCarpentryData();
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
    await _repository.logout();
    _currentUser = null;
    _cart.clear();
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
      ]);
      _products = results[0] as List<ProductEntity>;
      _orders = results[1] as List<OrderEntity>;
      _materials = results[2] as List<WoodMaterialEntity>;
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

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> createOrder({
    required String clientName,
    required String productName,
    required String woodType,
    required String specifications,
    required double totalAmount,
    required double advancePayment,
    required String deliveryDate,
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
      );
      _orders = [created, ..._orders];
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
        await SqliteDatabase.syncAll(
          products: _products,
          orders: _orders,
          materials: _materials,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> updateBackendUrl(String url) async {
    AppConfig.setCustomBaseUrl(url);
    await LocalStorage.saveCustomBaseUrl(url);
    await loadCarpentryData();
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
