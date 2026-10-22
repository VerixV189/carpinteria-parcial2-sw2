import 'package:flutter/material.dart';
import 'package:carpinteria_movil_sw2/core/config/app_config.dart';
import 'package:carpinteria_movil_sw2/core/services/llm_service.dart';
import 'package:carpinteria_movil_sw2/core/services/model_installer.dart';
import 'package:carpinteria_movil_sw2/core/services/whisper_service.dart';
import 'package:carpinteria_movil_sw2/domain/entities/entity.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/splash/splash_page.dart';
import 'package:carpinteria_movil_sw2/presentation/providers/app_provider.dart';
import 'package:carpinteria_movil_sw2/routes/app_router.dart';
import 'package:carpinteria_movil_sw2/theme/app_theme.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  int _currentIndex = 0;
  ProductEntity? _productForQuote;

  void _goToQuoteWithProduct(ProductEntity product) {
    setState(() {
      _productForQuote = product;
      _currentIndex = 1; // Pestaña Cotizar
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context);
    final cartCount = provider.cartItemCount;

    final titles = [
      'Marketplace de Muebles',
      'Cotizaciones y Mis Pedidos',
      'Mi Carrito de Compras',
      'Asistente al Cliente',
      'Mi Perfil',
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
              'Hola, ${provider.currentUser?.name ?? "Cliente"}',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppTheme.accentAmber,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Ver Carrito',
                onPressed: () => setState(() => _currentIndex = 2),
                icon: const Icon(Icons.shopping_cart_outlined),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _MarketplaceTab(onQuoteProduct: _goToQuoteWithProduct),
          _QuotationsTab(
            preselectedProduct: _productForQuote,
            onClearPreselected: () => setState(() => _productForQuote = null),
          ),
          _CartTab(
            onOrderCompleted: () => setState(() => _currentIndex = 1),
          ),
          const _ClientAssistantTab(),
          const _ClientProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Tienda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.design_services_outlined),
            selectedIcon: Icon(Icons.design_services_rounded),
            label: 'Cotizar',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_rounded),
            ),
            label: 'Carrito',
          ),
          const NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent_rounded),
            label: 'Asistente',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ── 1. MARKETPLACE DE MUEBLES DISPONIBLES A LA VENTA ────────────────────────

class _MarketplaceTab extends StatelessWidget {
  final ValueChanged<ProductEntity> onQuoteProduct;

  const _MarketplaceTab({required this.onQuoteProduct});

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
    final products = provider.availableMarketplaceProducts;

