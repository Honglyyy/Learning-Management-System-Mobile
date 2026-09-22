import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final ApiClient _api;

  CategoryRepository(this._api);

  Future<List<CategoryModel>> getCategories() async {
    final response = await _api.get(ApiEndpoints.categories);
    if (response is List) {
      return response
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> createCategory(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.categories, data: body);
  }

  Future<void> updateCategory(int id, Map<String, dynamic> body) async {
    await _api.put(ApiEndpoints.categoryById(id), data: body);
  }

  Future<void> deleteCategory(int id) async {
    await _api.delete(ApiEndpoints.categoryById(id));
  }
}
