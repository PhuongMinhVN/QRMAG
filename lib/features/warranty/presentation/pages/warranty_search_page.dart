import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quanlybaohanh_app/core/theme/app_theme.dart';
import 'package:quanlybaohanh_app/features/warranty/data/models/warranty_model.dart';

class WarrantySearchPage extends StatefulWidget {
  const WarrantySearchPage({super.key});

  @override
  State<WarrantySearchPage> createState() => _WarrantySearchPageState();
}

class _WarrantySearchPageState extends State<WarrantySearchPage> {
  final _searchController = TextEditingController();
  List<WarrantyModel> _results = [];
  bool _isLoading = false;
  String _debugMsg = '';

  @override
  void initState() {
    super.initState();
    // Auto-search everything on load to see if DB has *any* data
    _performSearch(query: '');
  }

  Future<void> _performSearch({String query = ''}) async {
    setState(() {
      _isLoading = true;
      _debugMsg = 'Đang tìm kiếm...';
    });

    try {
      // We will perform a very broad search to ensure we find *something*
      var builder = Supabase.instance.client
          .from('warranties')
          .select();
      
      // If query provided, filter
      if (query.isNotEmpty) {
        builder = builder.or('product_name.ilike.%$query%,product_code.ilike.%$query%,seller_name.ilike.%$query%,seller_phone.ilike.%$query%');
      }
      
      // We do NOT filter by user_id here to debug validity of data.
      // We want to see EVERYTHING in the DB to confirm insertion worked.
      
      final List<dynamic> response = await builder.order('created_at', ascending: false).limit(50);
      
      setState(() {
        _results = response.map((json) => WarrantyModel.fromJson(json)).toList();
        _debugMsg = 'Tìm thấy ${_results.length} mục.';
      });
      
    } catch (e) {
      setState(() {
        _debugMsg = 'Lỗi: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm Kiếm Toàn Cầu')),
      body: Column(
        children: [
          // DEBUG INFO
          if (_debugMsg.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.yellow[100],
              padding: const EdgeInsets.all(8),
              child: Text(_debugMsg, style: const TextStyle(fontSize: 12, color: Colors.black)),
            ),
            
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tìm kiếm TẤT CẢ (Admin View)',
                hintText: 'Nhập tên, mã, v.v.',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _performSearch(query: _searchController.text.trim()),
                ),
              ),
              onSubmitted: (val) => _performSearch(query: val.trim()),
            ),
          ),
          
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty 
                    ? const Center(child: Text('Không tìm thấy kết quả trong CSDL'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          return ListTile(
                            leading: item.productImageUrl != null 
                              ? Image.network(item.productImageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                              : const Icon(Icons.image_not_supported),
                            title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mã: ${item.productCode ?? "N/A"}'),
                                Text('Hết hạn: ${DateFormat.yMMMd().format(item.warrantyEndDate)}'),
                                Text('ID Chủ sở hữu: ${item.userId}', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
