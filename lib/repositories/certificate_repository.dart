import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/certificate_model.dart';

class CertificateRepository {
  final ApiClient _api;

  CertificateRepository(this._api);

  Future<List<CertificateModel>> getMyCertificates() async {
    final response = await _api.get(ApiEndpoints.certificatesMe);
    if (response is List) {
      return response
          .map((c) => CertificateModel.fromJson(c as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<CertificateModel> claimCertificate(int courseId) async {
    final response = await _api.post(ApiEndpoints.certificateClaim(courseId));
    return CertificateModel.fromJson(response as Map<String, dynamic>);
  }

  Future<CertificateVerification> verifyCertificate(String code) async {
    final response = await _api.get(ApiEndpoints.certificateVerify(code));
    return CertificateVerification.fromJson(response as Map<String, dynamic>);
  }
}
