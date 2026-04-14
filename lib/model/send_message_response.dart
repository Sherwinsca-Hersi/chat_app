import 'dart:convert';

SendMessageResponse sendMessageResponseFromJson(String str) =>
    SendMessageResponse.fromJson(json.decode(str));

String sendMessageResponseToJson(SendMessageResponse data) =>
    json.encode(data.toJson());

class SendMessageResponse {
  bool status;
  int id;
  String message;
  String? filePath;
  String? fileName;
  String? audioPath;
  String? imagePath;
  String? videoPath;

  SendMessageResponse({
    required this.status,
    required this.id,
    required this.message,
    this.filePath,
    this.fileName,
    this.audioPath,
    this.imagePath,
    this.videoPath,
  });

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) =>
      SendMessageResponse(
        status: json["status"] ?? false,
        message: json["message"] ?? "",
        id: json["id"] ?? "",
        filePath: json["file_path"]?.toString(),
        fileName: json["file_name"]?.toString(),
        audioPath: json["audio_path"]?.toString(),
        imagePath: json["image_path"]?.toString(),
        videoPath: json["video_path"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "id": id,
    "message": message,
    "file_path": filePath,
    "file_name": fileName,
    "image_path": imagePath,
    "audio_path": audioPath,
    "video_path": videoPath,
  };
}