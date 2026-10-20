import 'package:flutter/material.dart';
import 'package:carpinteria_movil_sw2/core/config/app_config.dart';
import 'package:carpinteria_movil_sw2/domain/entities/entity.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/voice_report_page.dart';
import 'package:carpinteria_movil_sw2/presentation/providers/app_provider.dart';
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
    final clientCtrl = TextEditingController();
    final productCtrl = TextEditingController(text: preselected?.name ?? '');
    final woodCtrl = TextEditingController(text: preselected?.woodType ?? 'Roble Macizo');
    final specsCtrl = TextEditingController(
      text: preselected != null ? 'Dimensiones: ${preselected.dimensions}' : '',
    );
    final totalCtrl = TextEditingController(
      text: preselected != null ? preselected.price.toStringAsFixed(0) : '',
    );
    final advanceCtrl = TextEditingController(
      text: preselected != null ? (preselected.price * 0.5).toStringAsFixed(0) : '',
    );
    final dateCtrl = TextEditingController(text: '30/10/2026');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.warmCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
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
                        'Nuevo Pedido / Cotización',
                        style: TextStyle(
                          fontSize: 18,
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
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: clientCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Cliente',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: productCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mueble / Trabajo solicitado',
                      prefixIcon: Icon(Icons.chair_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: woodCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Madera / Material',
                            prefixIcon: Icon(Icons.forest_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: dateCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Fecha Entrega',
                            prefixIcon: Icon(Icons.event_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: specsCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Medidas, tono de barniz y detalles',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final provider = AppScope.of(this.context);
                      final messenger = ScaffoldMessenger.of(this.context);
                      await provider.createOrder(
                        clientName: clientCtrl.text.trim(),
                        productName: productCtrl.text.trim(),
                        woodType: woodCtrl.text.trim(),
                        specifications: specsCtrl.text.trim(),
                        totalAmount: double.tryParse(totalCtrl.text) ?? 0.0,
                        advancePayment: double.tryParse(advanceCtrl.text) ?? 0.0,
                        deliveryDate: dateCtrl.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        setState(() => _currentIndex = 1);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Pedido registrado correctamente'),
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
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context);
    final user = provider.currentUser;

    final titles = [
      'Catálogo Carpintería',
      'Pedidos y Cotizaciones',
      'Inventario de Maderas',
      'Asistente IA por Voz',
      'Mi Perfil y Servidor',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titles[_currentIndex],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              provider.isUsingMock
                  ? 'Modo Híbrido (Datos locales • API lista)'
                  : 'Conectado a Backend (${AppConfig.baseUrl})',
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
          IconButton(
            tooltip: 'Sincronizar con Backend',
            onPressed: provider.loadCarpentryData,
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _CatalogTab(
            onOrderProduct: (product) =>
                _showCreateOrderModal(context, preselected: product),
          ),
          _OrdersTab(
            onAddOrder: () => _showCreateOrderModal(context),
          ),
          const _InventoryTab(),
          const VoiceReportPage(),
          _ProfileTab(user: user),
        ],
      ),
      floatingActionButton: _currentIndex == 1
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
            icon: Icon(Icons.chair_outlined),
            selectedIcon: Icon(Icons.chair),
            label: 'Muebles',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.forest_outlined),
            selectedIcon: Icon(Icons.forest),
            label: 'Maderas',
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

// ── TAB 1: CATÁLOGO DE MUEBLES ──────────────────────────────────────────────

class _CatalogTab extends StatelessWidget {
  final ValueChanged<ProductEntity> onOrderProduct;

  const _CatalogTab({required this.onOrderProduct});

  IconData _mapIcon(String name) {
    switch (name) {
      case 'table_restaurant':
        return Icons.table_restaurant_rounded;
      case 'door_sliding':
        return Icons.door_sliding_rounded;
      case 'door_front_door':
        return Icons.door_front_door_rounded;
      case 'countertops':
        return Icons.countertops_rounded;
      case 'desk':
        return Icons.desk_rounded;
      default:
        return Icons.chair_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context);
    final products = provider.filteredProducts;
    final lowStockCount =
        provider.materials.where((m) => m.isLowStock).length;

    return Column(
      children: [
        // Resumen rápido de la carpintería
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: const BoxDecoration(
            color: AppTheme.primaryDarkWood,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _StatBadge(
                    label: 'Muebles',
                    value: '${provider.allProducts.length}',
                    icon: Icons.chair_alt_rounded,
                  ),
                  const SizedBox(width: 10),
                  _StatBadge(
                    label: 'Pedidos Activos',
                    value: '${provider.orders.length}',
                    icon: Icons.handyman_rounded,
                  ),
                  const SizedBox(width: 10),
                  _StatBadge(
                    label: 'Stock Alerta',
                    value: '$lowStockCount insumo(s)',
                    icon: Icons.warning_amber_rounded,
                    highlight: lowStockCount > 0,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: provider.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Buscar mueble o tipo de madera (Roble, Cedro...)',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filtro por categorías
        SizedBox(
          height: 50,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: provider.categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = provider.categories[i];
              final selected = cat == provider.selectedCategory;
              return ChoiceChip(
                label: Text(cat),
                selected: selected,
                selectedColor: AppTheme.primaryWood,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.brown.shade900,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => provider.setCategory(cat),
              );
            },
          ),
        ),

        // Lista de productos
        Expanded(
          child: products.isEmpty
              ? const Center(
                  child: Text('No se encontraron muebles en esta categoría.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final item = products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryWood
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _mapIcon(item.iconName),
                                    color: AppTheme.primaryWood,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.category,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.brown.shade900,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Entrega: ~${item.estimatedDays} días',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryDarkWood,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Madera: ${item.woodType} • ${item.dimensions}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Precio estimado',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      'Bs ${item.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryWood,
                                      ),
                                    ),
                                  ],
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () => onOrderProduct(item),
                                  icon: const Icon(
                                    Icons.add_shopping_cart_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Crear Pedido'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight
                ? AppTheme.accentAmber
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: highlight ? AppTheme.accentAmber : Colors.white70,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── TAB 2: PEDIDOS Y COTIZACIONES ───────────────────────────────────────────

class _OrdersTab extends StatelessWidget {
  final VoidCallback onAddOrder;

  const _OrdersTab({required this.onAddOrder});

  Color _statusColor(String status) {
    switch (status) {
      case 'En fabricación':
        return Colors.blue.shade700;
      case 'Listo':
        return Colors.green.shade700;
      case 'Entregado':
        return Colors.teal.shade700;
      default:
        return Colors.orange.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context);
    final orders = provider.orders;

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No hay pedidos registrados aún'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onAddOrder,
              icon: const Icon(Icons.add),
              label: const Text('Crear primer pedido'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final pendingBalance = order.totalAmount - order.advancePayment;
        final color = _statusColor(order.status);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Código: ${order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        fontSize: 12.5,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (newStatus) {
                        provider.updateOrderStatus(order.id, newStatus);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'Pendiente',
                          child: Text('Marcar: Pendiente'),
                        ),
                        PopupMenuItem(
                          value: 'En fabricación',
                          child: Text('Marcar: En fabricación'),
                        ),
                        PopupMenuItem(
                          value: 'Listo',
                          child: Text('Marcar: Listo para entrega'),
                        ),
                        PopupMenuItem(
                          value: 'Entregado',
                          child: Text('Marcar: Entregado'),
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
                          border: Border.all(color: color.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              order.status,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.edit_outlined, size: 14, color: color),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  order.productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDarkWood,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      'Cliente: ${order.clientName}',
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.forest_outlined, size: 16, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      'Madera: ${order.woodType} • Entrega: ${order.deliveryDate}',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
                if (order.specifications.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    order.specifications,
                    style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                ],
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _AmountColumn(
                      label: 'Total',
                      amount: order.totalAmount,
                      color: AppTheme.primaryDarkWood,
                    ),
                    _AmountColumn(
                      label: 'Adelanto',
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
      },
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

// ── TAB 3: INVENTARIO DE MADERAS E INSUMOS ──────────────────────────────────

class _InventoryTab extends StatelessWidget {
  const _InventoryTab();

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context);
    final materials = provider.materials;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final mat = materials[index];
        final low = mat.isLowStock;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: low
                  ? Colors.red.shade100
                  : AppTheme.primaryWood.withValues(alpha: 0.12),
              child: Icon(
                low ? Icons.warning_amber_rounded : Icons.layers_rounded,
                color: low ? Colors.red.shade800 : AppTheme.primaryWood,
              ),
            ),
            title: Text(
              mat.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Categoría: ${mat.type} • Costo: Bs ${mat.costPerUnit.toStringAsFixed(1)} / ${mat.unit}',
                  style: const TextStyle(fontSize: 12.5),
                ),
                if (low)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Stock bajo (Mínimo requerido: ${mat.minStock.toStringAsFixed(0)} ${mat.unit})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  mat.quantity.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: low ? Colors.red.shade700 : AppTheme.primaryDarkWood,
                  ),
                ),
                Text(
                  mat.unit,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── TAB 5: PERFIL Y CONEXIÓN AL BACKEND ─────────────────────────────────────

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
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primaryWood,
                    child: Text(
                      (user?.name.isNotEmpty ?? false)
                          ? user!.name[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                          user?.email ?? 'sin-correo@carpinteria.bo',
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
                            'Rol: ${(user?.role ?? 'carpintero').toUpperCase()}',
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

          // Configuración de Backend API
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
                        'Configuración de Backend API',
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
                    'El cliente HTTP envía automáticamente el token JWT en el header Authorization: Bearer <token>.',
                    style: TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'URL Base del Backend (BASE_URL)',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await provider.updateBackendUrl(_urlController.text);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                provider.isUsingMock
                                    ? 'URL guardada. Backend sin respuesta, usando datos locales.'
                                    : '¡Conectado exitosamente al Backend!',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar y Probar Conexión'),
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
