import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quanlybaohanh_app/core/constants/app_constants.dart';
import 'package:quanlybaohanh_app/core/theme/app_theme.dart';
import 'package:quanlybaohanh_app/features/warranty/data/models/warranty_model.dart';
import 'package:uuid/uuid.dart';

import 'package:quanlybaohanh_app/features/profile/presentation/pages/map_picker_page.dart';

class AddWarrantyPage extends StatefulWidget {
  final bool useAdminId;
  const AddWarrantyPage({super.key, this.useAdminId = false});

  @override
  State<AddWarrantyPage> createState() => _AddWarrantyPageState();
}

class _AddWarrantyPageState extends State<AddWarrantyPage> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _productCodeController = TextEditingController();
  final _sellerNameController = TextEditingController();
  final _sellerPhoneController = TextEditingController();
  final _sellerAddressController = TextEditingController();
  
  DateTime _purchaseDate = DateTime.now();
  int _warrantyDurationMonths = 12;
  String _selectedCategory = 'Other';
  
  // Changed from File to Uint8List for Web compatibility
  Uint8List? _imageBytes;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _productNameController.dispose();
    _productCodeController.dispose();
    _sellerNameController.dispose();
    _sellerPhoneController.dispose();
    _sellerAddressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _scanBarcode() async {
    // Navigate to a dedicated scanner page using mobile_scanner
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SimpleScannerPage()),
    );
    if (result != null && result is String) {
      setState(() {
        _productCodeController.text = result;
      });
    }
  }

  Future<void> _openMapToPickAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapPickerPage(),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _sellerAddressController.text = result;
      });
    }
  }

  Future<void> _submitWarranty() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null && _productCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ảnh hoặc quét mã')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      String? userId = currentUser?.id;
      if (userId == null) {
        if (widget.useAdminId) {
          userId = AppConstants.adminId;
        } else if (AppConstants.testUserEnabled) {
          userId = AppConstants.testUserId;
        }
      }

      if (userId == null) throw 'User not logged in';

      String? imageUrl;
      if (_imageBytes != null) {
        final fileName = '${const Uuid().v4()}.jpg';
        try {
           // Use uploadBinary for Web support (accepts Uint8List)
           await Supabase.instance.client.storage
            .from('warranty_images')
            .uploadBinary(
              fileName, 
              _imageBytes!,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
            
           imageUrl = Supabase.instance.client.storage
            .from('warranty_images')
            .getPublicUrl(fileName);
        } catch (e) {
           debugPrint('Image upload failed: $e');
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Cảnh báo: Tải ảnh thất bại. Đang lưu không có ảnh. Lỗi: $e')),
             );
           }
        }
      }

      final endDate = DateTime(
        _purchaseDate.year,
        _purchaseDate.month + _warrantyDurationMonths,
        _purchaseDate.day,
      );

      final warranty = WarrantyModel(
        userId: userId,
        productName: _productNameController.text.trim(),
        purchaseDate: _purchaseDate,
        warrantyDurationMonths: _warrantyDurationMonths,
        warrantyEndDate: endDate,
        productImageUrl: imageUrl,
        productCode: _productCodeController.text.trim(),
        sellerName: _sellerNameController.text.trim(),
        sellerPhone: _sellerPhoneController.text.trim(),
        sellerAddress: _sellerAddressController.text.trim(),
        category: _selectedCategory,
      );

      await Supabase.instance.client.from('warranties').insert(warranty.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm bảo hành thành công!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final endDate = DateTime(
      _purchaseDate.year,
      _purchaseDate.month + _warrantyDurationMonths,
      _purchaseDate.day,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Thêm Bảo Hành')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              GestureDetector(
                onTap: () => _showImagePickerOptions(),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.darkRed.withValues(alpha: 0.5)),
                    image: _imageBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_imageBytes!), // Use MemoryImage
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageBytes == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                            Text('Chạm để thêm ảnh'),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Product Name
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(labelText: 'Tên Sản Phẩm'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),

              // Product Code (QR/Barcode)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _productCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Mã Sản Phẩm / QR',
                        hintText: 'Chạm để quét mã',
                      ),
                      readOnly: true, // Prevent manual typing
                      onTap: _scanBarcode, // Trigger scanner on tap
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _scanBarcode,
                    icon: const Icon(Icons.qr_code_scanner, size: 30),
                    color: AppTheme.darkRed,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: ['Electronics', 'Appliances', 'Vehicle', 'Furniture', 'Fashion', 'Other']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Seller Information
              const Text('Thông Tin Người Bán (Tùy chọn)', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              TextFormField(
                controller: _sellerNameController,
                decoration: const InputDecoration(
                  labelText: 'Cửa hàng / Tên người bán',
                  prefixIcon: Icon(Icons.store),
                ),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _sellerPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sellerAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 1, // Single line better for Row
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _openMapToPickAddress,
                    icon: const Icon(Icons.map, size: 28),
                    color: AppTheme.primaryRed,
                    tooltip: 'Chọn từ bản đồ',
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
              const SizedBox(height: 16),

              // Purchase Date
              ListTile(
                title: const Text('Ngày mua'),
                subtitle: Text(DateFormat.yMMMd().format(_purchaseDate)),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.darkRed.withValues(alpha: 0.5)),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _purchaseDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _purchaseDate = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Warranty Duration
              const Text('Thời hạn bảo hành (Tháng)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [3, 6, 12, 24].map((months) {
                  return ChoiceChip(
                    label: Text('$months Tháng'),
                    selected: _warrantyDurationMonths == months,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _warrantyDurationMonths = months;
                        });
                      }
                    },
                    selectedColor: AppTheme.darkRed,
                    labelStyle: TextStyle(
                      color: _warrantyDurationMonths == months
                          ? Colors.white
                          : Colors.black,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Expiration Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.darkRed),
                ),
                child: Column(
                  children: [
                    const Text('Bảo hành hết hạn vào:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMd().format(endDate),
                      style: const TextStyle(
                          fontSize: 20,
                          color: AppTheme.darkRed,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(${endDate.difference(DateTime.now()).inDays} ngày còn lại)',
                      style: TextStyle(
                          color: endDate.isAfter(DateTime.now())
                              ? Colors.green
                              : Colors.red),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitWarranty,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Lưu Bảo Hành'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Thư viện ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Máy ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleScannerPage extends StatelessWidget {
  const SimpleScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Code')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              Navigator.pop(context, barcode.rawValue);
              break; // Return first detected code
            }
          }
        },
      ),
    );
  }
}
