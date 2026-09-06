import 'package:cloud_firestore/cloud_firestore.dart';

enum DepositStatus { pending, approved, rejected }

class DepositModel {
  final String depositId;
  final String userId;
  final String userId7;
  final String userFullName;
  final String userEmail;
  final String asset;
  final String network;
  final String walletAddress;
  final double amount;
  final String? screenshotUrl;
  final DepositStatus status;
  final String? adminNote;
  final String? adminUid;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const DepositModel({
    required this.depositId,
    required this.userId,
    required this.userId7,
    required this.userFullName,
    required this.userEmail,
    required this.asset,
    required this.network,
    required this.walletAddress,
    required this.amount,
    this.screenshotUrl,
    required this.status,
    this.adminNote,
    this.adminUid,
    required this.createdAt,
    this.reviewedAt,
  });

  bool get isPending => status == DepositStatus.pending;
  bool get isApproved => status == DepositStatus.approved;
  bool get isRejected => status == DepositStatus.rejected;

  factory DepositModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DepositModel(
      depositId: doc.id,
      userId: data['userId'] as String? ?? '',
      userId7: data['userId7'] as String? ?? '',
      userFullName: data['userFullName'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      asset: data['asset'] as String? ?? '',
      network: data['network'] as String? ?? '',
      walletAddress: data['walletAddress'] as String? ?? '',
      amount: (data['amount'] as num? ?? 0).toDouble(),
      screenshotUrl: data['screenshotUrl'] as String?,
      status: DepositStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'pending'),
        orElse: () => DepositStatus.pending,
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
      'asset': asset,
      'network': network,
      'walletAddress': walletAddress,
      'amount': amount,
      'screenshotUrl': screenshotUrl,
      'status': status.name,
      'adminNote': adminNote,
      'adminUid': adminUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }
}
