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
      // Fallback híbrido cuando el backend aún no está levantado
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
    if (token != null && token.startsWith('mock-jwt-token')) {
      _isUsingMock = true;
    }
    return UserModel.fromJson(json, tokenOverride: token);
  }

  @override
  Future<List<ProductEntity>> getProducts() async {
    try {
      final list = await _remote.getProducts();
      _isUsingMock = false;
      return list.isNotEmpty ? list : _local.getProducts();
    } catch (_) {
      _isUsingMock = true;
      return _local.getProducts();
    }
  }

  @override
  Future<List<OrderEntity>> getOrders() async {
    try {
      final list = await _remote.getOrders();
      _isUsingMock = false;
      return list.isNotEmpty ? list : _local.getOrders();
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
  }) async {
    final payload = {
      'cliente_nombre': clientName,
      'producto_nombre': productName,
      'tipo_madera': woodType,
      'especificaciones': specifications,
      'monto_total': totalAmount,
      'adelanto': advancePayment,
      'fecha_entrega': deliveryDate,
      'estado': 'Pendiente',
    };
    try {
      final created = await _remote.createOrder(payload);
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
      _isUsingMock = true;
      return _local.updateOrderStatus(orderId, newStatus);
    }
  }

  @override
  Future<List<WoodMaterialEntity>> getMaterials() async {
    try {
      final list = await _remote.getMaterials();
      _isUsingMock = false;
      return list.isNotEmpty ? list : _local.getMaterials();
    } catch (_) {
      _isUsingMock = true;
      return _local.getMaterials();
    }
  }
}
