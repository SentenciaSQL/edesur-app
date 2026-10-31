import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/app_controller.dart';
import '../../core/mock/catalogs.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/entities.dart';
import '../../domain/logic/selectors.dart';
import '../../shared/widgets/common.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final value = text.trim();
    if (value.isEmpty || _typing) return;
    _controller.clear();
    setState(() => _typing = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await runDemoAction(context, () => ref.read(appControllerProvider.notifier).sendAssistantMessage(value));
    if (mounted) {
      setState(() => _typing = false);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    }
  }

  void _open(AssistantLink link) {
    final snapshot = ref.read(appControllerProvider).requireValue;
    switch (link) {
      case AssistantLink.pay:
        final invoice = snapshot.payableInvoice;
        if (invoice == null) {
          showAppMessage(context, 'No tienes balance pendiente.');
          context.go(Routes.invoices);
        } else {
          context.push(Routes.pay(invoice.id));
        }
      case AssistantLink.invoices:
        context.go(Routes.invoices);
      case AssistantLink.consumption:
        context.push(Routes.consumption);
      case AssistantLink.reportOutage:
        context.push(Routes.reportOutage);
      case AssistantLink.requests:
        context.go(Routes.requests);
      case AssistantLink.offices:
        context.push(Routes.offices);
      case AssistantLink.contact:
        context.push(Routes.contact);
      case AssistantLink.notifications:
        context.push(Routes.notifications);
      case AssistantLink.map:
        context.push(Routes.map);
      case AssistantLink.contracts:
        context.push(Routes.contracts);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(appControllerProvider).value?.messages ?? const <ChatMessage>[];
    return FeatureScaffold(
      title: 'Asistente EDESUR',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Respuestas locales. No se consulta ningún modelo de inteligencia artificial.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                for (final message in messages) _Bubble(message: message, onAction: _open),
                if (_typing)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Escribiendo...', style: TextStyle(color: AppColors.muted, fontStyle: FontStyle.italic)),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final suggestion in assistantSuggestions)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(label: Text(suggestion), onPressed: () => _send(suggestion)),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: const InputDecoration(hintText: 'Escribe tu pregunta'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: () => _send(_controller.text), icon: const Icon(Icons.send_rounded)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.onAction});
  final ChatMessage message;
  final ValueChanged<AssistantLink> onAction;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromUser;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: mine ? AppColors.navy : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: mine ? null : Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text, style: TextStyle(color: mine ? Colors.white : AppColors.ink, height: 1.35)),
            if (message.actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final action in message.actions)
                    ActionChip(
                      label: Text(action.label),
                      onPressed: () => onAction(action.link),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
