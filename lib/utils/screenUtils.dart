import 'package:flutter/material.dart';

class ScreenUtils {
  // Default values to avoid LateInitializationError
  static double screenWidth = 0.0;
  static double screenHeight = 0.0;

  static bool isWebView = false;
  static bool isMobile = false;
  static bool isTablet = false;
  static bool isDesktop = false;

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;

    screenWidth = size.width;
    screenHeight = size.height;

    isWebView = size.width > size.height;

    isMobile = size.width < 600;
    isTablet = size.width >= 600 && size.width < 1024;
    isDesktop = size.width >= 1024;
  }
}