    return Column(
      children: [
        // Banner y buscador de tienda
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: const BoxDecoration(
            color: AppTheme.primaryDarkWood,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Muebles en Madera Certificada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: provider.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Buscar comedores, sillas, roperos, puertas...',
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

        // Categorías
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

        // Catálogo disponible (solo stock > 0)
        Expanded(
          child: products.isEmpty
              ? const Center(
                  child: Text('No hay muebles disponibles con ese filtro.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final item = products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 62,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryWood
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _mapIcon(item.iconName),
                                    color: AppTheme.primaryWood,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.green.shade300,
                                              ),
                                            ),
                                            child: Text(
                                              'Disponible (${item.stock} u.)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
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
                                        'Madera: ${item.woodType}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Medidas: ${item.dimensions}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
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
                            const Divider(height: 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Precio de Venta',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      'Bs ${item.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryWood,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                      ),
                                      onPressed: () => onQuoteProduct(item),
                                      child: const Text(
                                        'Cotizar a Medida',
                                        style: TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppTheme.primaryWood,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      onPressed: () {
                                        provider.addToCart(item);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${item.name} agregado al carrito',
                                            ),
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.add_shopping_cart_rounded,
                                        size: 17,
                                      ),
                                      label: const Text(
                                        'Al Carrito',
                                        style: TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                  ],
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

// ── 2. SECCIÓN DE COTIZACIONES A MEDIDA Y MIS PEDIDOS ──────────────────────

class _QuotationsTab extends StatefulWidget {
  final ProductEntity? preselectedProduct;
  final VoidCallback onClearPreselected;

  const _QuotationsTab({
    required this.preselectedProduct,
    required this.onClearPreselected,
  });

  @override
  State<_QuotationsTab> createState() => _QuotationsTabState();
}

class _QuotationsTabState extends State<_QuotationsTab> {
  final _formKey = GlobalKey<FormState>();
  final _furnitureCtrl = TextEditingController();
  final _dimensionsCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  String _selectedWood = 'Roble Macizo';

  @override
  void didUpdateWidget(covariant _QuotationsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.preselectedProduct != null &&
        widget.preselectedProduct != oldWidget.preselectedProduct) {
      final p = widget.preselectedProduct!;
      _furnitureCtrl.text = 'Cotización a medida: ${p.name}';
      _dimensionsCtrl.text = p.dimensions;
      _budgetCtrl.text = p.price.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _furnitureCtrl.dispose();
    _dimensionsCtrl.dispose();
    _detailsCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitQuote() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final clientName = provider.currentUser?.name ?? 'Cliente';
    final estBudget = double.tryParse(_budgetCtrl.text) ?? 1500.0;

    final estDate = DateTime.now().add(const Duration(days: 14));
    final dateStr =
        '${estDate.day.toString().padLeft(2, '0')}/${estDate.month.toString().padLeft(2, '0')}/${estDate.year}';

    await provider.createOrder(
      clientName: clientName,
      productName: _furnitureCtrl.text.trim(),
      woodType: _selectedWood,
      specifications:
          'Medidas: ${_dimensionsCtrl.text.trim()} | Detalles: ${_detailsCtrl.text.trim()}',
      totalAmount: estBudget,
      advancePayment: 0.0,
      deliveryDate: dateStr,
    );

    _furnitureCtrl.clear();
    _dimensionsCtrl.clear();
    _detailsCtrl.clear();
    _budgetCtrl.clear();
    widget.onClearPreselected();

    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          '¡Cotización enviada! Puedes ver su estado en Mis Solicitudes abajo.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context);
    final myOrders = provider.clientOrders;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Formulario de nueva cotización
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.architecture_rounded,
                          color: AppTheme.primaryWood,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Solicitar Cotización de Mueble a Medida',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDarkWood,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Indícanos qué mueble deseas fabricar, el tipo de madera y tus medidas personalizadas.',
                      style: TextStyle(fontSize: 12.5, color: Colors.black54),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _furnitureCtrl,
                      decoration: const InputDecoration(
                        labelText: '¿Qué mueble deseas cotizar?',
                        hintText: 'Ej: Ropero empotrado 3 puertas, Mesa...',
                        prefixIcon: Icon(Icons.chair_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Describe el mueble'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedWood,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Madera preferida',
                        prefixIcon: Icon(Icons.forest_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Roble Macizo',
                          child: Text('Roble Macizo (Alta durabilidad)'),
                        ),
                        DropdownMenuItem(
                          value: 'Cedro Seleccionado',
                          child: Text('Cedro Seleccionado (Fino acabado)'),
                        ),
                        DropdownMenuItem(
                          value: 'Tajibo / Exterior',
                          child: Text('Tajibo (Ideal para puertas y exterior)'),
                        ),
                        DropdownMenuItem(
                          value: 'Melamina RH 18mm',
                          child: Text('Melamina RH Hidrófuga 18mm (Moderna)'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedWood = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _dimensionsCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Medidas aprox. (cm)',
                              hintText: 'Ej: 200 x 90 x 75 cm',
                              prefixIcon: Icon(Icons.straighten_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _budgetCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Presupuesto (Bs)',
                              hintText: 'Ej: 2500',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _detailsCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Color de barniz, divisiones o detalles extra',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: _submitQuote,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Enviar Solicitud de Cotización'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Historial de pedidos y cotizaciones del propio cliente
          const Text(
            'Mis Pedidos y Cotizaciones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDarkWood,
            ),
          ),
          const SizedBox(height: 10),
          if (myOrders.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Aún no tienes pedidos ni cotizaciones registradas con tu cuenta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ...myOrders.map((order) {
              final balance = order.totalAmount - order.advancePayment;
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
                          Text(
                            'Código: ${order.id}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          Chip(
                            label: Text(
                              order.status,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Colors.amber.shade100,
                          ),
                        ],
                      ),
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
                        'Madera: ${order.woodType} • Entrega est.: ${order.deliveryDate}',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      if (order.specifications.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            order.specifications,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      const Divider(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total: Bs ${order.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Adelanto: Bs ${order.advancePayment.toStringAsFixed(0)}',
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                          Text(
                            'Saldo: Bs ${balance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: balance > 0
                                  ? Colors.red.shade700
                                  : Colors.grey,
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
    );
  }
}

// ── 3. CARRITO DE COMPRAS DEL CLIENTE ───────────────────────────────────────

class _CartTab extends StatefulWidget {
  final VoidCallback onOrderCompleted;

  const _CartTab({required this.onOrderCompleted});

  @override
  State<_CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<_CartTab> {
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context);
    final items = provider.cartItems;
    final total = provider.cartTotal;

    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.remove_shopping_cart_outlined,
                size: 64,
                color: Colors.black38,
              ),
              SizedBox(height: 12),
              Text(
                'Tu carrito está vacío',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDarkWood,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Explora el Marketplace en la pestaña "Tienda" y agrega los muebles que desees comprar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final cartItem = items[index];
              final product = cartItem.product;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.primaryDarkWood,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${product.woodType} • Bs ${product.price.toStringAsFixed(0)} c/u',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Subtotal: Bs ${cartItem.subtotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryWood,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => provider.updateCartQuantity(
                              product.id,
                              cartItem.quantity - 1,
                            ),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '${cartItem.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          IconButton(
                            onPressed: cartItem.quantity < product.stock
                                ? () => provider.updateCartQuantity(
                                      product.id,
                                      cartItem.quantity + 1,
                                    )
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                          IconButton(
                            tooltip: 'Quitar',
                            onPressed: () => provider.removeFromCart(product.id),
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade700,
                            ),
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

        // Resumen y confirmación de pedido
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dirección de entrega o instrucciones adicionales',
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total a Pagar:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Bs ${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDarkWood,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await provider.checkoutCart(
                    advancePayment: total * 0.5,
                    deliveryNotes: _notesCtrl.text.trim(),
                  );
                  if (ok) {
                    _notesCtrl.clear();
                    widget.onOrderCompleted();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          '¡Compra confirmada! Puedes hacer seguimiento en "Cotizar / Mis Pedidos".',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirmar Pedido de Compra'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 4. ASISTENTE DE IA PARA CLIENTES (SIN INFORMES NI DATOS SENSIBLES) ──────

class _ClientAssistantTab extends StatefulWidget {
  const _ClientAssistantTab();

  @override
  State<_ClientAssistantTab> createState() => _ClientAssistantTabState();
}

class _ClientAssistantTabState extends State<_ClientAssistantTab> {
  final _controller = TextEditingController();
  final _whisperService = WhisperService();
  final _llmService = LlmService();

  bool _isRecording = false;
  bool _isThinking = false;
  final List<Map<String, String>> _messages = [
    {
      'sender': 'bot',
      'text':
          '¡Hola! Soy el Asistente Virtual de Carpintería El Roble. Puedo ayudarte a consultar el estado de tus pedidos, precios de muebles disponibles o recomendarte la mejor madera para tu hogar.',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    _whisperService.dispose();
    _llmService.dispose();
    super.dispose();
  }

  Future<void> _sendQuestion([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isThinking) return;

    final provider = AppScope.of(context);
    _controller.clear();

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isThinking = true;
    });

    try {
      if (ModelInstaller.isReady && !_llmService.isLoaded) {
        await _llmService.loadModel(ModelInstaller.llmModelPath);
      }

      final reply = await _llmService.generateClientResponse(
        rawQuestion: text,
        clientName: provider.currentUser?.name ?? 'Cliente',
        myOrders: provider.clientOrders,
        availableProducts: provider.availableMarketplaceProducts,
      );

      if (!mounted) return;
      setState(() {
        _messages.add({'sender': 'bot', 'text': reply});
        _isThinking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'sender': 'security',
          'text': e.toString().replaceAll('Exception: ', ''),
        });
        _isThinking = false;
      });
    }
  }

  Future<void> _toggleMic() async {
    if (_isRecording) {
      setState(() => _isRecording = false);
      try {
        final transcript = await _whisperService.stopAndTranscribe();
        if (!mounted) return;
        if (transcript.isNotEmpty) {
          _controller.text = transcript;
          await _sendQuestion(transcript);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de micrófono: $e')),
        );
      }
    } else {
      try {
        await _whisperService.startRecording();
        if (!mounted) return;
        setState(() => _isRecording = true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo iniciar micrófono: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra informativa de privacidad del cliente
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: AppTheme.primaryDarkWood,
          child: Row(
            children: [
              const Icon(
                Icons.lock_person_rounded,
                color: AppTheme.accentAmber,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Asistente de Cliente: Consulta tus pedidos y catálogo en venta.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              if (!ModelInstaller.isReady)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SplashPage()),
                    );
                  },
                  child: const Text(
                    'Activar Voz IA',
                    style: TextStyle(
                      color: AppTheme.accentAmber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Sugerencias rápidas para el cliente
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              ActionChip(
                avatar: const Icon(Icons.local_shipping_outlined, size: 16),
                label: const Text(
                  '¿En qué estado están mis pedidos?',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () =>
                    _sendQuestion('¿En qué estado están mis pedidos y cuánto debo?'),
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.chair_outlined, size: 16),
                label: const Text(
                  '¿Qué muebles tienen disponibles?',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () =>
                    _sendQuestion('¿Qué muebles tienen disponibles a la venta y sus precios?'),
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.forest_outlined, size: 16),
                label: const Text(
                  '¿Cómo cuidar madera de roble?',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () => _sendQuestion(
                  '¿Qué cuidados me recomiendas para limpiar mi mesa de madera roble?',
                ),
              ),
            ],
          ),
        ),

        // Historial de mensajes
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _messages.length + (_isThinking ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length) {
                return const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final msg = _messages[index];
              final isUser = msg['sender'] == 'user';
              final isSecurity = msg['sender'] == 'security';

              return Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(13),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.82,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppTheme.primaryWood
                        : (isSecurity ? Colors.red.shade50 : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: isSecurity
                        ? Border.all(color: Colors.red.shade300)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isSecurity) ...[
                        Icon(
                          Icons.gpp_bad_rounded,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(
                            color: isUser
                                ? Colors.white
                                : (isSecurity
                                    ? Colors.red.shade900
                                    : Colors.black87),
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Barra inferior de escritura y micrófono
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          color: Colors.white,
          child: Row(
            children: [
              IconButton.filledTonal(
                onPressed: _toggleMic,
                style: IconButton.styleFrom(
                  backgroundColor: _isRecording
                      ? Colors.red.shade100
                      : AppTheme.primaryWood.withValues(alpha: 0.12),
                ),
                icon: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: _isRecording ? Colors.red : AppTheme.primaryWood,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _sendQuestion(),
                  decoration: const InputDecoration(
                    hintText: 'Pregunta por tu pedido o por un mueble...',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryWood,
                ),
                onPressed: _isThinking ? null : () => _sendQuestion(),
                icon: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 5. PERFIL DEL CLIENTE ───────────────────────────────────────────────────

class _ClientProfileTab extends StatefulWidget {
  const _ClientProfileTab();

  @override
  State<_ClientProfileTab> createState() => _ClientProfileTabState();
}

class _ClientProfileTabState extends State<_ClientProfileTab> {
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
    final user = provider.currentUser;

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
                    radius: 30,
                    backgroundColor: AppTheme.primaryWood,
                    child: Text(
                      (user?.name.isNotEmpty ?? false)
                          ? user!.name[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Cliente',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDarkWood,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Cuenta Cliente Marketplace',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Servidor Backend API',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDarkWood,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'BASE_URL',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await provider.updateBackendUrl(_urlController.text);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Dirección del servidor actualizada'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Actualizar Conexión'),
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
              final nav = Navigator.of(context);
              await provider.logout();
              nav.pushNamedAndRemoveUntil(AppRouter.login, (_) => false);
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
