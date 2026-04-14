import 'dart:convert';
import 'dart:developer';
import 'package:chat_app/data/local_data.dart';
import 'package:chat_app/model/message_response.dart';
import 'package:http/http.dart' as http;

import '../api/api.dart';
import '../model/delete_response.dart';
import '../model/send_message_response.dart';
import '../model/user_response.dart';


class MessageRepository {
  ///User Fetch Data
  Future<UserResponse> getUserData({required int currentUser}) async {
    try {
      final body = {
        "data": "get_users",
        "current_user" : currentUser,
      };

      log("User Data request sending:$body");

      final response = await http.post(
        Uri.parse(ApiUrls.script),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserResponse.fromJson(data);

      } else {
        log("Messages Fetch Error");
        throw Exception();
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  ///Message Fetch Data
  Future<MessageResponse> getMessages({
    required dynamic otherUser,
  }) async {
    try {
      final body = {
        "data": "message_fetch",
        "sender_id" : localData.currentUserID,
        "receiver_id" : otherUser,
        // "last_id" : lastId,
      };

      log("Response Sended:$body");

      final response = await http.post(
        Uri.parse(ApiUrls.script),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MessageResponse.fromJson(data);

      }
      else {
        log("Messages Fetch Error");
        throw Exception();
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  ///Message Send Data
  Future<SendMessageResponse> sendMessages({
    required dynamic otherUser,
    required dynamic message,
    required int senderId,
    required String type,
    required String? audioPath,
    required String? imagePath,
    String? filePath,
    String? fileName,
    String? videoPath
  }) async {
    try {
      var uri = Uri.parse(ApiUrls.script);
      var request = http.MultipartRequest("POST", uri);

      request.fields["data"] = "send_message";
      request.fields["sender_id"] = senderId.toString();
      request.fields["receiver_id"] = otherUser.toString();
      request.fields["message"] = message.toString();
      request.fields["type"] = type;

      print("TYPE: $type");
      print("VIDEO PATH: $videoPath");
      print("IMAGE PATH: $imagePath");
      print("AUDIO PATH: $audioPath");
      print("FILE PATH: $filePath");

      /// VOICE
      if (audioPath != null && audioPath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath("audio", audioPath),
        );
      }

      /// IMAGE
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath("image", imagePath),
        );
      }

      /// 📎 FILE
      if (filePath != null && filePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "file",
            filePath,
            filename: fileName,
          ),
        );
      }

      /// 🎥 VIDEO (FIXED)
      if (videoPath != null && videoPath.isNotEmpty) {
        print("Sending video: $videoPath");

        request.files.add(
          await http.MultipartFile.fromPath(
            "video",
            videoPath,
            filename: videoPath.split('/').last,
          ),
        );
      }

      print("FILES COUNT: ${request.files.length}");

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      print("Response: $responseData");

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        return SendMessageResponse.fromJson(data);
      } else {
        throw Exception("Send failed");
      }
    } catch (e) {
      print("ERROR: $e");
      throw Exception(e);
    }
  }


  Future<DeleteResponse> deleteMessages({required dynamic messageId, required String active}) async {
    try {
      final body = {
        "data": "delete_message",
        "message_id" : messageId,
        "active" : active
      };

      log("Response Sended:$body");

      final response = await http.post(
        Uri.parse(ApiUrls.script),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DeleteResponse.fromJson(data);

      }
      else {
        log("Delete Messages Fetch Error");
        throw Exception();
      }
    } catch (e) {
      throw Exception(e);
    }
  }
}
