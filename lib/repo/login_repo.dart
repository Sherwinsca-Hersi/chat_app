import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

import '../api/api.dart';
import '../model/login_response.dart';


class LoginRepository {
  ///Login
  Future<LoginResponse> loginApi(String mobileNo, String password) async {
    try {
      final response = await http.post(Uri.parse(ApiUrls.script),
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json"
          },
          body: jsonEncode({
            'mobile': mobileNo,
            'password': password,
            'data': 'login'
          }));
      if (response.statusCode == 200) {
        final Map<String, dynamic> dataMap = jsonDecode(response.body);
        return LoginResponse.fromJson(dataMap);
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> dataMap = jsonDecode(response.body);
        return LoginResponse.fromJson(dataMap);
      } else {
        throw Exception('Failed to load loginApi');
      }
    } catch (e) {
      log("Error loginApi : $e");
      throw Exception();
    }
  }

  ///Sign Up
  Future<LoginResponse> signupApi(String mobileNo, String password, String name, String email) async {
    try {
      final response = await http.post(Uri.parse(ApiUrls.script),
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json"
          },
          body: jsonEncode({
            'name' : name,
            'mobile': mobileNo,
            'password': password,
            'email' : email,
            'data': 'signup'
          }));
      if (response.statusCode == 200) {
        final Map<String, dynamic> dataMap = jsonDecode(response.body);
        return LoginResponse.fromJson(dataMap);
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> dataMap = jsonDecode(response.body);
        return LoginResponse.fromJson(dataMap);
      } else {
        throw Exception('Failed to load signUpApi');
      }
    } catch (e) {
      log("Error SignUpApi : $e");
      throw Exception();
    }
  }
}
