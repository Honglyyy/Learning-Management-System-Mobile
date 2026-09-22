import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/course_model.dart';

class CourseRepository {
  final ApiClient _api;

  CourseRepository(this._api);

  Future<List<CourseModel>> getCourses({
    String? query,
    int? categoryId,
    String? level,
    double? minRating,
    String? sort,
  }) async {
    final queryParams = <String, dynamic>{};
    if (query != null && query.trim().isNotEmpty) queryParams['query'] = query.trim();
    if (categoryId != null) queryParams['categoryId'] = categoryId;
    if (level != null && level != 'ALL_LEVELS') queryParams['level'] = level;
    if (minRating != null && minRating > 0) queryParams['minRating'] = minRating;
    if (sort != null && sort.isNotEmpty) queryParams['sort'] = sort;

    final response = await _api.get(
      ApiEndpoints.courses,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response is List) {
      return response.map((item) => CourseModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<CourseModel>> getFeatured() async {
    final response = await _api.get(ApiEndpoints.coursesFeatured);
    if (response is List) {
      return response.map((item) => CourseModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<CourseModel>> getPopular() async {
    final response = await _api.get(ApiEndpoints.coursesPopular);
    if (response is List) {
      return response.map((item) => CourseModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<CourseModel> getCourseById(int id) async {
    final response = await _api.get(ApiEndpoints.courseById(id));
    return CourseModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<CourseReview>> getReviews(int courseId) async {
    final response = await _api.get(ApiEndpoints.courseReviews(courseId));
    if (response is List) {
      return response.map((r) => CourseReview.fromJson(r as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> submitReview(int courseId, int rating, String reviewText) async {
    await _api.post(
      ApiEndpoints.courseReviewSubmit(courseId),
      data: {'rating': rating, 'reviewText': reviewText},
    );
  }

  Future<double> getCourseProgress(int courseId) async {
    final res = await _api.get(ApiEndpoints.courseProgress(courseId));
    if (res is num) return res.toDouble();
    if (res is Map && res.containsKey('progress')) {
      return (res['progress'] as num).toDouble();
    }
    return 0.0;
  }

  Future<List<int>> getLessonsStatus(int courseId) async {
    final res = await _api.get(ApiEndpoints.courseLessonsStatus(courseId));
    if (res is List) {
      return res.map((id) => (id as num).toInt()).toList();
    }
    return [];
  }

  // Wishlist / Favorites
  Future<List<CourseModel>> getFavorites() async {
    final response = await _api.get(ApiEndpoints.favorites);
    if (response is List) {
      return response.map((item) => CourseModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<bool> checkFavorite(int courseId) async {
    try {
      final res = await _api.get(ApiEndpoints.favoriteCheck(courseId));
      if (res is bool) return res;
      if (res is Map && res.containsKey('isFavorite')) return res['isFavorite'] == true;
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> addFavorite(int courseId) async {
    await _api.post(ApiEndpoints.favoriteById(courseId));
  }

  Future<void> removeFavorite(int courseId) async {
    await _api.delete(ApiEndpoints.favoriteById(courseId));
  }

  // Instructor Courses
  Future<List<CourseModel>> getInstructorCoursesMe() async {
    final response = await _api.get(ApiEndpoints.instructorCoursesMe);
    if (response is List) {
      return response.map((item) => CourseModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> createInstructorCourse(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.instructorCoursesMe, data: body);
  }

  Future<void> updateInstructorCourse(int id, Map<String, dynamic> body) async {
    await _api.put(ApiEndpoints.instructorCourseMeById(id), data: body);
  }

  Future<void> deleteInstructorCourse(int id) async {
    await _api.delete(ApiEndpoints.instructorCourseMeById(id));
  }

  // Admin Courses
  Future<void> createAdminCourse(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.courses, data: body);
  }

  Future<void> updateAdminCourse(int id, Map<String, dynamic> body) async {
    await _api.put(ApiEndpoints.courseById(id), data: body);
  }

  Future<void> deleteAdminCourse(int id) async {
    await _api.delete(ApiEndpoints.courseById(id));
  }

  Future<void> updateCourseStatus(int courseId, String status) async {
    await _api.patch(
      ApiEndpoints.courseStatus(courseId),
      data: {'status': status},
    );
  }
}
