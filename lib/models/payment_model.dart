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
  final String? paymentUrl;
  final String status;
  final dynamic createdAt;
  final String? qrCode;
  final String? md5;
  final String? deepLink;
  final String? currency;
  final dynamic expiresAt;
  final dynamic paidAt;

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
    this.provider = '',
    this.providerReference,
    this.paymentUrl,
    this.status = 'PENDING',
    this.createdAt,
    this.qrCode,
    this.md5,
    this.deepLink,
    this.currency,
    this.expiresAt,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentId: (json['paymentId'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt(),
      studentName: json['studentName'] ?? json['userName'],
      courseId: (json['courseId'] as num?)?.toInt() ?? 0,
      courseTitle: json['courseTitle'] ?? json['courseName'] ?? 'Course',
      amount: json['amount'] as num? ?? 0,
      originalAmount: json['originalAmount'] as num?,
      discountAmount: json['discountAmount'] as num?,
      isReEnrollmentDiscount: json['isReEnrollmentDiscount'] as bool? ?? false,
      accessDurationDays: (json['accessDurationDays'] as num?)?.toInt(),
      accessExpiresAt: json['accessExpiresAt'],
      provider: json['provider']?.toString() ?? '',
      providerReference: json['providerReference'] ?? json['reference'],
      paymentUrl: json['paymentUrl'] ?? json['checkoutUrl'] ?? json['url'],
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      createdAt: json['createdAt'],
      qrCode: json['qrCode']?.toString(),
      md5: json['md5']?.toString(),
      deepLink: json['deepLink']?.toString(),
      currency: json['currency']?.toString(),
      expiresAt: json['expiresAt'],
      paidAt: json['paidAt'],
    );
  }

  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  bool get isPaid => status == 'PAID';
  bool get isPending => status == 'PENDING';
  bool get isExpired => status == 'EXPIRED';
  bool get isFailed => status == 'FAILED';
  bool get isBakong => provider.toUpperCase() == 'BAKONG_KHQR';
  DateTime? get expiresAtDate => parseDate(expiresAt);

  bool get hasUnexpiredQr {
    if (!isPending || qrCode == null || qrCode!.isEmpty) return false;
    final exp = expiresAtDate;
    if (exp == null) return true;
    return exp.toUtc().isAfter(DateTime.now().toUtc());
  }
}

class CheckoutResponse {
  final int paymentId;
  final int courseId;
  final String courseTitle;
  final num amount;
  final num? originalAmount;
  final num? discountAmount;
  final bool isReEnrollmentDiscount;
  final String? provider;
  final String? status;
  final String? paymentUrl;
  final String? providerReference;
  final String? qrCode;
  final String? md5;
  final String? deepLink;
  final String? currency;
  final dynamic expiresAt;
  final dynamic paidAt;
  final dynamic createdAt;

  CheckoutResponse({
    required this.paymentId,
    this.courseId = 0,
    this.courseTitle = 'Course',
    this.amount = 0,
    this.originalAmount,
    this.discountAmount,
    this.isReEnrollmentDiscount = false,
    this.provider,
    this.status,
    this.paymentUrl,
    this.providerReference,
    this.qrCode,
    this.md5,
    this.deepLink,
    this.currency,
    this.expiresAt,
    this.paidAt,
    this.createdAt,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      paymentId: (json['paymentId'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      courseId: (json['courseId'] as num?)?.toInt() ?? 0,
      courseTitle: json['courseTitle']?.toString() ?? json['courseName']?.toString() ?? 'Course',
      amount: json['amount'] as num? ?? 0,
      originalAmount: json['originalAmount'] as num?,
      discountAmount: json['discountAmount'] as num?,
      isReEnrollmentDiscount: json['isReEnrollmentDiscount'] as bool? ?? false,
      provider: json['provider']?.toString(),
      status: json['status']?.toString().toUpperCase(),
      paymentUrl: json['paymentUrl'] ?? json['checkoutUrl'] ?? json['url'],
      providerReference: json['providerReference'] ?? json['reference'],
      qrCode: json['qrCode']?.toString(),
      md5: json['md5']?.toString(),
      deepLink: json['deepLink']?.toString(),
      currency: json['currency']?.toString(),
      expiresAt: json['expiresAt'],
      paidAt: json['paidAt'],
      createdAt: json['createdAt'],
    );
  }

  PaymentModel toPaymentModel() {
    return PaymentModel(
      paymentId: paymentId,
      courseId: courseId,
      courseTitle: courseTitle,
      amount: amount,
      originalAmount: originalAmount,
      discountAmount: discountAmount,
      isReEnrollmentDiscount: isReEnrollmentDiscount,
      provider: provider ?? 'BAKONG_KHQR',
      providerReference: providerReference,
      paymentUrl: paymentUrl,
      status: (status ?? 'PENDING').toUpperCase(),
      createdAt: createdAt,
      qrCode: qrCode,
      md5: md5,
      deepLink: deepLink,
      currency: currency,
      expiresAt: expiresAt,
      paidAt: paidAt,
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
