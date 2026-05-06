class TransactionEntity {
  final String id;
  final String proposalId;
  final double amount;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TransactionEntity({
    required this.id,
    required this.proposalId,
    required this.amount,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isEscrow => status == 'escrow';
  bool get isReleased => status == 'released';
  bool get isRefunded => status == 'refunded';
}