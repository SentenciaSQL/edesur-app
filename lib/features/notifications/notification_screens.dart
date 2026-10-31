import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/app_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import '../../domain/logic/selectors.dart';
import '../../shared/widgets/common.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SnapshotBody(
      builder: (context, snapshot) {
        final items = [...snapshot.notifications]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return FeatureScaffold(
          title: 'Notificaciones',
          actions: [
            TextButton(
              onPressed: snapshot.unreadCount == 0
                  ? null
                  : () => ref.read(appControllerProvider.notifier).markAllNotificationsRead(),
              child: const Text('Marcar leídas'),
            ),
          ],
          body: items.isEmpty
              ? const EmptyState(title: 'Sin avisos', message: 'Los avisos de demostración aparecerán aquí.')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return AppCard(
                      color: item.read ? AppColors.white : AppColors.orangeSoft,
                      onTap: () async {
                        await ref.read(appControllerProvider.notifier).markNotificationRead(item.id);
                        if (context.mounted) context.push('/notificaciones/${item.id}');
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_icon(item.kind), color: item.read ? AppColors.muted : AppColors.orangeDark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                                Text(formatDateTime(item.createdAt), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  IconData _icon(NotificationKind kind) => switch (kind) {
        NotificationKind.invoiceReady => Icons.receipt_long,
        NotificationKind.dueReminder => Icons.event,
        NotificationKind.paymentDone => Icons.paid,
        NotificationKind.reportReceived => Icons.flag,
        NotificationKind.outageUpdate => Icons.bolt,
        NotificationKind.plannedOutage => Icons.campaign,
        NotificationKind.announcement => Icons.info_outline,
        NotificationKind.requestUpdate => Icons.assignment,
      };
}

class NotificationDetailScreen extends ConsumerWidget {
  const NotificationDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SnapshotBody(
      builder: (context, snapshot) {
        AppNotification? item;
        for (final notification in snapshot.notifications) {
          if (notification.id == id) item = notification;
        }
        if (item == null) {
          return const FeatureScaffold(title: 'Aviso', body: EmptyState(title: 'Aviso no disponible', message: 'Puede haber cambiado con el escenario.'));
        }
        final notice = item;
        return FeatureScaffold(
          title: 'Detalle',
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(notice.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
              const SizedBox(height: 6),
              Text(formatDateTime(notice.createdAt), style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 12),
              Text(notice.body, style: const TextStyle(fontSize: 16, height: 1.4)),
              const SizedBox(height: 16),
              if (notice.route != null)
                FilledButton(
                  onPressed: () => context.push(notice.route!),
                  child: const Text('Abrir relacionado'),
                ),
              TextButton(
                onPressed: () => ref.read(appControllerProvider.notifier).markNotificationRead(notice.id),
                child: Text(notice.read ? 'Leída' : 'Marcar como leída'),
              ),
            ],
          ),
        );
      },
    );
  }
}
