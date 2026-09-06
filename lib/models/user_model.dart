import 'package:cloud_firestore/cloud_firestore.dart';

enum AccountStatus { active, suspended, pending }

class UserModel {
  final String uid;
  final String userId7;
  final String fullName;
  final String email;
  final String? photoUrl;
  final AccountStatus accountStatus;
  final String? role;
  final double balance;
  final double profit;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.userId7,
    required this.fullName,
    required this.email,
    this.photoUrl,
    required this.accountStatus,
    this.role,
    required this.balance,
    required this.profit,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => accountStatus == AccountStatus.active;
  bool get isSuspended => accountStatus == AccountStatus.suspended;
  bool get isAdmin => role == 'admin';

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      userId7: data['userId7'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      accountStatus: AccountStatus.values.firstWhere(
        (e) => e.name == (data['accountStatus'] as String? ?? 'active'),
        orElse: () => AccountStatus.pending,
      ),
      role: data['role'] as String?,
      balance: (data['balance'] as num? ?? 0).toDouble(),
      profit: (data['profit'] as num? ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId7': userId7,
      'fullName': fullName,
      'email': email,
      'photoUrl': photoUrl,
      'accountStatus': accountStatus.name,
      'balance': balance,
      'profit': profit,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? fullName,
    String? photoUrl,
    AccountStatus? accountStatus,
    double? balance,
    double? profit,
  }) {
    return UserModel(
      uid: uid,
      userId7: userId7,
      fullName: fullName ?? this.fullName,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      accountStatus: accountStatus ?? this.accountStatus,
      balance: balance ?? this.balance,
      profit: profit ?? this.profit,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
