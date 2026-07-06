import '../../../core/api/api_client.dart';

class BalanceItem {
  final int productId;
  final String productName;
  final String? sku;
  final String? unit;
  final double quantity;
  final int warehouseId;
  final String? warehouseName;
  final String? expiresAt;
  final int? batchId;

  const BalanceItem({
    required this.productId,
    required this.productName,
    this.sku,
    this.unit,
    required this.quantity,
    required this.warehouseId,
    this.warehouseName,
    this.expiresAt,
    this.batchId,
  });

  factory BalanceItem.fromJson(Map<String, dynamic> j) => BalanceItem(
        productId: j['product_id'] as int,
        productName: j['product_name'] as String? ?? '',
        sku: j['sku'] as String?,
        unit: j['unit'] as String?,
        quantity: (j['quantity'] as num).toDouble(),
        warehouseId: j['warehouse_id'] as int,
        warehouseName: j['warehouse_name'] as String?,
        expiresAt: j['expires_at'] as String?,
        batchId: j['batch_id'] as int?,
      );
}

class StockRepository {
  final ApiClient _api;

  StockRepository({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<BalanceItem>> fetchBalances({
    int? warehouseId,
    String? search,
    int page = 1,
    int pageSize = 50,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
    };
    if (warehouseId != null) params['warehouse_id'] = '$warehouseId';
    if (search != null && search.isNotEmpty) params['search'] = search;

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final data = await _api.skladGet('/balances?$query');
    final items = data['items'] as List? ?? [];
    return items
        .map((e) => BalanceItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> fetchWarehouse(int id) =>
      _api.skladGet('/warehouses/$id');

  Future<List<Map<String, dynamic>>> fetchWarehouses() async {
    final data = await _api.skladGet('/warehouses');
    final items = data['items'] as List? ?? (data is List ? data : []);
    return items.cast<Map<String, dynamic>>();
  }
}
