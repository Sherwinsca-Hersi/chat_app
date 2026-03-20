

import 'dart:convert';

DeleteResponse deleteResponseFromJson(String str) => DeleteResponse.fromJson(json.decode(str));

String deleteResponseToJson(DeleteResponse data) => json.encode(data.toJson());

class DeleteResponse {
  bool status;
  String message;

  DeleteResponse({
    required this.status,
    required this.message,
  });

  factory DeleteResponse.fromJson(Map<String, dynamic> json) => DeleteResponse(
    status: json["status"],
    message: json["message"],
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
  };
}
