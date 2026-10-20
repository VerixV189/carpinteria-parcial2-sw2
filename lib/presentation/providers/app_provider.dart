import 'package:flutter/material.dart';
import 'package:carpinteria_movil_sw2/core/config/app_config.dart';
import 'package:carpinteria_movil_sw2/core/storage/local_storage.dart';
import 'package:carpinteria_movil_sw2/data/repositories/repository_impl.dart';
import 'package:carpinteria_movil_sw2/domain/entities/entity.dart';
import 'package:carpinteria_movil_sw2/domain/repositories/repository.dart';

class AppProvider extends ChangeNotifier {
  final CarpentryRepository _repository;

  UserEntity? _currentUser;
  List<ProductEntity> _products = [];
  List<OrderEntity> _orders = [];
  List<WoodMaterialEntity> _materials = [];

  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'Todos';
  String _searchQuery = '';

  AppProvider({CarpentryRepository? repository})
      : _repository = repository ?? CarpentryRepositoryImpl();

  UserEntity? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
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

  List<ProductEntity> get allProducts => _products;
  List<OrderEntity> get orders => _orders;
  List<WoodMaterialEntity> get materials => _materials;

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
