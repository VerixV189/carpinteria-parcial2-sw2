import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:carpinteria_movil_sw2/core/config/app_config.dart';
import 'package:carpinteria_movil_sw2/core/services/llm_service.dart';
import 'package:carpinteria_movil_sw2/core/services/model_installer.dart';
import 'package:carpinteria_movil_sw2/core/services/whisper_service.dart';
import 'package:carpinteria_movil_sw2/domain/entities/entity.dart';
import 'package:carpinteria_movil_sw2/presentation/pages/splash/splash_page.dart';
import 'package:carpinteria_movil_sw2/presentation/providers/app_provider.dart';
import 'package:carpinteria_movil_sw2/presentation/widgets/notification_bell_button.dart';
import 'package:carpinteria_movil_sw2/presentation/widgets/payment_and_invoice_modals.dart';
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
      _currentIndex = 1; // Pestaña Cotizar IA
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context);
    final cartCount = provider.cartItemCount;

    final titles = [
      'Catálogo de Muebles',
      'Cotizar a Medida y Mis Pedidos',
      'Mis Recibos y Carrito',
      'Asistente Virtual',
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
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              provider.isUsingMock
                  ? 'Hola, ${provider.currentUser?.name ?? "Cliente"} • Modo Sin Conexión'
                  : 'Hola, ${provider.currentUser?.name ?? "Cliente"} • Carpintería El Roble',
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
            tooltip: 'Sincronizar',
            onPressed: provider.loadCarpentryData,
            icon: const Icon(Icons.sync_rounded),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Ver Carrito y Recibos',
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
          _CartAndInvoicesTab(
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
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Cotizar IA',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.receipt_long_rounded),
            ),
            label: 'Recibos/Pago',
          ),
          const NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent_rounded),
            label: 'Agente IA',
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

