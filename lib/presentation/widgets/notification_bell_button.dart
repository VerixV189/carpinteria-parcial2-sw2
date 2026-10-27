import 'package:flutter/material.dart';
import 'package:carpinteria_movil_sw2/presentation/providers/app_provider.dart';
import 'package:carpinteria_movil_sw2/theme/app_theme.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  void _showNotificationsSheet(BuildContext context, AppProvider provider) {
    provider.markAllNotificationsRead();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.warmCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final list = provider.notifications;
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.notifications_active_rounded,
                        color: AppTheme.primaryWood,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Notificaciones en Tiempo Real',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDarkWood,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text(
                'Conectado a WebSocket (/ws • /subscriptions) y sincronización de estados.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const Divider(height: 20),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 48,
                        color: Colors.black38,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sin notificaciones recientes.\nAquí verás cambios de estado de pedidos, cotizaciones y pagos al instante.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final n = list[i];
                      final timeStr =
                          '${n.timestamp.hour.toString().padLeft(2, '0')}:${n.timestamp.minute.toString().padLeft(2, '0')}';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppTheme.primaryWood.withValues(alpha: 0.14),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: AppTheme.primaryWood,
                            ),
                          ),
                          title: Text(
                            n.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          subtitle: Text(
                            n.body,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                          trailing: Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context);
    final unread = provider.unreadNotificationsCount;
    final latestToast = provider.latestToastNotification;

    if (latestToast != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.clearLatestToast();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.primaryDarkWood,
              content: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_rounded,
                    color: AppTheme.accentAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          latestToast.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          latestToast.body,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    }

    return IconButton(
      tooltip: 'Notificaciones en tiempo real',
      onPressed: () => _showNotificationsSheet(context, provider),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        backgroundColor: AppTheme.accentAmber,
        textColor: Colors.black87,
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
