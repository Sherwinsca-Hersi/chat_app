import 'package:chat_app/utils/sizedBox.dart';
import 'package:flutter/material.dart';

import '../colors.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField(
      {
        super.key,
        this.labelText, this.isRequired,
        this.keyboardType,
        required this.controller,
        this.maxLength,
        this.minLines,
        this.textInputAction,
        this.textCapitalization, this.validator, this.hintText, this.fillColor, this.borderRadius, this.obscureText, this.suffixIcon, this.prefixIcon,
        this.border, this.maxLines, this.onChanged,
      }
      );
  final  String? labelText;
  final bool? isRequired;
  final TextInputType? keyboardType;
  final TextEditingController controller;
  final int? maxLength;
  final int? minLines;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final TextCapitalization? textCapitalization;
  final String? Function(String?)? validator;
  final String? hintText;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final bool? obscureText;
  final IconButton? suffixIcon;
  final Icon? prefixIcon;
  final InputBorder? border;
  final ValueChanged<String>? onChanged;


  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      child: Column(
        children: [
          labelText != null && labelText!.isNotEmpty
              ? Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: labelText,
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isRequired == true)
                    TextSpan(
                      text: "*",
                      style: TextStyle(
                        color: AppColor.requiredColor.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          )
              : const SizedBox(),
          5.height,
          TextFormField(
            keyboardType: keyboardType,
            controller: controller,
            maxLength: maxLength,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization ?? TextCapitalization.none,
            obscureText: obscureText ?? false,
            validator: validator,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey.shade500
              ),
              fillColor: fillColor ?? Colors.grey.shade200,
              filled: true,
              counterText: '',
              suffixIcon: suffixIcon,
              prefixIcon : prefixIcon,
              border: border,
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: borderRadius ?? BorderRadius.zero,
              ),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    width: 2,
                    color: AppColor.primaryColor,
                  ),
                  borderRadius: BorderRadius.circular(10)),
              errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    width: 2,
                    color: AppColor.errorColor,
                  ),
                  borderRadius: borderRadius ?? BorderRadius.zero),
              focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    width: 2,
                    color: AppColor.errorColor,
                  ),
                  borderRadius: borderRadius ?? BorderRadius.zero),
              errorStyle: TextStyle(
                color: AppColor.errorColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
