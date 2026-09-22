class CategoryModel {
  final int categoryId;
  final String category;

  CategoryModel({
    required this.categoryId,
    required this.category,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['categoryId'] as int? ?? json['id'] as int? ?? 0,
      category: json['category'] ?? json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'category': category,
      };
}
