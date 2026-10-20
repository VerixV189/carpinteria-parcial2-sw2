import 'package:carpinteria_movil_sw2/core/constants/api_constants.dart';
import 'package:carpinteria_movil_sw2/core/network/api_client.dart';
import 'package:carpinteria_movil_sw2/data/models/model.dart';

class ApiDataSource {
  final ApiClient _apiClient;

  ApiDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<UserModel> login(String email, String password) async {
    final res = await _apiClient.post(
      ApiConstants.login,
      withAuth: false,
      body: {
        'email': email,
        'password': password,
      },
    );
    return UserModel.fromJson(res as Map<String, dynamic>);
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final res = await _apiClient.post(
      ApiConstants.register,
      withAuth: false,
      body: {
        'nombre': name,
        'name': name,
        'email': email,
        'telefono': phone,
        'phone': phone,
        'password': password,
        'rol': role,
        'role': role,
      },
    );
    return UserModel.fromJson(res as Map<String, dynamic>);
  }

  Future<List<ProductModel>> getProducts() async {
    final res = await _apiClient.get(ApiConstants.products);
    final list = _extractList(res);
    return list
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OrderModel>> getOrders() async {
    final res = await _apiClient.get(ApiConstants.orders);
    final list = _extractList(res);
    return list
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderModel> createOrder(Map<String, dynamic> payload) async {
    final res = await _apiClient.post(ApiConstants.orders, body: payload);
    final map = (res is Map && res['data'] is Map)
        ? res['data'] as Map<String, dynamic>
        : res as Map<String, dynamic>;
    return OrderModel.fromJson(map);
  }

  Future<OrderModel> updateOrderStatus(String orderId, String newStatus) async {
    final res = await _apiClient.put(
      '${ApiConstants.orders}/$orderId',
      body: {'estado': newStatus, 'status': newStatus},
    );
    final map = (res is Map && res['data'] is Map)
        ? res['data'] as Map<String, dynamic>
        : res as Map<String, dynamic>;
    return OrderModel.fromJson(map);
  }

  Future<List<WoodMaterialModel>> getMaterials() async {
    final res = await _apiClient.get(ApiConstants.materials);
    final list = _extractList(res);
    return list
        .map((e) => WoodMaterialModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<dynamic> _extractList(dynamic res) {
    if (res is List) return res;
    if (res is Map<String, dynamic>) {
      if (res['data'] is List) return res['data'] as List<dynamic>;
      if (res['items'] is List) return res['items'] as List<dynamic>;
      if (res['results'] is List) return res['results'] as List<dynamic>;
    }
    return [];
  }
}
