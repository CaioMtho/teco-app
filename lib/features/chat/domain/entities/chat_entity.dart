class MessagePreview {
  final String id;
  final String? content;
  final String? senderId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  MessagePreview({
    required this.id,
    this.content,
    this.senderId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
}

class MessageEntity {
  final String id;
  final String chatId;
  final String senderId;
  final String? content;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  MessageEntity({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.content,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
}

class ProposalEntity {
  final String id;
  final String requestId;
  final String providerId;
  final double amount;
  final String? message;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  ProposalEntity({
    required this.id,
    required this.requestId,
    required this.providerId,
    required this.amount,
    this.message,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
}

class ChatEntity {
  final String id;
  final String requestId;
  final String requestTitle;
  final String requesterId;
  final String providerId;
  final String participantId;
  final String participantName;
  final String? participantAvatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final MessagePreview? lastMessage;

  ChatEntity({
    required this.id,
    required this.requestId,
    required this.requestTitle,
    required this.requesterId,
    required this.providerId,
    required this.participantId,
    required this.participantName,
    this.participantAvatarUrl,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.lastMessage,
  });
}
