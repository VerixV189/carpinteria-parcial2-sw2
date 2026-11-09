import 'package:flutter/material.dart';
import 'package:carpinteria_movil_sw2/core/config/app_config.dart';
import 'package:carpinteria_movil_sw2/domain/entities/entity.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/client/client_home_page.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/voice_report_page.dart';
import 'package:carpinteria_movil_sw2/presentation/providers/app_provider.dart';
import 'package:carpinteria_movil_sw2/presentation/widgets/notification_bell_button.dart';
import 'package:carpinteria_movil_sw2/presentation/widgets/payment_and_invoice_modals.dart';
import 'package:carpinteria_movil_sw2/routes/app_router.dart';
import 'package:carpinteria_movil_sw2/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  void _showCreateOrderModal(BuildContext context, {ProductEntity? preselected}) {
    final provider = AppScope.of(context);
    final clientCtrl = TextEditingController(
      text: provider.clients.isNotEmpty ? provider.clients.first.name : '',
    );
    final productCtrl = TextEditingController(text: preselected?.name ?? '');
    final woodCtrl = TextEditingController(text: preselected?.woodType ?? 'Roble');
    final specsCtrl = TextEditingController(
      text: preselected != null ? 'Dimensiones: ${preselected.dimensions}' : '',
    );
    final totalCtrl = TextEditingController(
      text: preselected != null ? preselected.price.toStringAsFixed(0) : '',
    );
    final advanceCtrl = TextEditingController(
      text: preselected != null ? (preselected.price * 0.5).toStringAsFixed(0) : '',
    );
    final dateCtrl = TextEditingController(text: '2026-11-05');
    final addressCtrl = TextEditingController(
      text: 'Av. Cristo Redentor 4to Anillo, Santa Cruz',
    );
    String deliveryType = 'DELIVERY';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.warmCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nuevo Pedido de Producción',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDarkWood,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: clientCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Cliente',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: productCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Mueble / Trabajo solicitado',
                          prefixIcon: Icon(Icons.chair_outlined),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: woodCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Madera',
                                prefixIcon: Icon(Icons.forest_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: dateCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Fecha (YYYY-MM-DD)',
                                prefixIcon: Icon(Icons.event_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: totalCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Total (Bs)',
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Requerido'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: advanceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Adelanto (Bs)',
                                prefixIcon: Icon(Icons.payments_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Envío a domicilio'),
                            selected: deliveryType == 'DELIVERY',
                            onSelected: (_) =>
                                setModalState(() => deliveryType = 'DELIVERY'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Recojo en taller'),
                            selected: deliveryType == 'PICKUP',
                            onSelected: (_) =>
                                setModalState(() => deliveryType = 'PICKUP'),
                          ),
                        ],
                      ),
                      if (deliveryType == 'DELIVERY') ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: addressCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Dirección de entrega',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: specsCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Medidas, tono de barniz y detalles',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final messenger = ScaffoldMessenger.of(this.context);
                          await provider.createOrder(
                            clientName: clientCtrl.text.trim(),
                            productName: productCtrl.text.trim(),
                            woodType: woodCtrl.text.trim(),
                            specifications: specsCtrl.text.trim(),
                            totalAmount: double.tryParse(totalCtrl.text) ?? 0.0,
                            advancePayment:
                                double.tryParse(advanceCtrl.text) ?? 0.0,
                            deliveryDate: dateCtrl.text.trim(),
                            deliveryType: deliveryType,
                            deliveryAddress: deliveryType == 'DELIVERY'
                                ? addressCtrl.text.trim()
                                : 'Recojo en taller',
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            setState(() => _currentIndex = 0);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pedido de producción registrado exitosamente',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Registrar Pedido'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context);
    if (provider.isClientRole) {
      return const ClientHomePage();
    }
    final user = provider.currentUser;
    final roleTag = provider.isAdminRole ? 'Administración' : 'Taller Central';

    final titles = [
      'Taller y Órdenes de Producción',
      'Cotizaciones y Logística de Entregas',
      'Clientes, Personal y Facturación',
      'Asistente IA y Reportes',
      'Mi Perfil',
    ];

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo_el_roble.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titles[_currentIndex],
              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
            ),
            Text(
              'Carpintería El Roble • $roleTag',
              style: TextStyle(
                fontSize: 11,
                color: provider.isUsingMock
                    ? AppTheme.accentAmber
                    : Colors.greenAccent,
              ),
            ),
          ],
        ),
        actions: [
          const NotificationBellButton(),
          IconButton(
            tooltip: 'Actualizar datos',
            onPressed: provider.loadCarpentryData,
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _WorkshopAndOrdersTab(
            onAddOrder: () => _showCreateOrderModal(context),
          ),
          const _QuotesAndDeliveriesTab(),
          _ManagementAndCatalogTab(
            onOrderProduct: (p) =>
                _showCreateOrderModal(context, preselected: p),
          ),
          const VoiceReportPage(),
          _ProfileTab(user: user),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryWood,
              foregroundColor: Colors.white,
              onPressed: () => _showCreateOrderModal(context),
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Nuevo Pedido'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.precision_manufacturing_outlined),
            selectedIcon: Icon(Icons.precision_manufacturing_rounded),
            label: 'Taller/Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping_rounded),
            label: 'Cotiz./Envíos',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings_rounded),
            label: 'Gestión/PDF',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none_rounded),
            selectedIcon: Icon(Icons.mic_rounded),
            label: 'Voz IA',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ── TAB 1: TALLER Y ÓRDENES DE PRODUCCIÓN ───────────────────────────────────

