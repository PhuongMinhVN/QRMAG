class WarrantyModel {
  final String? id;
  final String userId;
  final String productName;
  final DateTime purchaseDate;
  final int warrantyDurationMonths;
  final DateTime warrantyEndDate;
  final String? productImageUrl;
  final String? productCode;
  final String? sellerName;
  final String? sellerPhone;
  final String? sellerAddress;
  final String category;
  final DateTime createdAt;

  WarrantyModel({
    this.id,
    required this.userId,
    required this.productName,
    required this.purchaseDate,
    required this.warrantyDurationMonths,
    required this.warrantyEndDate,
    this.productImageUrl,
    this.productCode,
    this.sellerName,
    this.sellerPhone,
    this.sellerAddress,
    this.category = 'Other',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'product_name': productName,
      'purchase_date': purchaseDate.toIso8601String(),
      'warranty_duration_months': warrantyDurationMonths,
      'warranty_end_date': warrantyEndDate.toIso8601String(),
      'product_image_url': productImageUrl,
      'product_code': productCode,
      'seller_name': sellerName,
      'seller_phone': sellerPhone,
      'seller_address': sellerAddress,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WarrantyModel.fromJson(Map<String, dynamic> json) {
    return WarrantyModel(
      id: json['id'],
      userId: json['user_id'],
      productName: json['product_name'],
      purchaseDate: DateTime.parse(json['purchase_date']),
      warrantyDurationMonths: json['warranty_duration_months'],
      warrantyEndDate: DateTime.parse(json['warranty_end_date']),
      productImageUrl: json['product_image_url'],
      productCode: json['product_code'],
      sellerName: json['seller_name'],
      sellerPhone: json['seller_phone'],
      sellerAddress: json['seller_address'],
      category: json['category'] ?? 'Other',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
