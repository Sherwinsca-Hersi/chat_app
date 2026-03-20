import 'package:chat_app/utils/sizedBox.dart';
import 'package:chat_app/views/signup_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../res/colors.dart';
import '../res/components/customText.dart';
import '../res/components/custom_container.dart';
import '../res/components/custom_text_field.dart';
import '../view_model/login_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  void initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LoginProvider>(context, listen: false);
    });
  }
  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    return Consumer<LoginProvider>(
      builder: (context,loginProvider,child) {
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Scaffold(
              body: SingleChildScrollView(
                child: Center(
                    child: SafeArea(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                             CustomContainer(
                                 height: 300,
                                  image: DecorationImage(image: AssetImage("assets/images/login_vector_img.png"),fit: BoxFit.fitHeight,),
                             ),
                             Padding(
                               padding: const EdgeInsets.all(8.0),
                               child: MyText(title: "Login",color: AppColor.blackTextColor,fontSize: 20,fontWeight: FontWeight.bold,),
                             ),
                            CustomTextField(
                               keyboardType: TextInputType.number,
                               controller: loginProvider.mobileController,
                               maxLength: 10,
                               textInputAction: TextInputAction.next,
                               borderRadius: BorderRadius.circular(15),
                               validator: (value){
                                 if(value==null || value.isEmpty){
                                   return "Please enter the Mobile No !!";
                                 }
                                 else if(value.length < 10){
                                   return "Mobile No must be at least 10 characters";
                                 }
                                 return null;
                               },
                                 hintText: "Mobile No",
                                 fillColor: Colors.grey.shade200,
                                 prefixIcon: Icon(Icons.call,color: Colors.grey,),
                               ),
                            10.height,
                            CustomTextField(
                              keyboardType: TextInputType.number,
                              controller: loginProvider.passwordController,
                              maxLength: 16,
                              textInputAction: TextInputAction.next,
                              obscureText: loginProvider.isHidden ? true : false,
                              borderRadius: BorderRadius.circular(15),
                              validator: (value){
                                if(value==null || value.isEmpty){
                                  return "Please enter the Password !!";
                                }
                                else if(value.length < 8){
                                  return "Password must be between 8 to  16 characters";
                                }
                                return null;
                              },
                                  hintText: "Password",
                                  fillColor: Colors.grey.shade200,
                                  prefixIcon: Icon(Icons.password,color: Colors.grey,),
                                 suffixIcon: IconButton(onPressed: (){
                                    loginProvider.toggleVisibility();
                                 }, icon: Icon(CupertinoIcons.eye_fill,color: Colors.grey,))
                            ),
                            10.height,
                            SizedBox(
                              width: 300,
                              child:
                              // ElevatedButton(
                              //     onPressed: (){
                              //       if (_formKey.currentState!.validate()) {
                              //         log("Mobile No: ${loginProvider
                              //             .mobileController.text
                              //             .trim()}");
                              //         log("Password: ${loginProvider
                              //             .passwordController.text
                              //             .trim()}");
                              //         loginProvider.login(
                              //             mobileNo: loginProvider
                              //                 .mobileController.text
                              //                 .trim(),
                              //             password: loginProvider
                              //                 .passwordController.text
                              //                 .trim(),
                              //             context: context);
                              //       }
                              //       else{
                              //         // print("Please fill all the valid fields!!");
                              //         SnackBar(
                              //           backgroundColor: Colors.red,
                              //           content: MyText(title: "Please fill all the valid fields!!",
                              //             color: AppColor.whiteTextColor,),
                              //           duration: Duration(seconds: 2),
                              //         );
                              //       }
                              //     },
                              //     child: MyText(title: 'Login',fontWeight: FontWeight.bold,),
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: AppColor.primaryColor,
                              //       foregroundColor: Colors.white,
                              //       padding: EdgeInsets.symmetric(vertical: 15)
                              //     ),
                              // ),
                              RoundedLoadingButton(
                                  controller: loginProvider.loginButtonController,
                                color: AppColor.primaryColor,
                                onPressed: (){
                                    loginProvider.loginButtonController.start();
                                  if (_formKey.currentState!.validate()) {
                                    loginProvider.login(
                                        mobileNo: loginProvider
                                            .mobileController.text
                                            .trim(),
                                        password: loginProvider
                                            .passwordController.text
                                            .trim(),
                                        context: context);
                                  }
                                  else{
                                    // print("Please fill all the valid fields!!");
                                    // SnackBar(
                                    //   backgroundColor: Colors.red,
                                    //   content: MyText(title: "Please fill all the valid fields!!",
                                    //     color: AppColor.whiteTextColor,),
                                    //   duration: Duration(seconds: 2),
                                    // );
                                    loginProvider.loginButtonController.reset();
                                  }
                                },
                                child: MyText(title: 'Login',fontWeight: FontWeight.bold,color: AppColor.whiteTextColor,),
                              )
                            ),
                            SizedBox(
                              width: 300,
                              child: Align(
                                alignment: Alignment.centerRight,
                                  child: TextButton(
                                      onPressed: (){

                                      },
                                      child: MyText(title: "Forgot password ?",fontSize: 12,color: Colors.grey,fontWeight: FontWeight.bold,),
                                  ),
                              ),
                            ),
                            30.height,
                            SizedBox(
                              width: 300,
                              child: OutlinedButton(onPressed: (){
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>SignupScreen()));
                              },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Colors.black,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    )
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person,size: 14,color: AppColor.blackTextColor,),
                                  MyText(title: "Register as New User",color: AppColor.blackTextColor)
                                ],
                              )),
                            ),
                          ],
                        ),
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
