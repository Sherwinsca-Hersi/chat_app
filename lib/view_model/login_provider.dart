import 'dart:convert';
import 'dart:developer';
import 'package:chat_app/views/user_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import '../data/local_data.dart';
import '../data/project_data.dart';
import '../model/login_response.dart';
import '../model/user_response.dart';
import '../repo/login_repo.dart';
import '../res/colors.dart';
import '../res/components/customText.dart';

class LoginProvider with ChangeNotifier{

  final LoginRepository _loginRepository = LoginRepository();

  bool _isLoading = false;
  bool _isError = false;

  bool get isLoading => _isLoading;

  bool get isError => _isError;

  //Login Response Data

  int _userId = 0;
  String _userName = '';
  String _userMobile = '';
  // String _cosId = '';
  String _userPassword = '';

  int get userId => _userId;
  String get userName => _userName;
  String get userMobile => _userMobile;
  // String get cosId => _cosId;
  String get userPassword => _userPassword;

  List<Users>? _userData=[];
  List<Users>? get userData => _userData;


  ///Visibility Password
  bool _isHidden = true;
  bool get isHidden => _isHidden;

  void toggleVisibility(){
    _isHidden = !isHidden;
    notifyListeners();
  }
  // Login Screen Controllers
  final TextEditingController  mobileController = TextEditingController();
  final TextEditingController  passwordController = TextEditingController();

  //Signup Screen Controllers
  final TextEditingController  nameController = TextEditingController();
  final TextEditingController  emailController = TextEditingController();
  final TextEditingController  phoneController = TextEditingController();
  final TextEditingController  passController = TextEditingController();
  
  ///Rounded Loading Button Controllers
  final RoundedLoadingButtonController signUpButtonController = RoundedLoadingButtonController();
  final RoundedLoadingButtonController loginButtonController = RoundedLoadingButtonController();

  ///Login
  Future<void> login(
      {required String mobileNo,
        required String password,
        required BuildContext context}) async {
    _isLoading = true;
    notifyListeners();

    try {

      final response = await _loginRepository.loginApi(mobileNo, password);

      log("Response in Login Provider:$response");

      if (response.status == true) {
        final Data? userData = response.data ?? null;

        _userId = userData!.id;
        _userName = userData.name;
        _userMobile = userData.mobile;
        // _cosId = admin.cosId ?? '';

        final prefs = await SharedPreferences.getInstance();
        prefs.setBool("login", true);
        await prefs.setInt('userId', _userId);
        await prefs.setString('userName', _userName);
        await prefs.setString('userMobile', _userMobile);

        // await prefs.setString('cosId', _cosId);

        localData.currentUserID = _userId;
        localData.currentUserName = _userName;
        localData.currentUserMobile = _userMobile;
        // localData.cosId = _cosId;

        log("currentUserID: ${localData.currentUserID}");
        log("currentUserName: ${localData.currentUserName}");
        log("currentUserMobile: ${localData.currentUserMobile}");
        // log("cosId: ${localData.cosId}");
        // enterLoginHistory(
        //     userId: userId, mobile: mobileNo, context: context);

        mobileController.clear();
        passwordController.clear();

        loginButtonController.reset();

        notifyListeners();

        Navigator.push(context,
            MaterialPageRoute(builder: (context) => UserScreen()));
      }  else if(response.status == false){
        log("Wrong Credentials, Please Try again");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: MyText(
              title: response.message,
              color: AppColor.whiteTextColor,
            ),
            duration: Duration(seconds: 2),
          ),
        );
        loginButtonController.reset();
        notifyListeners();
      }
    }
    catch (e) {
      _isLoading = false;
      log("'Something went wrong. Try Again'");
      loginButtonController.reset();
      notifyListeners();
    } finally {
      _isLoading = false;
      loginButtonController.reset();
      notifyListeners();
    }
  }

  Future<void> initializeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId') ?? 0;
    localData.currentUserID = prefs.getInt('userId') ?? 0;
    log("${localData.currentUserID}");
    localData.currentUserName =
        prefs.getString('userName') ?? ProjectData.projectTitle;
    localData.currentUserMobile = prefs.getString('userMobile') ?? '';
    // localData.cosId = prefs.getString('cosId') ?? '';
    notifyListeners();
  }

  Future<void> enterLoginHistory(
      {required int userId,
        required String mobile,
        required BuildContext context}) async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceDetails = '';
      String deviceOs = '';
      String deviceId = '';

      if (defaultTargetPlatform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceDetails = androidInfo.model;
        deviceOs = androidInfo.version.release;
        deviceId = androidInfo.id;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceDetails = iosInfo.utsname.machine;
        deviceOs = iosInfo.systemVersion;
        deviceId = iosInfo.identifierForVendor ?? '';
      }

      final response = await http.post(
        Uri.parse(ApiUrls.script),
        body: jsonEncode({
          'login_id': '0',
          'user_id': userId,
          'mobile': mobile,
          'app_version': ProjectData.projectVersion,
          'device_info': deviceDetails,
          'device_os': deviceOs,
          'device_id': deviceId,
          'platform': LocalData.platformKey,
          // 'cos_id': localData.cosId,
          'action': "d_insert_user_history",
          'created_by': localData.currentUserID
        }),
      );

      log("Response${response.body}");

      if (response.statusCode == 200) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => UserScreen()));
      } else {
        log("enterLoginHistory ${response.body}");
        throw Exception('Failed to load enterLoginHistory');
      }
    } catch (e) {
      log("Error enterLoginHistory : $e");
      throw Exception(e);
    }
  }


  ///Sign Up
  Future<void> SignUp(
      {required String mobileNo,
        required String password,
        required BuildContext context, required String name, required String email}) async {
    _isLoading = true;
    notifyListeners();

    try {

      final response = await _loginRepository.signupApi(mobileNo, password,name,email);

      log("Response in Sign Up Provider:$response");

      if (response.status == true) {
        final Data? userData = response.data;

        _userId = userData!.id;
        _userName = userData.name;
        _userMobile = userData.mobile;
        // _cosId = admin.cosId ?? '';

        final prefs = await SharedPreferences.getInstance();
        prefs.setBool("login", true);
        await prefs.setInt('userId', _userId);
        await prefs.setString('userName', _userName);
        await prefs.setString('userMobile', _userMobile);

        // await prefs.setString('cosId', _cosId);

        localData.currentUserID = _userId;
        localData.currentUserName = _userName;
        localData.currentUserMobile = _userMobile;
        // localData.cosId = _cosId;

        log("currentUserID: ${localData.currentUserID}");
        log("currentUserName: ${localData.currentUserName}");
        log("currentUserMobile: ${localData.currentUserMobile}");
        // log("cosId: ${localData.cosId}");
        // enterLoginHistory(
        //     userId: userId, mobile: mobileNo, context: context);

        nameController.clear();
        emailController.clear();
        phoneController.clear();
        passController.clear();

        signUpButtonController.reset();

        Navigator.push(context,
            MaterialPageRoute(builder: (context) => UserScreen()));
        notifyListeners();
      }
      else {
        signUpButtonController.reset();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: MyText(
              title: response.message,
              color: AppColor.whiteTextColor,
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    catch (e) {
      _isLoading = false;
      signUpButtonController.reset();
      log("'Something went wrong. Try Again'");
      notifyListeners();
    } finally {
      _isLoading = false;
      signUpButtonController.reset();
      notifyListeners();
    }
  }

}