import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quanlybaohanh_app/core/theme/app_theme.dart';
import 'package:quanlybaohanh_app/features/warranty/data/models/warranty_model.dart';
import 'package:quanlybaohanh_app/features/warranty/presentation/pages/add_warranty_page.dart';
import 'package:quanlybaohanh_app/features/warranty/presentation/pages/warranty_search_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quanlybaohanh_app/core/constants/app_constants.dart';
import 'package:quanlybaohanh_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class HomePage extends StatefulWidget {
  final bool useAdminId;
  const HomePage({super.key, this.useAdminId = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();

  // Stream for real-time updates
  Stream<List<WarrantyModel>>? _warrantiesStream;
  bool _showExpiringOnly = false;
  
  // AdMob
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _setupStream();
    _loadAd();
  }
  
  void _loadAd() {
    if (kIsWeb) {
      // Ads not fully supported on Web in this setup, or requires AdSense. 
      // We will show a placeholder UI for Web in build method.
      return;
    }

    // Use platform-specific Test IDs
    final adUnitId = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ca-app-pub-3940256099942544/2934735716'
        : 'ca-app-pub-3940256099942544/6300978111';

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    )..load();
  }
  
  @override
  void dispose() {
    _bannerAd?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _setupStream() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    String? userId = currentUser?.id;

    if (userId == null) {
      if (widget.useAdminId) {
        userId = AppConstants.adminId;
      } else if (AppConstants.testUserEnabled) {
        userId = AppConstants.testUserId;
      }
    }

    // Debug Info: Let user know who we are fetching for
    // Using simple print for now, can be viewed in Debug Console
    debugPrint('HomePage: Fetching for UserID: $userId');
    
    // Also show a SnackBar for visibility on device
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userId == AppConstants.testUserId) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debug: Đang kiểm tra với Test User (0000...)'), duration: Duration(seconds: 2)),
        );
      } else if (userId != null && !widget.useAdminId) {
         // Show first 8 chars of ID
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debug: Đã đăng nhập với ID ${userId!.substring(0, 8)}...'), duration: const Duration(seconds: 2)),
        );
      }
    });

    if (userId == null) return;

    // Build Stream
    // We split the construction to avoid type inference issues with .stream() vs .eq() return types
    Stream<List<Map<String, dynamic>>> rawStream;
    
    if (!widget.useAdminId) {
      rawStream = Supabase.instance.client
          .from('warranties')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false);
    } else {
      rawStream = Supabase.instance.client
          .from('warranties')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false);
    }
    
    _warrantiesStream = rawStream.map((list) {
      return list.map((json) => WarrantyModel.fromJson(json)).toList();
    });
  }
  
  // Re-trigger stream setup (mainly for Search text change handling if we moved filter to local)
  // Or actually, we can just setState to trigger re-render if we Filter locally.
  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> _scanToSearch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SimpleScannerPage()),
    );
     if (result != null && result is String) {
      _searchController.text = result;
      _onSearchChanged();
    }
  }

  // ... (Keep _showWarrantyDetails and _buildDetailRow as they are)
  
  void _showWarrantyDetails(WarrantyModel warranty) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (warranty.productImageUrl != null)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          warranty.productImageUrl!,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    warranty.productName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkRed,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDetailRow(Icons.calendar_today, 'Ngày mua',
                      DateFormat.yMMMd().format(warranty.purchaseDate)),
                  _buildDetailRow(Icons.event_busy, 'Ngày hết hạn',
                      DateFormat.yMMMd().format(warranty.warrantyEndDate)),
                  if (warranty.productCode != null && warranty.productCode!.isNotEmpty)
                    _buildDetailRow(Icons.qr_code, 'Mã sản phẩm', warranty.productCode!),

                  const Divider(height: 32),
                  const Text('Thông tin người bán',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  
                  _buildDetailRow(Icons.store, 'Tên người bán', 
                      warranty.sellerName ?? 'N/A'),
                  _buildDetailRow(Icons.phone, 'Số điện thoại', 
                      warranty.sellerPhone ?? 'N/A', isPhone: true),
                  _buildDetailRow(Icons.location_on, 'Địa chỉ', 
                      warranty.sellerAddress ?? 'N/A'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                isPhone && value != 'N/A'
                    ? InkWell(
                        onTap: () async {
                          final Uri launchUri = Uri(
                            scheme: 'tel',
                            path: value,
                          );
                          if (await canLaunchUrl(launchUri)) {
                            await launchUrl(launchUri);
                          } else {
                            if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Không thể gọi số này')),
                              );
                            }
                          }
                        },
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    : Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảo Hành Của Tôi'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfilePage()),
                );
              } else if (value == 'logout') {
                 await Supabase.instance.client.auth.signOut();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Chỉnh sửa thành viên'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Đăng xuất'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<WarrantyModel>>(
        stream: _warrantiesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }

          final allWarranties = snapshot.data ?? [];
          final totalCount = allWarranties.length;
          final expiringSoonCount = allWarranties.where((w) {
            final days = w.warrantyEndDate.difference(DateTime.now()).inDays;
            return days >= 0 && days <= 90; // "Sắp hết hạn" -> within 90 days (3 months)
          }).length;

          // Apply filters for ListView
          List<WarrantyModel> displayedWarranties = allWarranties;

          // 1. Search Filter
          final query = _searchController.text.toLowerCase().trim();
          if (query.isNotEmpty) {
            displayedWarranties = displayedWarranties.where((item) {
              return item.productName.toLowerCase().contains(query) ||
                     (item.productCode?.toLowerCase().contains(query) ?? false) ||
                     (item.sellerName?.toLowerCase().contains(query) ?? false) ||
                     (item.sellerPhone?.toLowerCase().contains(query) ?? false) ||
                     (item.category.toLowerCase().contains(query));
            }).toList();
          }
          
          // 2. Expiring Soon Filter
          if (_showExpiringOnly) {
            displayedWarranties = displayedWarranties.where((w) {
               final days = w.warrantyEndDate.difference(DateTime.now()).inDays;
               return days >= 0 && days <= 90;
            }).toList();
          }

          return Column(
            children: [
               // --- STATS DASHBOARD ---
               Container(
                 padding: const EdgeInsets.all(16),
                 color: Colors.grey[100],
                 child: Row(
                   children: [
                     Expanded(
                       child: _buildStatCard(
                         title: 'Tổng sản phẩm',
                         count: totalCount,
                         color: Colors.blue,
                         onTap: () {
                           setState(() => _showExpiringOnly = false);
                         },
                         isSelected: !_showExpiringOnly,
                       ),
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: _buildStatCard(
                         title: 'Sắp hết hạn\n(< 3 tháng)',
                         count: expiringSoonCount,
                         color: Colors.orange,
                         onTap: () {
                           setState(() => _showExpiringOnly = true);
                         },
                         isSelected: _showExpiringOnly,
                       ),
                     ),
                   ],
                 ),
               ),

              // --- SEARCH BAR ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm theo tên, mã hoặc danh mục...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) => _onSearchChanged(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _scanToSearch,
                      icon: const Icon(Icons.qr_code_scanner),
                      color: AppTheme.primaryRed,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(12),
                           side: const BorderSide(color: AppTheme.primaryRed),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- LIST VIEW ---
              Expanded(
                child: displayedWarranties.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                                _showExpiringOnly 
                                  ? 'Không có sản phẩm nào sắp hết hạn'
                                  : 'Không tìm thấy bảo hành nào',
                              style: TextStyle(
                                  color: Colors.grey.withValues(alpha: 0.8),
                                  fontSize: 18),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayedWarranties.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final warranty = displayedWarranties[index];
                          final expirationDate = warranty.warrantyEndDate;
                          final isExpired =
                              expirationDate.isBefore(DateTime.now());
                          final daysRemaining =
                              expirationDate.difference(DateTime.now()).inDays;
  
                          return Card(
                            elevation: 2,
                             shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                             ),
                             child: InkWell(
                               onTap: () {
                                 _showWarrantyDetails(warranty);
                               },
                               borderRadius: BorderRadius.circular(12),
                               child: Padding(
                                 padding: const EdgeInsets.all(12),
                                 child: Row(
                                   children: [
                                     // Image Thumbnail
                                     Container(
                                       width: 60,
                                       height: 60,
                                       decoration: BoxDecoration(
                                         color: Colors.grey[200],
                                         borderRadius: BorderRadius.circular(8),
                                         image: warranty.productImageUrl != null
                                             ? DecorationImage(
                                                 image: NetworkImage(
                                                     warranty.productImageUrl!),
                                                 fit: BoxFit.cover,
                                               )
                                             : null,
                                       ),
                                       child: warranty.productImageUrl == null
                                           ? const Icon(Icons.image,
                                               color: Colors.grey)
                                           : null,
                                     ),
                                     const SizedBox(width: 16),
                                     
                                     // Details
                                     Expanded(
                                       child: Column(
                                         crossAxisAlignment:
                                             CrossAxisAlignment.start,
                                         children: [
                                           Text(
                                             warranty.productName,
                                             style: const TextStyle(
                                               fontWeight: FontWeight.bold,
                                               fontSize: 16,
                                             ),
                                           ),
                                           const SizedBox(height: 4),
                                           Text(
                                             'Hết hạn: ${DateFormat.yMMMd().format(expirationDate)}',
                                             style: TextStyle(
                                               fontSize: 14,
                                               color: isExpired
                                                   ? Colors.red
                                                   : Colors.green[700],
                                             ),
                                           ),
                                           Text(
                                             isExpired
                                                 ? 'Đã hết hạn'
                                                 : 'Còn $daysRemaining ngày',
                                             style: TextStyle(
                                               fontSize: 12,
                                                color: Colors.grey[600],
                                             ),
                                           ),
                                         ],
                                       ),
                                     ),
                                     
                                     if(warranty.productCode != null && warranty.productCode!.isNotEmpty)
                                       const Icon(Icons.qr_code, color: Colors.grey, size: 20),
                                   ],
                                 ),
                               ),
                             ),
                          );
                        },
                      ),
              ),
            ],
          );
        }
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddWarrantyPage(useAdminId: widget.useAdminId)),
          );
          // No need to manually refresh, Stream handles it!
        },
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: AppTheme.backgroundWhite,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              'Powered by PMVN',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey, 
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (kIsWeb)
            Container(
              height: 50,
              color: Colors.grey[200],
              alignment: Alignment.center,
              child: const Text('Banner Ad (Google AdSense) Placeholder'),
            )
          else if (_isAdLoaded && _bannerAd != null)
             SizedBox(
               height: _bannerAd!.size.height.toDouble(),
               width: _bannerAd!.size.width.toDouble(),
               child: AdWidget(ad: _bannerAd!),
             ),
        ],
      ),
    );
  }
}
