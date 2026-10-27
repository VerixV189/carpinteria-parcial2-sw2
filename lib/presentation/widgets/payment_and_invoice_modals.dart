import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:carpinteria_movil_sw2/domain/entities/entity.dart';
import 'package:carpinteria_movil_sw2/presentation/providers/app_provider.dart';
import 'package:carpinteria_movil_sw2/theme/app_theme.dart';

class PaymentAndInvoiceModals {
  static Future<void> previewInvoicePdf(
    BuildContext context,
    InvoiceEntity invoice,
  ) async {
    final provider = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Descargando PDF de Factura #${invoice.number}...'),
          duration: const Duration(seconds: 2),
        ),
      );
      final bytes = await provider.downloadInvoicePdf(invoice.id);
      await Printing.layoutPdf(
        name: 'Factura_${invoice.series}_${invoice.number}.pdf',
        onLayout: (_) async => bytes,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir el PDF: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  static Future<void> showPaymentGatewayModal(
    BuildContext context, {
    required String quotationId,
    required String description,
    required double amount,
  }) async {
    final cardCtrl = TextEditingController(text: '4242 4242 4242 4242');
    final holderCtrl = TextEditingController(
      text: AppScope.of(context).currentUser?.name.toUpperCase() ??
          'CLIENTE DEMO',
    );
    final monthCtrl = TextEditingController(text: '12');
    final yearCtrl = TextEditingController(text: '2028');
    final cvvCtrl = TextEditingController(text: '123');
    bool isProcessing = false;
    PaymentResultEntity? result;

    await showModalBottomSheet(
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
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: result != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: Colors.green.shade700,
                                size: 30,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  '¡Pago Capturado y Factura Emitida!',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryDarkWood,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Card(
                            color: Colors.green.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ID Pago: ${result!.id}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Transacción Gateway: ${result!.gatewayTransactionId}',
                                  ),
                                  Text(
                                    'Monto Pagado: Bs ${result!.amount.toStringAsFixed(2)} (${result!.currency})',
                                  ),
                                  Text(
                                    'Tarjeta: •••• ${result!.cardLast4} • Estado: ${result!.status}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Logs de Auditoría en AWS DynamoDB (PaymentLogs):',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.primaryDarkWood,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...result!.logs.map(
                            (l) => Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade900,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '[${l.stage}] ts:${l.timestamp} -> ${l.detail}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: Colors.greenAccent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Finalizar y Ver Mis Recibos'),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.credit_card_rounded,
                                    color: AppTheme.primaryWood,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Pasarela de Pago Segura (CU6)',
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
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryDarkWood,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total a debitar:',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  'Bs ${amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppTheme.accentAmber,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: cardCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Número de Tarjeta (Prueba: 4242...)',
                              prefixIcon: Icon(Icons.credit_card),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: holderCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del Titular',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: monthCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Mes (MM)',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: yearCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Año (YYYY)',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: cvvCtrl,
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'CVV',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    setModalState(() => isProcessing = true);
                                    final provider = AppScope.of(context);
                                    final res = await provider.processPayment(
                                      quotationId: quotationId,
                                      amount: amount,
                                      cardNumber: cardCtrl.text.trim(),
                                      cardHolder: holderCtrl.text.trim(),
                                      expiryMonth:
                                          int.tryParse(monthCtrl.text) ?? 12,
                                      expiryYear:
                                          int.tryParse(yearCtrl.text) ?? 2028,
                                      cvv: cvvCtrl.text.trim(),
                                    );
                                    setModalState(() {
                                      isProcessing = false;
                                      result = res;
                                    });
                                  },
                            icon: isProcessing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.lock_rounded),
                            label: Text(
                              isProcessing
                                  ? 'Procesando pago y generando factura...'
                                  : 'Pagar Bs ${amount.toStringAsFixed(0)} Ahora',
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
