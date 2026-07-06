import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/api/api_client.dart';
import '../../stock/data/stock_repository.dart';

class WriteOffScreen extends ConsumerStatefulWidget {
  final BalanceItem? preselectedItem;
  const WriteOffScreen({super.key, this.preselectedItem});

  @override
  ConsumerState<WriteOffScreen> createState() => _WriteOffScreenState();
}

class _WriteOffScreenState extends ConsumerState<WriteOffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController(text: '1');
  final _reasonCtrl = TextEditingController();

  BalanceItem? _item;
  bool _scanning = false;
  bool _loading = false;
  String? _error;
  bool _done = false;

  final _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _item = widget.preselectedItem;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _SuccessView(onBack: () => Navigator.of(context).pop());
    if (_scanning) return _ScannerView(onDetect: _onBarcode);

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Списание')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product selection
              Card(
                child: ListTile(
                  leading: const Icon(Icons.medication_outlined),
                  title: Text(
                    _item?.productName ?? 'Выберите товар',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _item == null ? scheme.outline : null,
                    ),
                  ),
                  subtitle: _item != null
                      ? Text(
                          'Остаток: ${_item!.quantity} ${_item!.unit ?? 'шт'}',
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        tooltip: 'Сканировать штрихкод',
                        onPressed: () =>
                            setState(() => _scanning = true),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Quantity
              TextFormField(
                controller: _qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d*'))
                ],
                decoration: const InputDecoration(
                  labelText: 'Количество',
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (v) {
                  final d = double.tryParse(v ?? '');
                  if (d == null || d <= 0) return 'Введите количество';
                  if (_item != null && d > _item!.quantity) {
                    return 'Превышает остаток (${_item!.quantity})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Reason
              TextFormField(
                controller: _reasonCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Причина списания',
                  prefixIcon: Icon(Icons.note_outlined),
                  hintText: 'Использование в процедуре, истечение срока…',
                ),
              ),
              const SizedBox(height: 28),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_error!,
                      style: TextStyle(color: scheme.error),
                      textAlign: TextAlign.center),
                ),

              FilledButton.icon(
                onPressed: (_loading || _item == null)
                    ? null
                    : _submit,
                icon: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: const Text('Списать',
                    style: TextStyle(fontSize: 16)),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onBarcode(String barcode) {
    setState(() => _scanning = false);
    // TODO: resolve barcode → product via /api/v1/products?barcode=…
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Штрихкод: $barcode')),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.skladPost('/stock/write-offs', {
        'warehouse_id': _item!.warehouseId,
        'lines': [
          {
            if (_item!.batchId != null) 'batch_id': _item!.batchId,
            'product_id': _item!.productId,
            'quantity': double.parse(_qtyCtrl.text),
            if (_reasonCtrl.text.isNotEmpty)
              'reason': _reasonCtrl.text.trim(),
          }
        ],
      });
      setState(() {
        _loading = false;
        _done = true;
      });
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Ошибка соединения';
      });
    }
  }
}

class _ScannerView extends StatelessWidget {
  final ValueChanged<String> onDetect;
  const _ScannerView({required this.onDetect});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сканирование')),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.firstOrNull?.rawValue;
          if (barcode != null) onDetect(barcode);
        },
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onBack;
  const _SuccessView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 80, color: Colors.green),
            const SizedBox(height: 16),
            const Text('Списание проведено',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: onBack, child: const Text('Готово')),
          ],
        ),
      ),
    );
  }
}
