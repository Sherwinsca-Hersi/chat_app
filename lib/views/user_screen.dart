import 'dart:developer';
import 'package:chat_app/res/components/customText.dart';
import 'package:chat_app/res/components/custom_text_field.dart';
import 'package:chat_app/utils/screenUtils.dart';
import 'package:chat_app/utils/sizedBox.dart';
import 'package:chat_app/view_model/chat_provider.dart';
import 'package:chat_app/views/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../data/local_data.dart';
import '../res/colors.dart';
import '../res/components/custom_container.dart';
import 'login_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}



class _UserScreenState extends State<UserScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {

      // checkFirstSeen(context);

      // final loginProvider =
      // Provider.of<LoginProvider>(context, listen: false);
      //
      // await loginProvider.initializeUserId();

      log("Local User Id: ${localData.currentUserID}");

      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      chatProvider.UserData(
        context: context,
        currentUser: localData.currentUserID,
      );
      chatProvider.userSearchController.clear();
      chatProvider.initializeUsers();

    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context,chatProvider,child){
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: AppColor.containerColor,
              title: MyText(title:"Users",fontWeight: FontWeight.bold,),
              centerTitle: true,
              elevation: 5,
              actions: [
                IconButton(onPressed: (){
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    barrierColor: AppColor.blackTextColor.withOpacity(0.5),
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          "Logout",
                          style: GoogleFonts.lato(fontSize: 16, color: AppColor.primaryColor),
                        ),
                        content: Text(
                          "Are you sure you want to logout?",
                          style: GoogleFonts.lato(fontSize: 16, color: AppColor.blackTextColor),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("No", style: GoogleFonts.lato(color: AppColor.blackTextColor,fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: () async {
                              final SharedPreferences prefs = await SharedPreferences.getInstance();
                              prefs.setBool("login", false);
                              if (!context.mounted) return;

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    (route) => false,
                              );
                            },
                            child: Text("Yes", style: GoogleFonts.lato(color: AppColor.primaryColor,fontWeight: FontWeight.bold)),


                          ),
                        ],
                      );
                    },
                  );
                }, icon: Icon(Icons.logout))
              ],
            ),
            body: Column(
              children: [
                Container(
                  width: 380,
                  child: CustomTextField(
                      controller: chatProvider.userSearchController,
                      borderRadius: BorderRadius.circular(10),
                    hintText: "Search By Name,Mobile,Email etc..",
                    prefixIcon: Icon(Icons.search,color: Colors.grey[400],),
                    suffixIcon: IconButton(onPressed: (){
                      chatProvider.userSearchController.clear();
                      chatProvider.initializeUsers();
                    }, icon: Icon(Icons.clear,color: Colors.grey[400],size: 15,)),
                    onChanged: (value){
                        final searchValue = value.trim();
                        chatProvider.searchUsers(searchValue);
                    },
                  ),
                ),
                10.height,
                Expanded(
                  child: chatProvider.isLoading ?
                //   Center(
                //   child: CircularProgressIndicator(
                //     color: AppColor.primaryColor,
                //   ),
                // )

                  ListView.separated(
                      separatorBuilder: (context, index){
                        return 20.height;
                        },
                    itemCount: 7,
                      itemBuilder: (context, index){
                         return Shimmer.fromColors(
                             child: Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 15.0),
                               child: CustomContainer(
                                 width : 300,
                                 height: 100,
                                 borderRadius: BorderRadius.circular(10),
                                 backgroundColor: Colors.white,
                               ),
                             ),
                           baseColor: Colors.grey[300]!,
                           highlightColor: Colors.grey[100]!,
                         );
                      })
                      : ListView.separated(
                  separatorBuilder: (context, index){
                    return 0.height;
                  },
                  itemCount: chatProvider.filteredUsers!.length,
                  shrinkWrap: true,
                  // physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final users = chatProvider.filteredUsers![index];
                    return InkWell(
                      onTap: (){
                        // Navigator.pushReplacement(context,
                        //     MaterialPageRoute(builder: (context)=>
                        //         ChatPage(otherUserId : users.id, otherUserName: users.name
                        // )));

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              otherUserId: users.id,
                              otherUserName: users.name,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
                        child: CustomContainer(
                          width: ScreenUtils.screenWidth * 0.80,
                          height: 90,
                          backgroundColor: AppColor.containerColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: Offset(0, 3),
                            )
                          ],
                          widget: Center(
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColor.primaryColor,
                                child: MyText(
                                  title: chatProvider.getInitials(users.name),
                                  color: AppColor.whiteTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              title: MyText(title: users.name[0].toUpperCase() + users.name.substring(1),fontWeight: FontWeight.bold,),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MyText(title: users.mobile),
                                  // MyText(title: "aaa@gmail.com"),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: (){
                                      chatProvider.makePhoneCall(users.mobile);
                                    },
                                    icon: Icon(Icons.call,color: AppColor.primaryColor,)),
                                  3.width,
                                  IconButton(onPressed: (){
                                      chatProvider.openGmail(users.email);
                                  }, icon: Icon(Icons.mail,color: AppColor.primaryColor,),),
                                  3.width,
                                  if (users.unreadCount > 0)
                                    CircleAvatar(
                                    radius: 10,
                                    backgroundColor: AppColor.primaryColor,
                                    child: Text(
                                      users.unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                ),
              ],
            )
          ),
        );
      },
    );
  }
}
