class DocumentHistory {
  final String referenceCode;
  final String documentType;
  final String? pickupDate;
  final String status;
  final String? reason;
  final String? ctcNumber;
  final String? receiptNumber;
  final int? price;

  DocumentHistory({
    required this.referenceCode,
    required this.documentType,
    required this.status,
    this.pickupDate,
    this.reason,
    this.ctcNumber,
    this.receiptNumber,
    this.price,
  });

factory DocumentHistory.fromJson(Map<String, dynamic> json) {
  return DocumentHistory(
    referenceCode: json['reference_code'] ?? '',
    documentType: json['document_type'] ?? '',
    pickupDate: json['pickup_date'],
    status: json['status'] ?? '',
    reason: json['reason'],
    ctcNumber: json['ctc_number'],
    receiptNumber: json['receipt_number'],
    price: json['price'] != null ? int.tryParse(json['price'].toString()) : null,
  );
}

}
