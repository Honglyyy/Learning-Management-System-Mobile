class PaymentModel {
  final int paymentId;
  final int? userId;
  final String? studentName;
  final int courseId;
  final String courseTitle;
  final num amount;
  final num? originalAmount;
  final num? discountAmount;
  final bool isReEnrollmentDiscount;
  final int? accessDurationDays;
  final dynamic accessExpiresAt;
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
    this.originalAmount,
    this.discountAmount,
    this.isReEnrollmentDiscount = false,
    this.accessDurationDays,
    this.accessExpiresAt,
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
      originalAmount: json['originalAmount'] as num?,
      discountAmount: json['discountAmount'] as num?,
      isReEnrollmentDiscount: json['isReEnrollmentDiscount'] as bool? ?? false,
      accessDurationDays: (json['accessDurationDays'] as num?)?.toInt(),
      accessExpiresAt: json['accessExpiresAt'],
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

class CheckoutQuoteModel {
  final int courseId;
  final String courseTitle;
  final num originalPrice;
  final num finalPrice;
  final num discountAmount;
  final double discountPercentage;
  final bool isReEnrollmentDiscount;
  final int accessDurationDays;
  final bool isExpired;

  CheckoutQuoteModel({
    required this.courseId,
    required this.courseTitle,
    required this.originalPrice,
    required this.finalPrice,
    required this.discountAmount,
    required this.discountPercentage,
    required this.isReEnrollmentDiscount,
    required this.accessDurationDays,
    required this.isExpired,
  });

  factory CheckoutQuoteModel.fromJson(Map<String, dynamic> json) {
    return CheckoutQuoteModel(
      courseId: (json['courseId'] as num?)?.toInt() ?? 0,
      courseTitle: json['courseTitle'] ?? '',
      originalPrice: json['originalPrice'] as num? ?? 0,
      finalPrice: json['finalPrice'] as num? ?? 0,
      discountAmount: json['discountAmount'] as num? ?? 0,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      isReEnrollmentDiscount: json['isReEnrollmentDiscount'] as bool? ?? false,
      accessDurationDays: (json['accessDurationDays'] as num?)?.toInt() ?? 180,
      isExpired: json['isExpired'] as bool? ?? false,
    );
  }
}
