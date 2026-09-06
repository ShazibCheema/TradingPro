import 'package:cloud_firestore/cloud_firestore.dart';

enum WithdrawalStatus { pending, approved, rejected }

class WithdrawalModel {
  final String withdrawalId;
  final String userId;
  final String userId7;
  final String userFullName;
  final String userEmail;
  final double amount;
  final String asset;
  final String network;
  final String walletAddress;
  final WithdrawalStatus status;
  final String? adminNote;
  final String? adminUid;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const WithdrawalModel({
    required this.withdrawalId,
    required this.userId,
    required this.userId7,
    required this.userFullName,
    required this.userEmail,
    required this.amount,
    required this.asset,
    required this.network,
    required this.walletAddress,
    required this.status,
    this.adminNote,
    this.adminUid,
    required this.createdAt,
    this.reviewedAt,
  });

  bool get isPending => status == WithdrawalStatus.pending;
  bool get isApproved => status == WithdrawalStatus.approved;
  bool get isRejected => status == WithdrawalStatus.rejected;

  factory WithdrawalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WithdrawalModel(
      withdrawalId: doc.id,
      userId: data['userId'] as String? ?? '',
      userId7: data['userId7'] as String? ?? '',
      userFullName: data['userFullName'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      amount: (data['amount'] as num? ?? 0).toDouble(),
      asset: data['asset'] as String? ?? '',
      network: data['network'] as String? ?? '',
      walletAddress: data['walletAddress'] as String? ?? '',
      status: WithdrawalStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'pending'),
        orElse: () => WithdrawalStatus.pending,
      ),
      adminNote: data['adminNote'] as String?,
      adminUid: data['adminUid'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userId7': userId7,
      'userFullName': userFullName,
      'userEmail': userEmail,
      'amount': amount,
      'asset': asset,
      'network': network,
      'walletAddress': walletAddress,
      'status': status.name,
      'adminNote': adminNote,
      'adminUid': adminUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }
}
