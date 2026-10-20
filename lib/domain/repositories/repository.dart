import 'package:carpinteria_movil_sw2/domain/entities/entity.dart';

abstract class CarpentryRepository {
  bool get isUsingMock;

  Future<UserEntity> login({
    required String email,
    required String password,
  });

  Future<UserEntity> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  });

  Future<void> logout();

  Future<UserEntity?> getSavedSession();

  Future<List<ProductEntity>> getProducts();

  Future<List<OrderEntity>> getOrders();

  Future<OrderEntity> createOrder({
    required String clientName,
    required String productName,
    required String woodType,
    required String specifications,
    required double totalAmount,
    required double advancePayment,
    required String deliveryDate,
  });

  Future<OrderEntity> updateOrderStatus(String orderId, String newStatus);

  Future<List<WoodMaterialEntity>> getMaterials();
}
