import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/stock_repository.dart';
import '../../writeoff/presentation/writeoff_screen.dart';

final _stockRepo = Provider((_) => StockRepository());

final _balancesProvider =
    FutureProvider.family<List<BalanceItem>, String?>((ref, search) {
  return ref.read(_stockRepo).fetchBalances(search: search);
});

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  final _searchCtrl = TextEditingController();
  String? _search;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balances = ref.watch(_balancesProvider(_search));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Остатки'),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Поиск товара…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _search = null);
                    },
                  ),
              ],
              onChanged: (v) {
                setState(() => _search = v.isEmpty ? null : v);
              },
            ),
          ),
        ),
      ),
      body: balances.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('$e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(_balancesProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Нет остатков'))
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1),
                itemBuilder: (ctx, i) => _BalanceTile(
                  item: items[i],
                  onWriteOff: () => _openWriteOff(ctx, items[i]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openWriteOff(context, null),
        icon: const Icon(Icons.remove_circle_outline),
        label: const Text('Списать'),
      ),
    );
  }

  void _openWriteOff(BuildContext ctx, BalanceItem? item) {
    Navigator.of(ctx).push(MaterialPageRoute(
      builder: (_) => WriteOffScreen(preselectedItem: item),
    ));
  }
}

class _BalanceTile extends StatelessWidget {
  final BalanceItem item;
  final VoidCallback onWriteOff;

  const _BalanceTile({required this.item, required this.onWriteOff});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final low = item.quantity <= 5;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            low ? scheme.errorContainer : scheme.primaryContainer,
        child: Icon(
          Icons.medication_outlined,
          color: low ? scheme.onErrorContainer : scheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(item.productName,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        [
          if (item.sku != null) item.sku!,
          if (item.warehouseName != null) item.warehouseName!,
          if (item.expiresAt != null) 'до ${item.expiresAt!.substring(0, 10)}',
        ].join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${item.quantity} ${item.unit ?? 'шт'}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: low ? scheme.error : scheme.onSurface,
            ),
          ),
          if (low)
            Text('Мало',
                style: TextStyle(
                    fontSize: 11, color: scheme.error)),
        ],
      ),
      onTap: onWriteOff,
    );
  }
}
