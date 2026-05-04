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
