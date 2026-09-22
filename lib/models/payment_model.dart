class PaymentModel {
  final int paymentId;
  final int? userId;
  final String? studentName;
  final int courseId;
  final String courseTitle;
  final num amount;
  final String provider;
  final String? providerReference;
  final String status;
  final dynamic createdAt;

  PaymentModel({
    required this.paymentId,
    this.userId,
    this.studentName,
    required this.courseId,
    required this.courseTitle,
    required this.amount,
    this.provider = 'ABA_PAYWAY',
    this.providerReference,
    this.status = 'PENDING',
    this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentId: json['paymentId'] as int? ?? json['id'] as int? ?? 0,
      userId: json['userId'] as int?,
      studentName: json['studentName'] ?? json['userName'],
      courseId: json['courseId'] as int? ?? 0,
      courseTitle: json['courseTitle'] ?? json['courseName'] ?? 'Course',
      amount: json['amount'] as num? ?? 0,
      provider: json['provider'] ?? 'ABA_PAYWAY',
      providerReference: json['providerReference'] ?? json['reference'],
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      createdAt: json['createdAt'],
    );
  }

  bool get isPaid => status == 'PAID';
  bool get isPending => status == 'PENDING';
  bool get isFailed => status == 'FAILED';
}

class CheckoutResponse {
  final int paymentId;
  final String? status;
  final String? paymentUrl;
  final String? providerReference;

  CheckoutResponse({
    required this.paymentId,
    this.status,
    this.paymentUrl,
    this.providerReference,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      paymentId: json['paymentId'] as int? ?? json['id'] as int? ?? 0,
      status: json['status'],
      paymentUrl: json['paymentUrl'] ?? json['checkoutUrl'] ?? json['url'],
      providerReference: json['providerReference'] ?? json['reference'],
    );
  }
}