// ── 1. TIENDA / CATÁLOGO DEL PORTAL CLIENTE ─────────────────────────────────

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
                'Catálogo de Muebles en Madera Certificada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
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
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryWood
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _mapIcon(item.iconName),
                                    color: AppTheme.primaryWood,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          Text(
                                            '~${item.estimatedDays} días',
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
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryDarkWood,
                                        ),
                                      ),
                                      Text(
                                        'Madera: ${item.woodType} • ${item.dimensions}',
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
                            const SizedBox(height: 8),
                            Text(
                              item.description,
                              style: const TextStyle(
                                fontSize: 12.5,
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
                                      'Precio referencia',
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
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => onQuoteProduct(item),
                                      icon: const Icon(
                                        Icons.auto_awesome,
                                        size: 15,
                                      ),
                                      label: const Text(
                                        'Cotizar IA',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppTheme.primaryWood,
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
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Comprar',
                                        style: TextStyle(fontSize: 12),
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

// ── 2. COTIZAR CON IA + NEGOCIACIÓN + MIS COTIZACIONES ──────────────────────

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
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController(
    text: 'Av. Cristo Redentor 4to Anillo, Santa Cruz',
  );
  final _latCtrl = TextEditingController(text: '-17.7540');
  final _lngCtrl = TextEditingController(text: '-63.1790');

  String _selectedWood = 'Roble';
  String _deliveryType = 'DELIVERY'; // 'DELIVERY' | 'PICKUP'
  bool _hasAttachedReferencePhoto = false;
  bool _isEstimating = false;
  AiEstimateEntity? _aiEstimate;
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoBase64;
  String? _selectedPhotoSourceLabel;

  Future<void> _pickReferencePhoto(ImageSource source) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 78,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedPhotoBytes = bytes;
        _selectedPhotoBase64 = base64Encode(bytes);
        _selectedPhotoSourceLabel =
            source == ImageSource.camera ? 'Cámara' : 'Galería';
        _hasAttachedReferencePhoto = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir la imagen: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Adjuntar Foto o Plano de Referencia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDarkWood,
                  ),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryWood,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.camera_alt_rounded),
                ),
                title: const Text('Tomar foto con la Cámara'),
                subtitle: const Text(
                  'Fotografía el espacio, mueble o boceto con tu cámara',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickReferencePhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryDarkWood,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.photo_library_rounded),
                ),
                title: const Text('Elegir desde la Galería'),
                subtitle: const Text(
                  'Selecciona una imagen o diseño guardado en tu teléfono',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickReferencePhoto(ImageSource.gallery);
                },
              ),
              if (_hasAttachedReferencePhoto)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade700,
                    child: const Icon(Icons.delete_outline_rounded),
                  ),
                  title: Text(
                    'Quitar foto adjuntada',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedPhotoBytes = null;
                      _selectedPhotoBase64 = null;
                      _selectedPhotoSourceLabel = null;
                      _hasAttachedReferencePhoto = false;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _QuotationsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.preselectedProduct != null &&
        widget.preselectedProduct != oldWidget.preselectedProduct) {
      final p = widget.preselectedProduct!;
      setState(() {
        _descCtrl.text =
            '${p.name} de medidas ${p.dimensions} con acabado fino.';
        _selectedWood = p.woodType.split(' ').first;
        _aiEstimate = null;
      });
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _calculateAiEstimate() async {
    if (_descCtrl.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Describe primero el mueble y sus medidas en el Paso 1'),
        ),
      );
      return;
    }
    setState(() => _isEstimating = true);
    final provider = AppScope.of(context);
    final est = await provider.estimateFurniture(
      description: _descCtrl.text.trim(),
      woodType: _selectedWood,
      imageBase64: _hasAttachedReferencePhoto ? _selectedPhotoBase64 : null,
    );
    if (!mounted) return;
    setState(() {
      _aiEstimate = est;
      _isEstimating = false;
    });
  }

  Future<void> _submitQuotation() async {
    if (_descCtrl.text.trim().isEmpty) return;
    final provider = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (_aiEstimate == null) {
      await _calculateAiEstimate();
    }
    if (!mounted) return;

    final price = _aiEstimate?.estimatedPrice ?? 1850.0;
    final created = await provider.createQuotation(
      description: _descCtrl.text.trim(),
      woodType: _selectedWood,
      estimatedPrice: price,
      aiEstimate: _aiEstimate,
      imageBase64: _hasAttachedReferencePhoto ? _selectedPhotoBase64 : null,
      deliveryType: _deliveryType,
      deliveryAddress: _deliveryType == 'DELIVERY'
          ? _addressCtrl.text.trim()
          : 'Recojo en taller',
      latitude: _deliveryType == 'DELIVERY'
          ? double.tryParse(_latCtrl.text)
          : null,
      longitude: _deliveryType == 'DELIVERY'
          ? double.tryParse(_lngCtrl.text)
          : null,
    );

    if (created != null) {
      setState(() {
        _descCtrl.clear();
        _aiEstimate = null;
        _hasAttachedReferencePhoto = false;
        _selectedPhotoBytes = null;
        _selectedPhotoBase64 = null;
        _selectedPhotoSourceLabel = null;
      });
      widget.onClearPreselected();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '¡Cotización #${created.id.substring(0, created.id.length.clamp(0, 8))} enviada al taller!',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  void _showCounterOfferDialog(QuotationEntity q) {
    final amountCtrl = TextEditingController(
      text: (q.payableAmount * 0.9).toStringAsFixed(0),
    );
    final msgCtrl = TextEditingController(
      text: '¿Podrían dejarlo en este monto si pago al contado hoy?',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Proponer Contraoferta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Precio cotizado por el taller: Bs ${q.payableAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tu monto propuesto (Bs)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: msgCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Mensaje para el carpintero',
                prefixIcon: Icon(Icons.chat_bubble_outline),
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
              await provider.respondQuotation(
                id: q.id,
                action: 'counter',
                counterAmount: double.tryParse(amountCtrl.text) ?? q.payableAmount,
                message: msgCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Enviar Contraoferta'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context);
    final quotations = provider.quotations;
    final woods = const ['Roble', 'Cedro', 'Mara', 'Pino', 'Melamina'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Asistente de Cotización IA en 3 pasos ──────────────────────────
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppTheme.primaryWood),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cotizar Mueble a Medida con IA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDarkWood,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '1) Describe tu mueble • 2) Elige madera y foto • 3) Obtén precio IA y modalidad de entrega',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),

                  // Ejemplos rápidos
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        label: const Text(
                          'Mesa comedor 6p (200x100cm)',
                          style: TextStyle(fontSize: 11.5),
                        ),
                        onPressed: () => setState(() {
                          _descCtrl.text =
                              'Mesa de comedor para 6 personas de 200x100x76 cm con acabado mate.';
                        }),
                      ),
                      ActionChip(
                        label: const Text(
                          'Ropero 3 puertas (220x60x235cm)',
                          style: TextStyle(fontSize: 11.5),
                        ),
                        onPressed: () => setState(() {
                          _descCtrl.text =
                              'Ropero empotrado de 3 puertas corredizas de 220x60x235 cm con cajonera.';
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Paso 1: Describe el mueble y sus medidas',
                      hintText:
                          'Ej: Escritorio en L de 160x120x75 cm con 3 cajones...',
                      prefixIcon: Icon(Icons.straighten_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Paso 2: Selecciona la madera y adjunta diseño/plano (opcional):',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryDarkWood,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: woods.map((w) {
                      final selected = _selectedWood == w;
                      return ChoiceChip(
                        label: Text(w),
                        selected: selected,
                        selectedColor: AppTheme.primaryWood,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setState(() => _selectedWood = w),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showPhotoSourceSheet,
                          icon: Icon(
                            _hasAttachedReferencePhoto
                                ? Icons.check_circle_rounded
                                : Icons.add_a_photo_outlined,
                            color: _hasAttachedReferencePhoto
                                ? Colors.green.shade700
                                : AppTheme.primaryWood,
                            size: 18,
                          ),
                          label: Text(
                            _hasAttachedReferencePhoto
                                ? 'Foto adjuntada (${_selectedPhotoSourceLabel ?? "Imagen"})'
                                : 'Cámara / Galería (Foto o Plano)',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: _isEstimating ? null : _calculateAiEstimate,
                        icon: _isEstimating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.calculate_outlined, size: 18),
                        label: const Text('Estimar con IA'),
                      ),
                    ],
                  ),
                  if (_selectedPhotoBytes != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.brown.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.brown.shade200),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _selectedPhotoBytes!,
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Imagen lista para enviar (${_selectedPhotoSourceLabel ?? "Referencia"})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: AppTheme.primaryDarkWood,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Se analizará con IA y se adjuntará a tu cotización para el taller.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Cambiar o quitar foto',
                            onPressed: _showPhotoSourceSheet,
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppTheme.primaryWood,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_aiEstimate != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mueble identificado: ${_aiEstimate!.furnitureType.toUpperCase()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryDarkWood,
                                  ),
                                ),
                                Text(
                                  'Precisión estimada: ${(_aiEstimate!.confidence * 100).toStringAsFixed(0)}% • Madera: $_selectedWood',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Bs ${_aiEstimate!.estimatedPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryWood,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Text(
                    'Paso 3: ¿Cómo prefieres recibir tu mueble?',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryDarkWood,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Envío a domicilio'),
                          selected: _deliveryType == 'DELIVERY',
                          selectedColor: AppTheme.primaryWood,
                          labelStyle: TextStyle(
                            color: _deliveryType == 'DELIVERY'
                                ? Colors.white
                                : Colors.black87,
                          ),
                          onSelected: (_) =>
                              setState(() => _deliveryType = 'DELIVERY'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Recojo en taller'),
                          selected: _deliveryType == 'PICKUP',
                          selectedColor: AppTheme.primaryWood,
                          labelStyle: TextStyle(
                            color: _deliveryType == 'PICKUP'
                                ? Colors.white
                                : Colors.black87,
                          ),
                          onSelected: (_) =>
                              setState(() => _deliveryType = 'PICKUP'),
                        ),
                      ),
                    ],
                  ),
                  if (_deliveryType == 'DELIVERY') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dirección de entrega',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _latCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Latitud GPS',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _lngCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Longitud GPS',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _submitQuotation,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Enviar Solicitud al Taller'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Lista de Cotizaciones y Negociación ────────────────────────────
          const Text(
            'Mis Cotizaciones y Seguimiento de Negociación',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDarkWood,
            ),
          ),
          const SizedBox(height: 8),
          if (quotations.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Aún no tienes cotizaciones registradas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ...quotations.map((q) {
              final statusUpper = q.status.toUpperCase();
              final isQuoted = statusUpper == 'QUOTED';
              final isApproved = statusUpper == 'APPROVED';
              final isConverted = statusUpper == 'CONVERTED';

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
                              'Cotización #${q.id.substring(0, q.id.length.clamp(0, 8))}',
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isConverted
                                  ? Colors.green.shade100
                                  : (isQuoted || isApproved
                                      ? Colors.blue.shade100
                                      : Colors.amber.shade100),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              q.statusLabel,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isConverted
                                    ? Colors.green.shade900
                                    : Colors.brown.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        q.description,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDarkWood,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Madera: ${q.woodType} • Entrega: ${q.deliveryType == "PICKUP" ? "Recojo en taller" : q.deliveryAddress}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.black87,
                        ),
                      ),
                      if (q.notes != null && q.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Nota del taller: ${q.notes}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey.shade800,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      if (q.counterAmount != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Tu contraoferta enviada: Bs ${q.counterAmount!.toStringAsFixed(0)} (${q.clientMessage ?? ""})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Divider(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                q.finalAmount != null
                                    ? 'Precio Formal del Taller'
                                    : 'Estimación IA',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                'Bs ${q.payableAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryWood,
                                ),
                              ),
                            ],
                          ),
                          if (isQuoted)
                            Wrap(
                              spacing: 6,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _showCounterOfferDialog(q),
                                  child: const Text(
                                    'Contraoferta',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                  ),
                                  onPressed: () async {
                                    await provider.respondQuotation(
                                      id: q.id,
                                      action: 'accept',
                                    );
                                    if (!context.mounted) return;
                                    await PaymentAndInvoiceModals
                                        .showPaymentGatewayModal(
                                      context,
                                      quotationId: q.id,
                                      description: q.description,
                                      amount: q.payableAmount,
                                    );
                                  },
                                  icon: const Icon(Icons.payment, size: 16),
                                  label: const Text(
                                    'Aceptar y Pagar',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            )
                          else if (isApproved)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryWood,
                              ),
                              onPressed: () =>
                                  PaymentAndInvoiceModals.showPaymentGatewayModal(
                                context,
                                quotationId: q.id,
                                description: q.description,
                                amount: q.payableAmount,
                              ),
                              icon: const Icon(Icons.credit_card, size: 16),
                              label: const Text('Pagar con Tarjeta'),
                            )
                          else if (isConverted)
                            const Chip(
                              avatar: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                              label: Text(
                                'Pagada • En Taller',
                                style: TextStyle(fontSize: 11.5),
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

// ── 3. MIS RECIBOS / FACTURAS PDF Y CARRITO DE COMPRAS ──────────────────────

class _CartAndInvoicesTab extends StatefulWidget {
  final VoidCallback onOrderCompleted;

  const _CartAndInvoicesTab({required this.onOrderCompleted});

  @override
  State<_CartAndInvoicesTab> createState() => _CartAndInvoicesTabState();
}

class _CartAndInvoicesTabState extends State<_CartAndInvoicesTab> {
  final _notesCtrl = TextEditingController(
    text: 'Av. Cristo Redentor 4to Anillo, Santa Cruz',
  );
  String _deliveryType = 'DELIVERY';

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
    final invoices = provider.invoices;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Sección Carrito ─────────────────────────────────────────────────
          const Text(
            'Mi Carrito de Compras',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDarkWood,
            ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Tu carrito está vacío. Agrega muebles desde la pestaña "Tienda".',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else ...[
            ...items.map((cartItem) {
              final product = cartItem.product;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                  subtitle: Text(
                    '${product.woodType} • Subtotal: Bs ${cartItem.subtotal.toStringAsFixed(0)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => provider.updateCartQuantity(
                          product.id,
                          cartItem.quantity - 1,
                        ),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('${cartItem.quantity}'),
                      IconButton(
                        onPressed: () => provider.updateCartQuantity(
                          product.id,
                          cartItem.quantity + 1,
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
              );
            }),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Envío a domicilio'),
                          selected: _deliveryType == 'DELIVERY',
                          onSelected: (_) =>
                              setState(() => _deliveryType = 'DELIVERY'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Recojo en taller'),
                          selected: _deliveryType == 'PICKUP',
                          onSelected: (_) =>
                              setState(() => _deliveryType = 'PICKUP'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dirección o instrucciones de entrega',
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Carrito:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Bs ${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryWood,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final ok = await provider.checkoutCart(
                          advancePayment: total,
                          deliveryNotes: _notesCtrl.text.trim(),
                          deliveryType: _deliveryType,
                          deliveryAddress: _notesCtrl.text.trim(),
                        );
                        if (ok && context.mounted) {
                          widget.onOrderCompleted();
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirmar Solicitud de Compra'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 22),

          // ── Sección Mis Recibos / Facturas PDF ─────────────────────────────
          const Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryWood),
              SizedBox(width: 8),
              Text(
                'Mis Recibos y Facturas Oficiales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDarkWood,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (invoices.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Aún no tienes facturas emitidas. Al pagar una cotización aprobada, el recibo PDF aparecerá aquí.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ...invoices.map(
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Cliente: ${inv.clientName} (NIT: ${inv.clientNit})\nFecha: ${inv.issuedAt}',
                    style: const TextStyle(fontSize: 12),
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
      ),
    );
  }
}

// ── 4. ASISTENTE VIRTUAL PARA CLIENTES ──────────────────────────────────────

class _ClientAssistantTab extends StatefulWidget {
  const _ClientAssistantTab();

  @override
  State<_ClientAssistantTab> createState() => _ClientAssistantTabState();
}

class _ClientAssistantTabState extends State<_ClientAssistantTab> {
  final _controller = TextEditingController();
  final _whisperService = WhisperService();
  final _llmService = LlmService();

  bool _useOnlineAgent = true;
  bool _isRecording = false;
  bool _isThinking = false;
  final List<Map<String, String>> _messages = [
    {
      'sender': 'bot',
      'text':
          '¡Hola! Soy el asistente virtual de Carpintería El Roble. Puedo ayudarte a consultar el estado de tus pedidos, cotizaciones, disponibilidad de entregas y nuestro catálogo de muebles.',
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

    if (_useOnlineAgent) {
      try {
        final res = await provider.askOnlineAgent(
          query: text,
          sessionId: 'mobile-client-${provider.currentUser?.email ?? "cliente"}',
        );
        if (!mounted) return;
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': res.answer,
          });
          _isThinking = false;
        });
        return;
      } catch (_) {
        // Fallback automático a IA en dispositivo si no hay conexión
      }
    }

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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: AppTheme.primaryDarkWood,
          child: Row(
            children: [
              Icon(
                _useOnlineAgent ? Icons.cloud_done_rounded : Icons.memory_rounded,
                color: AppTheme.accentAmber,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _useOnlineAgent
                      ? 'Asistente Conectado en Línea'
                      : 'Asistente Local sin Internet',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              Switch(
                value: _useOnlineAgent,
                activeThumbColor: AppTheme.accentAmber,
                onChanged: (v) => setState(() => _useOnlineAgent = v),
              ),
              if (!ModelInstaller.isReady)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SplashPage()),
                    );
                  },
                  child: const Text(
                    'Modelos Voz',
                    style: TextStyle(
                      color: AppTheme.accentAmber,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
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
                onPressed: () => _sendQuestion('¿En qué estado están mis pedidos?'),
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.event_available_outlined, size: 16),
                label: const Text(
                  '¿Hay cupo de entrega mañana?',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () => _sendQuestion(
                  '¿Tienen disponibilidad para programar entrega mañana?',
                ),
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.calculate_outlined, size: 16),
                label: const Text(
                  '¿Cuánto cuesta una mesa de roble?',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () => _sendQuestion(
                  '¿Cuánto cuesta aproximadamente una mesa de comedor en madera roble?',
                ),
              ),
            ],
          ),
        ),
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
              );
            },
          ),
        ),
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
                    hintText: 'Pregunta por tu pedido, entrega o mueble...',
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
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accentAmber,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo_el_roble.png',
                        fit: BoxFit.cover,
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
                            'Cliente Registrado • Carpintería El Roble',
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
                            fontSize: 15.5,
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
                        ? 'Tu huella está vinculada a ${user?.email ?? ""}. Al iniciar sesión solo necesitarás escribir tu correo y poner tu huella dactilar, sin introducir tu contraseña.'
                        : 'Configura tu huella dactilar aquí para desbloquear tu cuenta en cualquier momento introduciendo únicamente tu correo electrónico y tu huella.',
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        provider.isUsingMock
                            ? Icons.cloud_off_rounded
                            : Icons.cloud_done_rounded,
                        color: provider.isUsingMock
                            ? Colors.orange.shade800
                            : Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Modo de Conexión y Sincronización',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDarkWood,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: provider.isUsingMock
                              ? Colors.orange.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          provider.isUsingMock ? 'OFFLINE' : 'ONLINE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: provider.isUsingMock
                                ? Colors.orange.shade900
                                : Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      provider.isForcedOffline
                          ? 'Modo Offline Activo (Base Local)'
                          : 'Modo Online Activo (Servidor en Red)',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      provider.isForcedOffline
                          ? 'Desconectado del servidor. Operando 100% con almacenamiento local del teléfono.'
                          : 'Conectado al servidor central para sincronizar en tiempo real.',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: !provider.isForcedOffline,
                    activeTrackColor: Colors.green.shade600,
                    onChanged: (online) async {
                      final messenger = ScaffoldMessenger.of(context);
                      await provider.setOfflineMode(!online);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            online
                                ? 'Modo Online activado: conectado a ${AppConfig.baseUrl}'
                                : 'Modo Offline activado: trabajando con base de datos local',
                          ),
                          backgroundColor: online
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                        ),
                      );
                    },
                  ),
                  const Divider(height: 16),
                  TextField(
                    controller: _urlController,
                    enabled: !provider.isForcedOffline,
                    decoration: const InputDecoration(
                      labelText: 'Dirección del Servidor',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final nextOffline = !provider.isForcedOffline;
                            await provider.setOfflineMode(nextOffline);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  nextOffline
                                      ? 'Desconectado: Modo Offline activado'
                                      : 'Conectado: Modo Online activado',
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            provider.isForcedOffline
                                ? Icons.wifi_rounded
                                : Icons.wifi_off_rounded,
                          ),
                          label: Text(
                            provider.isForcedOffline
                                ? 'Conectar Online'
                                : 'Pasar a Offline',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: provider.isForcedOffline
                              ? null
                              : () async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  await provider
                                      .updateBackendUrl(_urlController.text);
                                  _urlController.text = AppConfig.baseUrl;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Servidor actualizado: ${AppConfig.baseUrl}',
                                      ),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Guardar URL'),
                        ),
                      ),
                    ],
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
