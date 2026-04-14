import 'dart:convert';

UserResponse userResponseFromJson(String str) => UserResponse.fromJson(json.decode(str));

String userResponseToJson(UserResponse data) => json.encode(data.toJson());

class UserResponse {
  bool status;
  List<Users> data;

  UserResponse({
    required this.status,
    required this.data,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
    status: json["status"],
    data: List<Users>.from(json["data"].map((x) => Users.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class Users {
  int id;
  String name;
  String mobile;
  String email;
  String lastMessage;
  String lastChatTime;
  int unreadCount;

  Users({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.lastMessage,
    required this.lastChatTime,
    required this.unreadCount,
  });

  factory Users.fromJson(Map<String, dynamic> json) => Users(
    id: int.tryParse(json["id"].toString()) ?? 0,
    name: json["name"] ?? "",
    mobile: json["mobile"] ?? "",
    email: json["email"] ?? "",
    lastChatTime: json["last_chat_time"] ?? "",
    lastMessage: json["last_message"] ?? "",

    /// 🔥 SAFE unread_count parsing
    unreadCount:
    int.tryParse(json["unread_count"]?.toString() ?? "0") ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "mobile": mobile,
    "email": email,
    "unread_count": unreadCount,
  };
}
