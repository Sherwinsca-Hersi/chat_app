import 'dart:convert';

MessageResponse messageResponseFromJson(String str) => MessageResponse.fromJson(json.decode(str));

String messageResponseToJson(MessageResponse data) => json.encode(data.toJson());

class MessageResponse {
  bool status;
  List<Message> data;

  MessageResponse({
    required this.status,
    required this.data,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) => MessageResponse(
    status: json["status"],
    data: List<Message>.from(json["data"].map((x) => Message.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class Message {

  int id;
  int? active;
  int? isRead;
  int senderId;
  int receiverId;
  String senderName;
  String message;
  String type;
  String audioPath;
  String imagePath;
  String videoPath;
  String fileName;
  String filePath;
  DateTime createdAt;

  bool isFailed = false;

  Message({
    required this.id,
     this.active,
    this.isRead,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.message,
    required this.type,
    required this.audioPath,
    required this.imagePath,
    required this.videoPath,
    required this.fileName,
    required this.filePath,
    required this.createdAt,
    this.isFailed = false,

  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json["id"] ?? 0,
    active: json["active"] ?? 0,
    isRead: json["is_read"] ?? 0,
    senderId: int.parse(json["sender_id"].toString()),
    receiverId: int.parse(json["receiver_id"].toString()),
    message: json["message"]?.toString() ?? "",
    audioPath: json["audio_path"]?.toString() ?? "",
    imagePath: json["image_path"]?.toString() ?? "",
    videoPath: json["video_path"]?.toString() ?? "",
    fileName: json["file_name"]?.toString() ?? "",
    filePath: json["file_path"]?.toString() ?? "",
    senderName: json["sender_name"]?.toString() ?? "",
    type: json["type"]?.toString() ?? "",
    createdAt: DateTime.parse(json["created_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "active": active,
    "is_read": isRead,
    "sender_id": senderId,
    "receiver_id": receiverId,
    "message": message,
    "type" : type,
    "audio_path" : audioPath,
    "image_path" : imagePath,
    "created_at": createdAt.toIso8601String(),
  };
}
