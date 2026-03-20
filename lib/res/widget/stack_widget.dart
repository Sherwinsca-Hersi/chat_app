import 'package:flutter/material.dart';
import '../components/customText.dart';
import '../components/custom_container.dart';

class StackWidget extends StatelessWidget {
  const StackWidget({super.key,
    required this.clipBorderRadius,
    required this.stackImage,
    required this.clipWidth,
    required this.clipHeight,
    required this.boxFit,
    required this.containerWidth,
    required this.containerHeight,
    this.gradientColors,
    this.bgColor,
    required this.containerBorderRadius,
    this.topValue,
    this.rightValue,
    this.bottomValue,
    this.leftValue,
    required this.stackText, this.fontSize, this.fontWeight, this.textColor,
  });
  
  final BorderRadius clipBorderRadius;
  final BorderRadius containerBorderRadius;
  final String stackImage;
  final String stackText;
  final double clipWidth;
  final double clipHeight;
  final BoxFit boxFit;
  final double containerWidth;
  final double containerHeight;
  final List<Color>? gradientColors;
  final  Color? bgColor;
  final double? topValue;
  final double? rightValue;
  final double? bottomValue;
  final double? leftValue;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // CustomContainer(
        //   containerWidth: 150,
        //   containerHeight: 150,
        //   borderRadius: BorderRadius.circular(200),
        //   bgColor: Colors.grey,
        // ),
        // Positioned(
        //   top: 7,
        //   left: 7,
        //   right: 7,
        //   bottom: 7,
        //   child: CircleAvatar(
        //     backgroundImage: AssetImage("assets/images/profile.jpg"),
        //   )
        // )
        ClipRRect(
          borderRadius: clipBorderRadius,
          child: Image.network(stackImage,
            width: clipWidth,
            height: clipHeight,
            fit: boxFit,
          ),
        ),
        CustomContainer(
          width: containerWidth,
          height: containerHeight,
          backgroundColor: bgColor,
          gradientColors: gradientColors,
          borderRadius: containerBorderRadius,
        ),
        Positioned(
            bottom: bottomValue,
            right: rightValue,
            top: topValue,
            left: leftValue,
            child: MyText(title: stackText,
              color: textColor,
              fontWeight: fontWeight,
              fontSize: fontSize,)
        ),
      ],
    );
  }
}
