import 'package:chat_app/res/colors.dart';
import 'package:chat_app/view_model/chat_provider.dart';
import 'package:chat_app/view_model/login_provider.dart';
import 'package:chat_app/views/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_)=> ChatProvider()),
    ChangeNotifierProvider(create: (_)=> LoginProvider()),
  ],child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColor.primaryColor,
        ),
        textTheme: GoogleFonts.latoTextTheme(),
        /// Text selection customization
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColor.primaryColor,                     // cursor color
          selectionColor: AppColor.primaryColor.withOpacity(0.3), // selected text background
          selectionHandleColor: AppColor.primaryColor,            // selection handle color
        ),
      ),

      home: const SplashScreen(),
    );
  }
}
