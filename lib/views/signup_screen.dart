import 'package:chat_app/res/colors.dart';
import 'package:chat_app/res/components/customText.dart';
import 'package:chat_app/utils/sizedBox.dart';
import 'package:chat_app/views/login_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

import '../res/components/custom_text_field.dart';
import '../view_model/login_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  @override
  Widget build(BuildContext context) {
    final _formSignupKey = GlobalKey<FormState>();
    return Consumer<LoginProvider>(
      builder: (context,loginProvider,child){
        return WillPopScope(
          onWillPop: () async {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
            return false;
          },
          child: Scaffold(
            appBar: AppBar(
              title: MyText(title: "Add New User",fontSize: 20,color: AppColor.whiteTextColor,),
              centerTitle: true,
              backgroundColor: AppColor.primaryColor,
            ),
            body: SingleChildScrollView(
              child: Center(
                child: Form(
                  key: _formSignupKey,
                  child: Column(
                    children: [
                      10.height,
                      /// NAME FIELD
                      CustomTextField(
                        keyboardType: TextInputType.text,
                        controller: loginProvider.nameController,
                        maxLength: 100,
                        labelText: "Name",
                        isRequired: true,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter the User Name";
                          }
                          return null;
                        },

                        hintText: "Name",
                        borderRadius: BorderRadius.circular(10),
                      ),
                      10.height,
                      /// MOBILE FIELD
                      CustomTextField(
                        keyboardType: TextInputType.number,
                        controller: loginProvider.phoneController,
                        maxLength: 10,
                        textInputAction: TextInputAction.next,
                        labelText: "Mobile No",
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter the Mobile No";
                          }

                          if (value.length != 10) {
                            return "Mobile number must be 10 digits";
                          }

                          return null;
                        },
                            hintText: "Mobile",
                            fillColor: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                        ),
                      10.height,
                      /// EMAIL FIELD
                      CustomTextField(
                        keyboardType: TextInputType.emailAddress,
                        controller: loginProvider.emailController,
                        maxLength: 80,
                        textInputAction: TextInputAction.next,
                        labelText: "Email",
                        isRequired: true,
                        validator: (value) {

                          if (value == null || value.isEmpty) {
                            return "Please enter Email";
                          }

                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );

                          if (!emailRegex.hasMatch(value)) {
                            return "Please enter valid Email";
                          }

                          return null;
                        },
                        hintText: "Email",
                        fillColor: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      10.height,
                      /// PASSWORD FIELD
                      CustomTextField(
                        keyboardType: TextInputType.text,
                        controller: loginProvider.passController,
                        maxLength: 16,
                        obscureText: loginProvider.isHidden,
                        textInputAction: TextInputAction.done,
                        labelText: "Password",
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter Password";
                          }
                          if (value.length < 8) {
                            return "Password must be 8-16 characters";
                          }
                          return null;
                        },
                          hintText: "Password",
                          fillColor: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                          suffixIcon: IconButton(
                            onPressed: () {
                              loginProvider.toggleVisibility();
                            },
                            icon: Icon(
                              CupertinoIcons.eye_fill,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      10.height,
                      /// SUBMIT BUTTON
                      Container(
                        width: 300,
                        child:
                        // ElevatedButton(
                        //
                        //   onPressed: () {
                        //
                        //     if (_formSignupKey.currentState!.validate()) {
                        //
                        //       // ScaffoldMessenger.of(context).showSnackBar(
                        //       //   SnackBar(
                        //       //     backgroundColor: Colors.green,
                        //       //     content: MyText(
                        //       //       title: "Form Submitted Successfully",
                        //       //       color: AppColor.whiteTextColor,
                        //       //     ),
                        //       //   ),
                        //       // );
                        //
                        //       loginProvider.SignUp(
                        //         mobileNo: loginProvider.phoneController.text.trim(),
                        //         password: loginProvider.passController.text.trim(),
                        //         name: loginProvider.nameController.text.trim(),
                        //         email: loginProvider.emailController.text.trim(),
                        //         context: context,
                        //       );
                        //
                        //     } else {
                        //
                        //       // ScaffoldMessenger.of(context).showSnackBar(
                        //       //   SnackBar(
                        //       //     backgroundColor: Colors.red,
                        //       //     content: MyText(
                        //       //       title: "Please fill all the valid fields!!",
                        //       //       color: AppColor.whiteTextColor,
                        //       //     ),
                        //       //   ),
                        //       // );
                        //
                        //     }
                        //
                        //   },
                        //
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: AppColor.primaryColor,
                        //   ),
                        //
                        //   child: Row(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: [
                        //       Icon(Icons.add,
                        //           color: AppColor.whiteTextColor,
                        //           weight: 700),
                        //       MyText(
                        //         title: "Add",
                        //         color: AppColor.whiteTextColor,
                        //         fontWeight: FontWeight.bold,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        RoundedLoadingButton(
                            controller: loginProvider.signUpButtonController,
                            color: AppColor.primaryColor,
                            onPressed: (){
                              loginProvider.signUpButtonController.start();
                              if (_formSignupKey.currentState!.validate()) {
                                // ScaffoldMessenger.of(context).showSnackBar(
                                //   SnackBar(
                                //     backgroundColor: Colors.green,
                                //     content: MyText(
                                //       title: "Form Submitted Successfully",
                                //       color: AppColor.whiteTextColor,
                                //     ),
                                //   ),
                                // );

                                loginProvider.SignUp(
                                  mobileNo: loginProvider.phoneController.text.trim(),
                                  password: loginProvider.passController.text.trim(),
                                  name: loginProvider.nameController.text.trim(),
                                  email: loginProvider.emailController.text.trim(),
                                  context: context,
                                );

                              } else {

                                // ScaffoldMessenger.of(context).showSnackBar(
                                //   SnackBar(
                                //     backgroundColor: Colors.red,
                                //     content: MyText(
                                //       title: "Please fill all the valid fields!!",
                                //       color: AppColor.whiteTextColor,
                                //     ),
                                //   ),
                                // );
                                loginProvider.signUpButtonController.reset();
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add,
                                    color: AppColor.whiteTextColor,
                                    weight: 700),
                                MyText(
                                  title: "Add",
                                  color: AppColor.whiteTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),)
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}
