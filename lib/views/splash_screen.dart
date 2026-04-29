import 'package:chat_app/res/components/custom_container.dart';
import 'package:chat_app/views/user_screen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../view_model/login_provider.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {

      final loginData = Provider.of<LoginProvider>(context, listen: false);
      await loginData.initializeUserId();

      // 👇 wait 3 seconds
      await Future.delayed(const Duration(seconds: 3));

      checkFirstSeen(context);

    });

  }

  Future<void> checkFirstSeen(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLogin = prefs.getBool("login") ?? false;
    Widget nextScreen;
    if (isLogin == true) {
      print("$isLogin");
      nextScreen = const UserScreen();
    } else {
      print("$isLogin");
      nextScreen = LoginScreen();
    }
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      // MaterialPageRoute(builder: (context)=> nextScreen)
      PageTransition(
        type: PageTransitionType.fade,
        duration: const Duration(milliseconds: 3000),
        child: nextScreen,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CustomContainer(
          width: 400,
          height: 800,
          image: DecorationImage(image: AssetImage("assets/images/splash_screen_img.png"
              "",),fit: BoxFit.contain)
        ),
      ),
    );
  }
}