class _WorkshopAndOrdersTab extends StatelessWidget {
  final VoidCallback onAddOrder;

  const _WorkshopAndOrdersTab({required this.onAddOrder});

  Color _statusColor(String status) {
    switch (status) {
      case 'En fabricación':
        return Colors.blue.shade700;
      case 'Aprobado':
        return Colors.indigo.shade700;
      case 'Listo':
        return Colors.green.shade700;
      case 'Entregado':
        return Colors.teal.shade700;
      case 'Cancelado':
        return Colors.red.shade700;
      default:
        return Colors.orange.shade800;
    }
  }

  void _showAssignCarpenterDialog(BuildContext context, OrderEntity order) {
    final provider = AppScope.of(context);
    final carpenters = provider.carpenters;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Asignar Carpintero a Pedido #${order.id}'),
        content: carpenters.isEmpty
            ? const Text('No hay carpinteros registrados.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: carpenters
                    .map(
                      (c) => ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.primaryWood,
                          child: Icon(Icons.handyman, color: Colors.white, size: 18),
                        ),
                        title: Text(c.name),
                        subtitle: Text('${c.specialty} • Bs ${c.hourlyRate.toStringAsFixed(0)}/h'),
                        onTap: () async {
                          await provider.assignCarpenter(order.id, c.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    )
                    .toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context);
    final orders = provider.orders;
    final inProdCount =
        orders.where((o) => o.rawStatus == 'IN_PRODUCTION').length;
    final readyCount = orders.where((o) => o.rawStatus == 'READY').length;
    final draftQuotesCount = provider.quotations
        .where((q) => q.status.toUpperCase() == 'DRAFT')
        .length;

    // Buscar el siguiente paso de producción activo
    OrderEntity? nextStepOrder;
    ProductionStepEntity? nextStep;
    for (final o in orders) {
      for (final s in o.steps) {
        if (!s.isCompleted) {
          nextStepOrder = o;
          nextStep = s;
          break;
        }
      }
      if (nextStep != null) break;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 84),
      children: [
        // ── KPIs Rápidos del Taller ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primaryDarkWood,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              _StatBadge(
                label: 'Pedidos',
                value: '${orders.length}',
                icon: Icons.assignment_outlined,
              ),
              const SizedBox(width: 8),
              _StatBadge(
                label: 'En Taller',
                value: '$inProdCount',
                icon: Icons.handyman_rounded,
              ),
              const SizedBox(width: 8),
              _StatBadge(
                label: 'Listos',
                value: '$readyCount',
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(width: 8),
              _StatBadge(
                label: 'Por Cotizar',
                value: '$draftQuotesCount',
                icon: Icons.request_quote_outlined,
                highlight: draftQuotesCount > 0,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Tarjeta "Siguiente Paso en Taller" ───────────────────────────────
        if (nextStep != null && nextStepOrder != null)
          Card(
            color: Colors.amber.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.amber.shade400),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppTheme.primaryWood,
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu siguiente paso en taller (Pedido #${nextStepOrder.id}):',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                        Text(
                          '${nextStep.sequence}. ${nextStep.name}',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDarkWood,
                          ),
                        ),
                        Text(
                          '${nextStepOrder.productName} • Cliente: ${nextStepOrder.clientName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () {
                      final nextStatus =
                          nextStep!.isInProgress ? 'COMPLETED' : 'IN_PROGRESS';
                      provider.updateStepStatus(nextStep.id, nextStatus);
                    },
                    child: Text(
                      nextStep.isInProgress ? 'Terminar' : 'Empezar',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 10),
        const Text(
          'Órdenes de Trabajo, Pasos de Producción y Asignación',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDarkWood,
          ),
        ),
        const SizedBox(height: 8),

        if (orders.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('No hay pedidos registrados aún'),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: onAddOrder,
                    icon: const Icon(Icons.add),
                    label: const Text('Crear primer pedido'),
                  ),
                ],
              ),
            ),
          )
        else
          ...orders.map((order) {
            final color = _statusColor(order.status);
            final pendingBalance = order.totalAmount - order.advancePayment;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Pedido #${order.id} • ${order.deliveryType == "PICKUP" ? "Recojo en taller" : "Envío a domicilio"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (newStatus) {
                            provider.updateOrderStatus(order.id, newStatus);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'PENDING',
                              child: Text('Estado: Pendiente'),
                            ),
                            PopupMenuItem(
                              value: 'APPROVED',
                              child: Text('Estado: Aprobado'),
                            ),
                            PopupMenuItem(
                              value: 'IN_PRODUCTION',
                              child: Text('Estado: En fabricación'),
                            ),
                            PopupMenuItem(
                              value: 'READY',
                              child: Text('Estado: Listo para entrega'),
                            ),
                            PopupMenuItem(
                              value: 'DELIVERED',
                              child: Text('Estado: Entregado'),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: color.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  order.status,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.edit_outlined, size: 13, color: color),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.productName,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDarkWood,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cliente: ${order.clientName} • Madera: ${order.woodType} • Entrega: ${order.deliveryDate}',
                      style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                    ),
                    if (order.deliveryAddress.isNotEmpty)
                      Text(
                        'Dirección: ${order.deliveryAddress}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),

                    // Carpinteros asignados
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            order.carpenters.isEmpty
                                ? 'Carpintero: Sin asignar'
                                : 'Carpintero(s): ${order.carpenters.map((c) => c.name).join(", ")}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryWood,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              _showAssignCarpenterDialog(context, order),
                          icon: const Icon(Icons.person_add_alt_1, size: 15),
                          label: const Text(
                            'Asignar',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),

                    // Pasos de producción
                    if (order.steps.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: order.stepsProgress,
                          minHeight: 6,
                          backgroundColor: Colors.brown.shade100,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...order.steps.map((step) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                step.isCompleted
                                    ? Icons.check_circle
                                    : (step.isInProgress
                                        ? Icons.timelapse
                                        : Icons.radio_button_unchecked),
                                size: 17,
                                color: step.isCompleted
                                    ? Colors.green.shade700
                                    : (step.isInProgress
                                        ? Colors.blue.shade700
                                        : Colors.grey),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${step.sequence}. ${step.name}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    decoration: step.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              if (!step.isCompleted)
                                InkWell(
                                  onTap: () {
                                    final next = step.isInProgress
                                        ? 'COMPLETED'
                                        : 'IN_PROGRESS';
                                    provider.updateStepStatus(step.id, next);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryWood
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      step.isInProgress ? 'Terminar' : 'Empezar',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryWood,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _AmountColumn(
                          label: 'Total',
                          amount: order.totalAmount,
                          color: AppTheme.primaryDarkWood,
                        ),
                        _AmountColumn(
                          label: 'Pagado/Adelanto',
                          amount: order.advancePayment,
                          color: Colors.green.shade700,
                        ),
                        _AmountColumn(
                          label: 'Saldo',
                          amount: pendingBalance,
                          color: pendingBalance > 0
                              ? Colors.red.shade700
                              : Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ── TAB 2: COTIZACIONES DEL TALLER Y LOGÍSTICA DE ENTREGAS ──────────────────

class _QuotesAndDeliveriesTab extends StatefulWidget {
  const _QuotesAndDeliveriesTab();

  @override
  State<_QuotesAndDeliveriesTab> createState() =>
      _QuotesAndDeliveriesTabState();
}

class _QuotesAndDeliveriesTabState extends State<_QuotesAndDeliveriesTab> {
  int _subTab = 0; // 0 = Cotizaciones, 1 = Entregas
  DeliveryCapacityEntity? _capacityInfo;

  void _showSendFormalQuoteDialog(BuildContext context, QuotationEntity q) {
    final priceCtrl = TextEditingController(
      text: (q.counterAmount ?? q.payableAmount).toStringAsFixed(0),
    );
    final notesCtrl = TextEditingController(
      text: q.notes ?? 'Incluye barnizado en poliuretano y garantía de 1 año.',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar Cotización Formal al Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              q.description,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            if (q.counterAmount != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Contraoferta del cliente: Bs ${q.counterAmount!.toStringAsFixed(0)} ("${q.clientMessage ?? ""}")',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Precio Formal Final (Bs)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Condiciones / Tiempo de entrega',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = AppScope.of(context);
              final amount =
                  double.tryParse(priceCtrl.text) ?? q.payableAmount;
              await provider.sendQuotationFormalPrice(
                id: q.id,
                finalAmount: amount,
                notes: notesCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Enviar Precio al Cliente'),
          ),
        ],
      ),
    );
  }

  void _showScheduleDeliveryDialog(BuildContext context) {
    final provider = AppScope.of(context);
    final orders = provider.orders;
    String selectedOrderId = orders.isNotEmpty ? orders.first.id : '1';
    final dateCtrl = TextEditingController(text: '2026-10-30');
    final addressCtrl = TextEditingController(
      text: orders.isNotEmpty && orders.first.deliveryAddress.isNotEmpty
          ? orders.first.deliveryAddress
          : 'Av. Cristo Redentor 4to Anillo',
    );
    final notesCtrl = TextEditingController(text: 'Llamar al cliente antes de salir');
    String timeSlot = 'MORNING';
    String deliveryType = 'DELIVERY';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Programar Entrega'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (orders.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: selectedOrderId,
                    decoration: const InputDecoration(labelText: 'Pedido'),
                    items: orders
                        .map(
                          (o) => DropdownMenuItem(
                            value: o.id,
                            child: Text(
                              '#${o.id} - ${o.clientName}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedOrderId = v);
                    },
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Fecha Programada (YYYY-MM-DD)',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: timeSlot,
                  decoration: const InputDecoration(labelText: 'Franja Horaria'),
                  items: const [
                    DropdownMenuItem(
                      value: 'MORNING',
                      child: Text('Mañana (08:00 - 12:00)'),
                    ),
                    DropdownMenuItem(
                      value: 'AFTERNOON',
                      child: Text('Tarde (14:00 - 18:00)'),
                    ),
                    DropdownMenuItem(
                      value: 'EVENING',
                      child: Text('Noche (18:00 - 20:00)'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => timeSlot = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección o Punto de Entrega',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notas logísticas',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await provider.scheduleDelivery(
                  orderId: selectedOrderId,
                  scheduledDate: dateCtrl.text.trim(),
                  timeSlot: timeSlot,
                  address: addressCtrl.text.trim(),
                  notes: notesCtrl.text.trim(),
                  deliveryType: deliveryType,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar Entrega'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context);
    final quotations = provider.quotations;
    final deliveries = provider.deliveries;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Text(
                    'Cotizaciones (${quotations.length})',
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: _subTab == 0,
                  selectedColor: AppTheme.primaryWood,
                  labelStyle: TextStyle(
                    color: _subTab == 0 ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  onSelected: (_) => setState(() => _subTab = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Text(
                    'Entregas (${deliveries.length})',
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: _subTab == 1,
                  selectedColor: AppTheme.primaryWood,
                  labelStyle: TextStyle(
                    color: _subTab == 1 ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  onSelected: (_) => setState(() => _subTab = 1),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _subTab == 0
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: quotations.length,
                  itemBuilder: (context, index) {
                    final q = quotations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Cliente: ${q.clientId}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  flex: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryWood
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.primaryWood
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Text(
                                      q.statusLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryDarkWood,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              q.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.primaryDarkWood,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Madera: ${q.woodType} • Estimado IA: Bs ${q.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12.5),
                            ),
                            if (q.counterAmount != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Contraoferta Cliente: Bs ${q.counterAmount!.toStringAsFixed(0)} — "${q.clientMessage ?? ""}"',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            const Divider(height: 18),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: () =>
                                      _showSendFormalQuoteDialog(context, q),
                                  icon: const Icon(Icons.price_change, size: 16),
                                  label: const Text(
                                    'Cotizar /Responder',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => provider.approveQuotation(
                                    id: q.id,
                                    finalAmount: q.payableAmount,
                                  ),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text(
                                    'Aprobar',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => provider.rejectQuotation(
                                    id: q.id,
                                    reason: 'Sin disponibilidad de madera',
                                  ),
                                  child: Text(
                                    'Rechazar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final cap = await provider
                                  .checkDeliveryCapacity('2026-10-30');
                              setState(() => _capacityInfo = cap);
                            },
                            icon: const Icon(Icons.event_available, size: 18),
                            label: const Text('Verificar Cupo Diario'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _showScheduleDeliveryDialog(context),
                            icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                            label: const Text('Programar Entrega'),
                          ),
                        ),
                      ],
                    ),
                    if (_capacityInfo != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          'Capacidad ${_capacityInfo!.date}: ${_capacityInfo!.scheduledCount}/${_capacityInfo!.maxPerDay} programadas (${_capacityInfo!.remainingSlots} cupos libres)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ...deliveries.map((del) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Entrega #${del.id} (Pedido #${del.orderId})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: Text(
                                      del.statusLabel,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              Text(
                                'Fecha: ${del.scheduledDate} • ${del.timeSlotLabel}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryDarkWood,
                                ),
                              ),
                              Text(
                                '${del.isPickup ? "Recojo en taller" : "Domicilio"}: ${del.address}',
                                style: const TextStyle(fontSize: 12.5),
                              ),
                              if (del.latitude != null && del.longitude != null)
                                Text(
                                  'GPS: ${del.latitude}, ${del.longitude}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: [
                                  ActionChip(
                                    label: const Text(
                                      'En Camino',
                                      style: TextStyle(fontSize: 11.5),
                                    ),
                                    onPressed: () => provider.updateDeliveryStatus(
                                      del.id,
                                      'IN_TRANSIT',
                                    ),
                                  ),
                                  ActionChip(
                                    label: const Text(
                                      'Entregada',
                                      style: TextStyle(fontSize: 11.5),
                                    ),
                                    onPressed: () => provider.updateDeliveryStatus(
                                      del.id,
                                      'DELIVERED',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ],
    );
  }
}

// ── TAB 3: GESTIÓN DE CLIENTES, CARPINTEROS, FACTURAS E INVENTARIO ──────────

class _ManagementAndCatalogTab extends StatefulWidget {
  final ValueChanged<ProductEntity> onOrderProduct;

  const _ManagementAndCatalogTab({required this.onOrderProduct});

  @override
  State<_ManagementAndCatalogTab> createState() =>
      _ManagementAndCatalogTabState();
}

class _ManagementAndCatalogTabState extends State<_ManagementAndCatalogTab> {
  int _section = 0; // 0=Clientes, 1=Carpinteros, 2=Facturas PDF, 3=Maderas

  void _showClientDialog(BuildContext context, {ClientProfileEntity? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    String segment = existing?.segment ?? 'REGULAR';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Nuevo Cliente' : 'Editar Cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: segment,
                decoration: const InputDecoration(labelText: 'Segmento'),
                items: const [
                  DropdownMenuItem(value: 'REGULAR', child: Text('REGULAR')),
                  DropdownMenuItem(value: 'VIP', child: Text('VIP')),
                  DropdownMenuItem(value: 'WHOLESALE', child: Text('WHOLESALE')),
                ],
                onChanged: (v) {
                  if (v != null) segment = v;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = AppScope.of(context);
              if (existing == null) {
                await provider.createClient(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  segment: segment,
                );
              } else {
                await provider.updateClient(
                  id: existing.id,
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  segment: segment,
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showCarpenterDialog(BuildContext context, {CarpenterEntity? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final specCtrl =
        TextEditingController(text: existing?.specialty ?? 'Ebanistería fina');
    final expCtrl = TextEditingController(
      text: (existing?.yearsExperience ?? 5).toString(),
    );
    final rateCtrl = TextEditingController(
      text: (existing?.hourlyRate ?? 50.0).toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existing == null ? 'Nuevo Carpintero' : 'Editar Carpintero',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: specCtrl,
                decoration: const InputDecoration(labelText: 'Especialidad'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Años Exp.'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: rateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tarifa Bs/h'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = AppScope.of(context);
              if (existing == null) {
                await provider.createCarpenter(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  specialty: specCtrl.text.trim(),
                  yearsExperience: int.tryParse(expCtrl.text) ?? 3,
                  hourlyRate: double.tryParse(rateCtrl.text) ?? 45.0,
                );
              } else {
                await provider.updateCarpenter(
                  id: existing.id,
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  specialty: specCtrl.text.trim(),
                  yearsExperience: int.tryParse(expCtrl.text) ?? 3,
                  hourlyRate: double.tryParse(rateCtrl.text) ?? 45.0,
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showManualInvoiceDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: 'Roberto Suárez');
    final nitCtrl = TextEditingController(text: '4829102015');
    final emailCtrl = TextEditingController(text: 'cliente@carpinteria.com');
    final descCtrl = TextEditingController(text: 'Mesa de Comedor Imperial en Roble');
    final priceCtrl = TextEditingController(text: '2200');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emitir Factura Oficial'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Razón Social / Cliente'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nitCtrl,
                decoration: const InputDecoration(labelText: 'NIT / CI'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Correo Cliente'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Concepto / Mueble'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monto Total (Bs)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = AppScope.of(context);
              await provider.createManualInvoice(
                clientName: nameCtrl.text.trim(),
                clientNit: nitCtrl.text.trim(),
                clientEmail: emailCtrl.text.trim(),
                description: descCtrl.text.trim(),
                quantity: 1,
                unitPrice: double.tryParse(priceCtrl.text) ?? 1500.0,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Emitir Factura'),
          ),
        ],
      ),
    );
  }

  void _showProductDialog(BuildContext context, {ProductEntity? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final dimCtrl =
        TextEditingController(text: existing?.dimensions ?? '180 x 90 x 76 cm');
    final priceCtrl = TextEditingController(
      text: (existing?.price ?? 1800).toStringAsFixed(0),
    );
    final stockCtrl =
        TextEditingController(text: (existing?.stock ?? 3).toString());
    final daysCtrl =
        TextEditingController(text: (existing?.estimatedDays ?? 10).toString());
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final imgCtrl = TextEditingController(text: existing?.imageUrl ?? '');
    const categories = ['Mesas', 'Sillas', 'Roperos', 'Puertas', 'Cocina'];
    const woods = ['Roble', 'Mara', 'Cedro', 'Pino', 'Melamina'];
    String category = categories.contains(existing?.category)
        ? existing!.category
        : 'Mesas';
    String wood =
        woods.contains(existing?.woodType) ? existing!.woodType : 'Roble';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Publicar Mueble' : 'Editar Mueble'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => category = v ?? category,
              ),
              DropdownButtonFormField<String>(
                initialValue: wood,
                decoration: const InputDecoration(labelText: 'Madera'),
                items: woods
                    .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                    .toList(),
                onChanged: (v) => wood = v ?? wood,
              ),
              TextField(
                controller: dimCtrl,
                decoration: const InputDecoration(labelText: 'Medidas'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Precio Bs'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: daysCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Días'),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              TextField(
                controller: imgCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL de la foto (opcional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = AppScope.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final ok = await provider.saveMarketplaceProduct(
                id: existing?.id,
                name: nameCtrl.text.trim(),
                category: category,
                woodType: wood,
                dimensions: dimCtrl.text.trim(),
                price: double.tryParse(priceCtrl.text) ?? 0,
                stock: int.tryParse(stockCtrl.text) ?? 0,
                estimatedDays: int.tryParse(daysCtrl.text) ?? 10,
                description: descCtrl.text.trim(),
                imageUrl: imgCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              messenger.showSnackBar(SnackBar(
                content: Text(ok
                    ? 'Mueble guardado en el Marketplace'
                    : 'No se pudo guardar: ${provider.errorMessage ?? ""}'),
              ));
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context);

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Clientes y Segmentación'),
                selected: _section == 0,
                onSelected: (_) => setState(() => _section = 0),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Carpinteros'),
                selected: _section == 1,
                onSelected: (_) => setState(() => _section = 1),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Facturas PDF'),
                selected: _section == 2,
                onSelected: (_) => setState(() => _section = 2),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Maderas y Catálogo'),
                selected: _section == 3,
                onSelected: (_) => setState(() => _section = 3),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildSectionBody(context, provider),
        ),
      ],
    );
  }

  Widget _buildSectionBody(BuildContext context, AppProvider provider) {
    switch (_section) {
      case 0:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await provider.runClientClustering();
                    },
                    icon: const Icon(Icons.hub_outlined, size: 18),
                    label: const Text('Segmentar Clientes con IA'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _showClientDialog(context),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Nuevo Cliente'),
                ),
              ],
            ),
            if (provider.clientClusters.isNotEmpty) ...[
              const SizedBox(height: 10),
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Análisis Inteligente de Segmentos de Clientes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDarkWood,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...provider.clientClusters.map(
                        (cl) => Text(
                          '• Grupo #${cl.clusterId + 1} (${cl.label}): ${cl.size} cliente(s)',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            ...provider.clients.map(
              (c) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primaryWood,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    '${c.name} (${c.segment})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${c.email}\n${c.phone} • ${c.address}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showClientDialog(context, existing: c),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => provider.deleteClient(c.id),
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      case 1:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _showCarpenterDialog(context),
                icon: const Icon(Icons.engineering_outlined),
                label: const Text('Registrar Carpintero'),
              ),
            ),
            const SizedBox(height: 10),
            ...provider.carpenters.map(
              (cp) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primaryDarkWood,
                    child: Icon(Icons.handyman, color: AppTheme.accentAmber),
                  ),
                  title: Text(
                    cp.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${cp.specialty} • ${cp.yearsExperience} años exp.\nTarifa: Bs ${cp.hourlyRate.toStringAsFixed(0)}/h • ${cp.email}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () =>
                            _showCarpenterDialog(context, existing: cp),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => provider.deleteCarpenter(cp.id),
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      case 2:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _showManualInvoiceDialog(context),
                icon: const Icon(Icons.post_add_rounded),
                label: const Text('Emitir Factura Manual'),
              ),
            ),
            const SizedBox(height: 10),
            ...provider.invoices.map(
              (inv) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade50,
                    child: Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red.shade700,
                    ),
                  ),
                  title: Text(
                    'Factura ${inv.series}-${inv.number} • Bs ${inv.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Cliente: ${inv.clientName} (NIT: ${inv.clientNit})\nEmitida: ${inv.issuedAt}',
                  ),
                  isThreeLine: true,
                  trailing: FilledButton.tonalIcon(
                    onPressed: () =>
                        PaymentAndInvoiceModals.previewInvoicePdf(context, inv),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('PDF'),
                  ),
                ),
              ),
            ),
          ],
        );
      default:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Stock de Maderas e Insumos',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDarkWood,
              ),
            ),
            const SizedBox(height: 8),
            ...provider.materials.map((mat) {
              final low = mat.isLowStock;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    low ? Icons.warning_amber_rounded : Icons.layers_rounded,
                    color: low ? Colors.red.shade700 : AppTheme.primaryWood,
                  ),
                  title: Text(
                    mat.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${mat.type} • Mínimo: ${mat.minStock.toStringAsFixed(0)} ${mat.unit}',
                  ),
                  trailing: Text(
                    '${mat.quantity.toStringAsFixed(0)} ${mat.unit}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: low
                          ? Colors.red.shade700
                          : AppTheme.primaryDarkWood,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Marketplace de Muebles',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDarkWood,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showProductDialog(context),
                  icon: const Icon(Icons.add_business_outlined, size: 18),
                  label: const Text('Publicar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...provider.allProducts.map(
              (prod) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    prod.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${prod.category} • ${prod.woodType} • Bs ${prod.price.toStringAsFixed(0)}\n'
                    'Stock: ${prod.stock} ${prod.stock <= 0 ? "(Agotado)" : ""}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        _showProductDialog(context, existing: prod);
                      } else if (v == 'delete') {
                        await provider.deleteMarketplaceProduct(prod.id);
                      } else {
                        widget.onOrderProduct(prod);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar / Stock')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      PopupMenuItem(value: 'order', child: Text('Crear Pedido')),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight
                ? AppTheme.accentAmber
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 16,
              color: highlight ? AppTheme.accentAmber : Colors.white70,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _AmountColumn({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        Text(
          'Bs ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── TAB 5: PERFIL Y PREFERENCIAS DE CONEXIÓN ────────────────────────────────

class _ProfileTab extends StatefulWidget {
  final UserEntity? user;

  const _ProfileTab({required this.user});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: AppConfig.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context);
    final user = widget.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryWood, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo_el_roble.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Maestro Carpintero',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDarkWood,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'carpintero@carpinteria.com',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentAmber.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            provider.isAdminRole
                                ? 'Administración General'
                                : 'Maestro Carpintero',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDarkWood,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.fingerprint_rounded,
                        color: AppTheme.primaryWood,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Inicio de Sesión con Huella Dactilar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDarkWood,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: provider.isCurrentUserBiometricEnabled
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          provider.isCurrentUserBiometricEnabled
                              ? 'Activa'
                              : 'Sin vincular',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: provider.isCurrentUserBiometricEnabled
                                ? Colors.green.shade900
                                : Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.isCurrentUserBiometricEnabled
                        ? 'Tu huella está vinculada al correo ${user?.email ?? ""}. En la pantalla de acceso podrás entrar escribiendo únicamente tu correo y poniendo tu huella, sin introducir contraseña.'
                        : 'Activa tu huella dactilar para poder desbloquear tu cuenta en cualquier momento ingresando solo tu correo electrónico y tu huella, sin escribir tu contraseña.',
                    style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryWood,
                          ),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final ok = await provider
                                .configureBiometricForCurrentUser();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Huella dactilar vinculada exitosamente a ${user?.email ?? "tu cuenta"}'
                                      : (provider.errorMessage ??
                                          'No se pudo vincular la huella'),
                                ),
                                backgroundColor: ok
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            );
                          },
                          icon: const Icon(Icons.fingerprint_rounded),
                          label: Text(
                            provider.isCurrentUserBiometricEnabled
                                ? 'Actualizar Huella Dactilar'
                                : 'Configurar Inicio con Huella Dactilar',
                          ),
                        ),
                      ),
                      if (provider.isCurrentUserBiometricEnabled) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () async {
                            await provider.disableBiometricForCurrentUser();
                          },
                          child: const Text('Desactivar'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud_sync_rounded, color: AppTheme.primaryWood),
                      SizedBox(width: 8),
                      Text(
                        'Servidor de Sincronización',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDarkWood,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Configura la dirección de red del servidor central para sincronizar pedidos, inventario, facturación y notificaciones.',
                    style: TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección del Servidor',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await provider.updateBackendUrl(_urlController.text);
                        _urlController.text = AppConfig.baseUrl;
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                provider.isUsingMock
                                    ? 'Configuración guardada. Trabajando con respaldo local.'
                                    : 'Conectado al servidor central exitosamente.',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar y Sincronizar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              await provider.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRouter.login,
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'Cerrar Sesión',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
