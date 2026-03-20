import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyText extends StatelessWidget {
  const MyText({
    super.key,
    required this.title,
    this.textAlign,
    this.maxLines,
    this.softWrap,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.overflow,
    this.textDecoration,
  });
  final String title;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool? softWrap;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextOverflow? overflow;
  final TextDecoration? textDecoration;
  @override
  Widget build(BuildContext context) {
    return Text(
        title,
      style: GoogleFonts.montserrat(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        decoration: textDecoration ?? TextDecoration.none,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      softWrap: softWrap,
      overflow: overflow,
    );
  }
}
