import 'package:flutter/material.dart';

class CustomContainer extends StatelessWidget {
  const CustomContainer({
    super.key,
    this.backgroundColor,
    this.borderRadius,
    this.gradientColors,
    this.widget,
    this.width,
    this.height,
    this.elevation,
    this.boxShadow,
    this.margin,
    this.alignment,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.image, this.padding,
  });
 final Color? backgroundColor;
 final BorderRadius? borderRadius;
 final List<Color>? gradientColors;
 final Widget? widget;
 final double? width;
 final double? height;
 final double? elevation;
 final List<BoxShadow>? boxShadow;
 final EdgeInsets? margin;
 final EdgeInsets? padding;
 final Alignment? alignment;
 final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final DecorationImage? image;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        image: image,
        gradient: gradientColors != null && gradientColors!.length >= 2
            ? LinearGradient(colors: gradientColors!,begin: begin ,end: end,
        )
            : null,
        boxShadow: boxShadow,
      ),
      alignment: alignment,
      child:  widget,
    );
  }
}
