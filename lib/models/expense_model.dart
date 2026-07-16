class ExpenseModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String category;
  final String paymentMethod;
  final String notes;
  final String receiptImage;
  final DateTime date;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.notes,
    required this.receiptImage,
    required this.date,
    required this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? 'Others',
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      notes: json['notes'] ?? '',
      receiptImage: json['receiptImage'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'receiptImage': receiptImage,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
