import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:carpinteria_movil_sw2/core/config/app_config.dart';
import 'package:carpinteria_movil_sw2/core/storage/local_storage.dart';
import 'package:carpinteria_movil_sw2/domain/entities/entity.dart';

class RealtimeNotificationService {
  WebSocket? _socketIoWs;
  WebSocket? _graphqlWs;
  Timer? _reconnectTimer;
  bool _disposed = false;

  final void Function(AppNotificationEntity notification) onNotification;

  RealtimeNotificationService({required this.onNotification});

  Future<void> connect({required bool includeGraphqlSubscription}) async {
    _disposed = false;
    await disconnect(keepFlag: true);
    _connectSocketIo();
    if (includeGraphqlSubscription) {
      _connectGraphqlWs();
    }
  }

  Future<void> _connectSocketIo() async {
    if (_disposed) return;
    try {
      final wsUrl = '${AppConfig.wsBaseUrl}/ws/?EIO=4&transport=websocket';
      final token = LocalStorage.getToken();
      _socketIoWs = await WebSocket.connect(
        wsUrl,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 6));

      _socketIoWs!.listen(
        (dynamic raw) {
          if (raw is! String) return;
          // Engine.IO v4 / Socket.IO v4 protocol handling
          if (raw.startsWith('0')) {
            // Open packet -> send Socket.IO namespace connect
            _socketIoWs?.add('40');
          } else if (raw == '2') {
            // Ping -> Pong
            _socketIoWs?.add('3');
          } else if (raw.startsWith('42')) {
            // Event packet: 42["orderStatusChanged", {...}]
            final jsonPart = raw.substring(2);
            try {
              final decoded = jsonDecode(jsonPart);
              if (decoded is List && decoded.length >= 2) {
                final eventName = decoded[0].toString();
                final payload = decoded[1];
                if (eventName == 'orderStatusChanged' && payload is Map) {
                  final id = (payload['id'] ?? payload['orderId'] ?? '').toString();
                  final rawStat = (payload['status'] ?? '').toString();
                  final spanStat = OrderEntity.toSpanishStatus(rawStat);
                  final desc = (payload['description'] ?? 'Pedido #$id').toString();
                  onNotification(
                    AppNotificationEntity(
                      id: 'WS-${DateTime.now().millisecondsSinceEpoch}',
                      title: 'Actualización de Pedido #$id',
                      body: '$desc cambió a estado: $spanStat',
                      orderId: id,
                      status: spanStat,
                      timestamp: DateTime.now(),
                    ),
                  );
                }
              }
            } catch (_) {}
          }
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  Future<void> _connectGraphqlWs() async {
    if (_disposed) return;
    try {
      final wsUrl = '${AppConfig.wsBaseUrl}/subscriptions';
      final token = LocalStorage.getToken();
      _graphqlWs = await WebSocket.connect(
        wsUrl,
        protocols: ['graphql-transport-ws'],
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 6));

      _graphqlWs!.add(jsonEncode({
        'type': 'connection_init',
        'payload': {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      }));

      _graphqlWs!.listen(
        (dynamic raw) {
          if (raw is! String) return;
          try {
            final msg = jsonDecode(raw);
            if (msg is! Map<String, dynamic>) return;
            final type = msg['type'];
            if (type == 'connection_ack') {
              _graphqlWs?.add(jsonEncode({
                'id': 'sub-orders-1',
                'type': 'subscribe',
                'payload': {
                  'query':
                      'subscription { orderStatusChanged { id status description totalAmount client { name } } }',
                },
              }));
            } else if (type == 'ping') {
              _graphqlWs?.add(jsonEncode({'type': 'pong'}));
            } else if (type == 'next') {
              final data = msg['payload']?['data']?['orderStatusChanged'];
              if (data is Map) {
                final id = (data['id'] ?? '').toString();
                final rawStat = (data['status'] ?? '').toString();
                final spanStat = OrderEntity.toSpanishStatus(rawStat);
                final clientName =
                    (data['client']?['name'] ?? 'Cliente').toString();
                onNotification(
                  AppNotificationEntity(
                    id: 'GQL-${DateTime.now().millisecondsSinceEpoch}',
                    title: 'Pedido #$id ($clientName)',
                    body: 'Nuevo estado en taller: $spanStat',
                    orderId: id,
                    status: spanStat,
                    timestamp: DateTime.now(),
                  ),
                );
              }
            }
          } catch (_) {}
        },
        onDone: () {},
        onError: (_) {},
      );
    } catch (_) {}
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 15), () {
      if (!_disposed) {
        _connectSocketIo();
      }
    });
  }

  Future<void> disconnect({bool keepFlag = false}) async {
    if (!keepFlag) _disposed = true;
    _reconnectTimer?.cancel();
    try {
      await _socketIoWs?.close();
    } catch (_) {}
    try {
      await _graphqlWs?.close();
    } catch (_) {}
    _socketIoWs = null;
    _graphqlWs = null;
  }
}
