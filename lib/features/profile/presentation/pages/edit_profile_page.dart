import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quanlybaohanh_app/core/theme/app_theme.dart';
import 'package:uuid/uuid.dart';
import 'package:quanlybaohanh_app/features/profile/presentation/pages/map_picker_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  
  DateTime? _dateOfBirth;
  String? _avatarUrl;
  Uint8List? _newAvatarBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (data != null) {
        _fullNameController.text = data['full_name'] ?? '';
        _addressController.text = data['address'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        if (data['date_of_birth'] != null) {
          _dateOfBirth = DateTime.parse(data['date_of_birth']);
        }
        _avatarUrl = data['avatar_url'];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải hồ sơ: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _newAvatarBytes = bytes;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      String? avatarPath = _avatarUrl;

      // Upload new avatar if selected
      if (_newAvatarBytes != null) {
        final fileName = '${const Uuid().v4()}.jpg';
        await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            _newAvatarBytes!,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
        
        avatarPath = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);
      }

      final updates = {
        'id': userId,
        'full_name': _fullNameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'date_of_birth': _dateOfBirth?.toIso8601String(),
        'avatar_url': avatarPath,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('profiles')
          .upsert(updates);
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi cập nhật: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openMapToPickAddress() async {
     final result = await Navigator.push(
       context,
       MaterialPageRoute(builder: (context) => const MapPickerPage()),
     );
     
     if (result != null && result is String) {
       setState(() {
         _addressController.text = result;
       });
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh Sửa Hồ Sơ')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _newAvatarBytes != null 
                          ? MemoryImage(_newAvatarBytes!) 
                          : (_avatarUrl != null ? NetworkImage(_avatarUrl!) : null) as ImageProvider?,
                      child: (_newAvatarBytes == null && _avatarUrl == null)
                          ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Chạm để đổi ảnh đại diện'),
                  const SizedBox(height: 24),

                  // Full Name
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return 'Họ tên phải có ít nhất 3 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth
                  TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Ngày sinh / Năm sinh',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: _dateOfBirth != null ? DateFormat.yMMMd().format(_dateOfBirth!) : ''
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateOfBirth ?? DateTime(1990),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _dateOfBirth = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Address with "Map" button
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Địa chỉ',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ),
                      IconButton(
                        onPressed: _openMapToPickAddress, // Placeholder for map action
                        icon: const Icon(Icons.map),
                        color: Colors.blue,
                        tooltip: 'Chọn từ Google Map',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.darkRed,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Lưu Thay Đổi'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
