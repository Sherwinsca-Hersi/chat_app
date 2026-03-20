import 'dart:io';
import 'package:chat_app/res/colors.dart';
import 'package:chat_app/utils/sizedBox.dart';
import 'package:chat_app/view_model/chat_provider.dart';
import 'package:chat_app/views/user_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/local_data.dart';
import '../res/components/customText.dart';
import '../res/components/custom_container.dart';
import '../res/widget/voice_message_bubble.dart';
import '../utils/intl.dart';

class ChatPage extends StatefulWidget {
  final int otherUserId;
  final String otherUserName;
  const ChatPage({super.key,required this.otherUserId, required this.otherUserName});



  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late ChatProvider chatProvider;

  @override
  void initState() {
    super.initState();

    chatProvider = Provider.of<ChatProvider>(context, listen: false); // store

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await chatProvider.MessageData(
        context: context,
        otherUser: widget.otherUserId,
      );
    });

    chatProvider.initPlayerListeners();
  }

  @override
  void deactivate() {
    chatProvider.stopAudio();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context,chatProvider,child){
        return WillPopScope(
          onWillPop: () async {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => UserScreen()),
            );
            return false;
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: AppColor.containerColor,
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColor.primaryColor,
                    child: MyText(
                      title: chatProvider.getInitials(widget.otherUserName),
                      color: AppColor.whiteTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  MyText(
                    title: widget.otherUserName[0].toUpperCase() + widget.otherUserName.substring(1),
                    fontWeight: FontWeight.bold,
                  )
                ],
              ),
              // centerTitle: true,
              elevation: 5,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserScreen()));
                },
              ),
              //   actions: [
              //     IconButton(onPressed: (){
              //       showDialog(
              //         context: context,
              //         barrierDismissible: false,
              //         barrierColor: AppColor.blackTextColor.withOpacity(0.5),
              //         builder: (BuildContext context) {
              //           return AlertDialog(
              //             title: MyText(
              //               title: "Logout",
              //               fontSize: 16, textColor: AppColor.primaryColor,
              //             ),
              //             content: MyText(
              //               title: "Are you sure you want to logout?",
              //               fontSize: 16, textColor: AppColor.blackTextColor
              //             ),
              //             actions: [
              //               TextButton(
              //                 onPressed: () => Navigator.pop(context),
              //                 child: MyText(title: "No", textColor: AppColor.blackTextColor,fontWeight: FontWeight.bold)
              //               ),
              //               TextButton(
              //                 onPressed: () async {
              //                   final SharedPreferences prefs = await SharedPreferences.getInstance();
              //                   prefs.setBool("login", false);
              //                   if (!context.mounted) return;
              //
              //                   Navigator.pushAndRemoveUntil(
              //                     context,
              //                     MaterialPageRoute(builder: (_) => const LoginScreen()),
              //                         (route) => false,
              //                   );
              //                 },
              //                 child: MyText(title: "Yes", textColor: AppColor.primaryColor,fontWeight: FontWeight.bold)
              //               ),
              //             ],
              //           );
              //         },
              //       );
              //     }, icon: Icon(Icons.logout))
              // ],
            ),
            body: CustomContainer(
              widget: Column(
                children: [
                  /// Messages
                  Expanded(
                    child: chatProvider.isLoading ?
                    Center(
                      child: CircularProgressIndicator(
                        color: AppColor.primaryColor,
                      ),
                    ):
                    SafeArea(
                      child: CustomContainer(
                        padding: const EdgeInsets.all(10),

                        /// ⭐ FILTERED LIST (Delete for me removed)
                        widget: (() {
                          final visibleMessages = chatProvider.messages
                              .where((m) => m.active != 2)
                              .toList();

                          /// EMPTY STATE
                          if (visibleMessages.isEmpty) {
                            return Center(
                              child: Image.asset(
                                "assets/images/splash_vector.png",
                                height: 600,
                              ),
                            );
                          }

                          return Align(
                            alignment: Alignment.topCenter,
                            child: ListView.builder(
                              controller: chatProvider.chatScrollController,
                              itemCount: visibleMessages.length,
                              reverse: true,
                              shrinkWrap: true,

                              itemBuilder: (context, index) {

                                final msg =
                                visibleMessages[visibleMessages.length - 1 - index];

                                final String loggedInUserId =
                                localData.currentUserID.toString();

                                bool isMe =
                                    msg.senderId.toString().trim() ==
                                        loggedInUserId.trim();

                                /// ✅ DATE HEADER LOGIC (using visible list)
                                bool showDateHeader = false;

                                if (index == visibleMessages.length - 1) {
                                  showDateHeader = true;
                                } else {
                                  final previous =
                                  visibleMessages[visibleMessages.length - 2 - index];

                                  if (msg.createdAt.day != previous.createdAt.day ||
                                      msg.createdAt.month != previous.createdAt.month ||
                                      msg.createdAt.year != previous.createdAt.year) {
                                    showDateHeader = true;
                                  }
                                }

                                return Column(
                                  key: ValueKey(msg.id),
                                  children: [

                                    /// DATE HEADER
                                    if (showDateHeader)
                                      Padding(
                                        padding:
                                        const EdgeInsets.symmetric(vertical: 10),
                                        child: Center(
                                          child: CustomContainer(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 5),
                                            backgroundColor:
                                            AppColor.dateFormatColor.shade300,
                                            borderRadius: BorderRadius.circular(5),
                                            widget: MyText(
                                              title:
                                              formatDateHeader(msg.createdAt),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),

                                    /// MESSAGE ROW
                                    Row(
                                      mainAxisAlignment:
                                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        /// ================= RECEIVED (LEFT) =================
                                        if (!isMe) ...[
                                          /// RECEIVER PROFILE
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: AppColor.primaryColor,
                                            child: MyText(
                                              title: chatProvider.getInitials(msg.senderName),
                                              color: AppColor.whiteTextColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          /// MESSAGE BUBBLE
                                          GestureDetector(
                                            onLongPress: () {
                                              void _showDeleteOptions(BuildContext context, msg) {
                                                showModalBottomSheet(
                                                  context: context,
                                                  builder: (_) => Wrap(
                                                    children: [
                                                      ListTile(
                                                        leading: const Icon(Icons.delete),
                                                        title: const Text('Delete for me'),
                                                        onTap: () async {
                                                          Navigator.pop(context);
                                                          await chatProvider.DeleteMessage(
                                                            messageId: msg.id,
                                                            active: '2',
                                                            context: context,
                                                          );
                                                        },
                                                      ),
                                                      if (msg.senderId == localData.currentUserID)
                                                        ListTile(
                                                          leading: const Icon(Icons.delete_forever),
                                                          title: const Text('Delete for everyone'),
                                                          onTap: () async {
                                                            Navigator.pop(context);
                                                            await chatProvider.DeleteMessage(
                                                              messageId: msg.id,
                                                              active: '3',
                                                              context: context,
                                                            );
                                                          },
                                                        ),
                                                      ListTile(
                                                        leading: const Icon(Icons.close),
                                                        title: const Text('Cancel'),
                                                        onTap: () => Navigator.pop(context),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }

                                              _showDeleteOptions(context, msg);
                                            },

                                            child: CustomContainer(
                                              margin: const EdgeInsets.symmetric(vertical: 5),
                                              padding: const EdgeInsets.all(6),
                                              backgroundColor: AppColor.receivedMsgColor,
                                              borderRadius: BorderRadius.circular(10),

                                              widget: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth:
                                                  MediaQuery.of(context).size.width * 0.60,
                                                ),

                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                                  children: [
                                                    /// ⭐ ACTIVE MESSAGE
                                                    if (msg.active == 1 ||
                                                        msg.active == null ||
                                                        msg.active == 0) ...[

                                                      /// IMAGE
                                                      if (msg.type == "image" &&
                                                          msg.imagePath.isNotEmpty)
                                                        Flexible(
                                                          child: ConstrainedBox(
                                                            constraints: BoxConstraints(
                                                              maxWidth:
                                                              MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                                  0.5,
                                                              minWidth: 150,
                                                              minHeight: 200,
                                                            ),
                                                            child: GestureDetector(
                                                              onTap: () {},
                                                              child: msg.imagePath
                                                                  .startsWith("/data/")
                                                                  ? Image.file(
                                                                File(msg.imagePath),
                                                                width: 180,
                                                                height: 200,
                                                                fit: BoxFit.cover,
                                                              )
                                                                  : Image.network(
                                                                chatProvider
                                                                    .getImageUrl(
                                                                    msg.imagePath),
                                                                fit: BoxFit.cover,
                                                              ),
                                                            ),
                                                          ),
                                                        ),

                                                      /// VOICE
                                                      if (msg.type == "voice")
                                                        Flexible(
                                                          child: VoiceMessageBubble(
                                                            audioPath: msg.audioPath,
                                                          ),
                                                        ),

                                                      /// TEXT
                                                      if (msg.type == "text")
                                                        Flexible(
                                                          child: MyText(
                                                            title: msg.message,
                                                            color:
                                                            AppColor.whiteTextColor,
                                                            softWrap: true,
                                                            maxLines: null,
                                                          ),
                                                        ),
                                                    ]

                                                    /// ⭐ DELETE FOR EVERYONE
                                                    else if (msg.active == 3) ...[
                                                      Flexible(
                                                        child: MyText(
                                                          title:
                                                          "This message was deleted",
                                                          color: Colors.grey.shade300,
                                                        ),
                                                      ),
                                                    ],

                                                    /// ERROR ICON
                                                    if (msg.isFailed) ...[
                                                      const SizedBox(width: 6),
                                                      GestureDetector(
                                                        onTap: () {
                                                          chatProvider
                                                              .resendMessage(msg);
                                                        },
                                                        child: const Icon(
                                                          Icons.error,
                                                          color: Colors.red,
                                                          size: 16,
                                                        ),
                                                      )
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          /// TIME (AFTER BUBBLE)
                                          MyText(
                                            title: formatMessageTime(msg.createdAt),
                                            color: AppColor.receivedMsgColor,
                                            fontSize: 10,
                                          ),
                                        ],

                                        /// ================= SENT (RIGHT) =================
                                        if (isMe) ...[

                                          /// TIME FIRST
                                          MyText(
                                            title: formatMessageTime(msg.createdAt),
                                            color: AppColor.receivedMsgColor,
                                            fontSize: 10,
                                          ),
                                          3.width,
                                          if (isMe)
                                            Icon(
                                              Icons.done_all,
                                              size: 16,
                                              color: msg.isRead == 1 ? Colors.blue : Colors.grey,
                                            ),

                                          const SizedBox(width: 5),

                                          /// MESSAGE BUBBLE
                                          GestureDetector(
                                            onLongPress: () {
                                              void _showDeleteOptions(BuildContext context, msg) {
                                                showModalBottomSheet(
                                                  context: context,
                                                  builder: (_) => Wrap(
                                                    children: [
                                                      ListTile(
                                                        leading: const Icon(Icons.delete),
                                                        title: const Text('Delete for me'),
                                                        onTap: () async {
                                                          Navigator.pop(context);
                                                          await chatProvider.DeleteMessage(
                                                            messageId: msg.id,
                                                            active: '2',
                                                            context: context,
                                                          );
                                                        },
                                                      ),
                                                      if (msg.senderId == localData.currentUserID)
                                                        ListTile(
                                                          leading: const Icon(Icons.delete_forever),
                                                          title: const Text('Delete for everyone'),
                                                          onTap: () async {
                                                            Navigator.pop(context);
                                                            await chatProvider.DeleteMessage(
                                                              messageId: msg.id,
                                                              active: '3',
                                                              context: context,
                                                            );
                                                          },
                                                        ),
                                                      ListTile(
                                                        leading: const Icon(Icons.close),
                                                        title: const Text('Cancel'),
                                                        onTap: () => Navigator.pop(context),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }

                                              _showDeleteOptions(context, msg);
                                            },

                                            child: CustomContainer(
                                              margin: const EdgeInsets.symmetric(vertical: 5),
                                              padding: const EdgeInsets.all(6),
                                              backgroundColor: AppColor.sendedMsgColor,
                                              borderRadius: BorderRadius.circular(10),

                                              widget: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth:
                                                  MediaQuery.of(context).size.width * 0.60,
                                                ),

                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                                  children: [

                                                    /// ⭐ ACTIVE MESSAGE
                                                    if (msg.active == 1 ||
                                                        msg.active == null ||
                                                        msg.active == 0) ...[

                                                      if (msg.type == "image" &&
                                                          msg.imagePath.isNotEmpty)
                                                        Flexible(
                                                          child: ConstrainedBox(
                                                            constraints: BoxConstraints(
                                                              maxWidth:
                                                              MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                                  0.5,
                                                              minWidth: 150,
                                                              minHeight: 200,
                                                            ),
                                                            child: msg.imagePath
                                                                .startsWith("/data/")
                                                                ? Image.file(
                                                              File(msg.imagePath),
                                                              width: 180,
                                                              height: 200,
                                                              fit: BoxFit.cover,
                                                            )
                                                                : Image.network(
                                                              chatProvider.getImageUrl(msg.imagePath),
                                                              fit: BoxFit.cover,

                                                              loadingBuilder: (context, child, loadingProgress) {
                                                                if (loadingProgress == null) return child;

                                                                return const SizedBox(
                                                                  height: 200,
                                                                  child: Center(child: CircularProgressIndicator()),
                                                                );
                                                              },

                                                              errorBuilder: (context, error, stackTrace) {
                                                                return const SizedBox(
                                                                  height: 200,
                                                                  child: Center(child: Icon(Icons.broken_image)),
                                                                );
                                                              },
                                                            )
                                                          ),
                                                        ),

                                                      if (msg.type == "voice")
                                                        Flexible(
                                                          child: VoiceMessageBubble(
                                                            audioPath: msg.audioPath,
                                                          ),
                                                        ),

                                                      if (msg.type == "text")
                                                        Flexible(
                                                          child: MyText(
                                                            title: msg.message,
                                                            color:
                                                            AppColor.whiteTextColor,
                                                            softWrap: true,
                                                            maxLines: null,
                                                          ),
                                                        ),
                                                    ]

                                                    else if (msg.active == 3) ...[
                                                      Flexible(
                                                        child: MyText(
                                                          title:
                                                          "This message was deleted",
                                                          color: Colors.grey.shade300,
                                                        ),
                                                      ),
                                                    ],

                                                    if (msg.isFailed) ...[
                                                      const SizedBox(width: 6),
                                                      GestureDetector(
                                                        onTap: () {
                                                          chatProvider
                                                              .resendMessage(msg);
                                                        },
                                                        child: const Icon(
                                                          Icons.error,
                                                          color: Colors.red,
                                                          size: 16,
                                                        ),
                                                      )
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    )
                                  ],
                                );
                              },
                            ),
                          );
                        })(),
                      ),
                    ),
                  ),
                  /// Bottom input area
                  CustomContainer(
                    padding: const EdgeInsets.all(8),
                    widget: Row(
                      children: [
                        /// TextField
                        Expanded(
                          child: chatProvider.isRecording
                              ? Container(
                            height: 55,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColor.typeFieldColor,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                /// Delete Recording
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    chatProvider.deleteRecording();
                                  },
                                ),

                                /// Recording Timer
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      chatProvider.formatDuration(
                                          chatProvider.recordingDuration),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                /// Stop Recording
                                IconButton(
                                  icon: const Icon(Icons.stop_circle, color: Colors.red),
                                  onPressed: () {
                                    chatProvider.stopRecording(
                                        widget.otherUserId, context);
                                  },
                                ),
                              ],
                            ),
                          )
                              : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColor.typeFieldColor,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [

                                /// TEXT FIELD
                                Expanded(
                                  child: TextField(
                                    controller: chatProvider.messageController,
                                    minLines: 1,
                                    maxLines: 5,
                                    onChanged: (value) {
                                      chatProvider.notifyListeners();
                                    },
                                    decoration: const InputDecoration(
                                      hintText: "Message...",
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),

                                /// SHOW SEND OR MIC+IMAGE
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),

                                  child: chatProvider.hasText

                                  /// SEND BUTTON
                                      ? SizedBox()

                                  /// MIC + IMAGE
                                      : Row(
                                    key: const ValueKey("actions"),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [

                                      /// MIC BUTTON
                                      IconButton(
                                        icon: Icon(Icons.mic, color: Colors.grey[800]),
                                        onPressed: () async {
                                          chatProvider.startRecording();
                                        },
                                      ),

                                      /// IMAGE BUTTON
                                      IconButton(
                                        icon: Icon(Icons.image, color: Colors.grey[800]),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            builder: (_) => CustomContainer(
                                              height: 200,
                                              backgroundColor: AppColor.containerColor,
                                              borderRadius: BorderRadius.circular(20),
                                              widget: Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                                children: [

                                                  /// Camera
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      chatProvider.pickFromCamera(
                                                          context, widget.otherUserId);
                                                    },
                                                    child: CustomContainer(
                                                      height: 150,
                                                      backgroundColor: Colors.grey[200],
                                                      borderRadius:
                                                      BorderRadius.circular(15),
                                                      padding: const EdgeInsets.all(10),
                                                      widget: Column(
                                                        children: [
                                                          CustomContainer(
                                                            height: 110,
                                                            width: 120,
                                                            widget: const Image(
                                                              image: AssetImage(
                                                                  "assets/images/camera_picker.png"),
                                                              fit: BoxFit.contain,
                                                            ),
                                                          ),
                                                          const MyText(
                                                            title: "Camera",
                                                            fontWeight: FontWeight.bold,
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),

                                                  /// Gallery
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      chatProvider.pickFromGallery(
                                                          context, widget.otherUserId);
                                                    },
                                                    child: CustomContainer(
                                                      height: 150,
                                                      backgroundColor: Colors.grey[200],
                                                      borderRadius:
                                                      BorderRadius.circular(15),
                                                      padding: const EdgeInsets.all(10),
                                                      widget: Column(
                                                        children: [
                                                          CustomContainer(
                                                            height: 110,
                                                            width: 120,
                                                            widget: const Image(
                                                              image: AssetImage(
                                                                  "assets/images/image_picker.png"),
                                                              fit: BoxFit.contain,
                                                            ),
                                                          ),
                                                          const MyText(
                                                            title: "Gallery",
                                                            fontWeight: FontWeight.bold,
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        10.width,
                        /// Send button
                        IconButton(
                          onPressed: (){
                            chatProvider.isRecording
                                 ?  chatProvider.stopRecording(
                                widget.otherUserId, context)
                                :
                            chatProvider.sendMessage(
                                context: context,
                                senderId: localData.currentUserID,
                                otherUser: widget.otherUserId,
                                audioPath: '',
                                type: 'text',
                                imagePath: ""
                            );
                          },
                          icon: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColor.primaryColor,
                              child: Icon(Icons.send,color: AppColor.iconColor,)),
                          // child: MyText(title:"Send",textColor: AppColor.primaryColor,fontWeight: FontWeight.w600,),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


