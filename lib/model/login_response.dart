import 'dart:convert';

LoginResponse loginResponseFromJson(String str) =>
    LoginResponse.fromJson(json.decode(str));

String loginResponseToJson(LoginResponse data) =>
    json.encode(data.toJson());

class LoginResponse {
  bool status;
  String message;
  Data? data; // nullable

  LoginResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    status: json["status"],
    message: json["message"],
    data: json["data"] != null ? Data.fromJson(json["data"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  int id;
  String name;
  String email;
  String mobile;
  int unreadCount;

  Data({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.unreadCount,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    id: int.tryParse(json["id"].toString()) ?? 0,
    name: json["name"] ?? "",
    email: json["email"] ?? "",
    mobile: json["mobile"] ?? "",

    unreadCount:
    int.tryParse(json["unread_count"]?.toString() ?? "0") ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "mobile": mobile,
    "unread_count": unreadCount,
  };
}