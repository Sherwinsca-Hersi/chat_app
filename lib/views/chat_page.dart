import 'dart:io';
import 'package:chat_app/res/colors.dart';
import 'package:chat_app/res/widget/chat_shimmer.dart';
import 'package:chat_app/utils/screenUtils.dart';
import 'package:chat_app/utils/sizedBox.dart';
import 'package:chat_app/view_model/chat_provider.dart';
import 'package:chat_app/views/user_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/local_data.dart';
import '../res/components/customText.dart';
import '../res/components/custom_container.dart';
import '../res/widget/video_screen.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      chatProvider = Provider.of<ChatProvider>(context, listen: false);

      chatProvider.resetChat();

      /// 🔥 First API call
      await chatProvider.MessageData(
        context: context,
        otherUser: widget.otherUserId,
      );

      /// 🔥 Start polling AFTER first load
      chatProvider.startPolling(
        widget.otherUserId.toString(),
        context,
        widget.otherUserId,
      );

      chatProvider.initPlayerListeners();
    });
  }

  @override
  void dispose() {
    chatProvider.stopPolling();
    super.dispose();
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
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(builder: (context) => UserScreen()),
            // );
            // Navigator.pop(context);
            return false;
          },
          child: SafeArea(
            child: Scaffold(
              resizeToAvoidBottomInset: true,
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
              ),
              body: CustomContainer(
                child: Column(
                  children: [
                    /// Messages
                    Expanded(
                      child: chatProvider.isLoading ?
                      ChatMessageShimmer()
                          : SafeArea(
                        child: CustomContainer(
                          padding: const EdgeInsets.all(10),
                          /// ⭐ FILTERED LIST (Delete for me removed)
                          child: (() {
                            final visibleMessages = chatProvider.messages
                                .where((m) => m.active != 2)
                                .toList();
            
                            /// ⭐ BLOCK UI until correct data loads
                            if (!chatProvider.hasLoadedOnce) {
                              return ChatMessageShimmer(); // or empty container
                            }
            
                            /// EMPTY
                            if (visibleMessages.isEmpty) {
                              return Center(
                                child: Image.asset("assets/images/splash_vector.png"),
                              );
                            }
                            return Align(
                              alignment: Alignment.topCenter,
                              child: ListView.builder(
                                controller: chatProvider.chatScrollController,
                                itemCount: visibleMessages.length,
                                reverse: true,
                                shrinkWrap: true,
                                /// shrinkWrap: true, This is very important for showing message
                                ///at top if only small or single message present
                                itemBuilder: (context, index) {
                                  final msg = visibleMessages[visibleMessages.length - 1 - index];
                                  final String loggedInUserId =
                                  localData.currentUserID.toString();
            
                                  bool isMe =
                                      msg.senderId.toString().trim() ==
                                          loggedInUserId.trim();
            
                                  print("MSG: ${msg.message} | sender: ${msg.senderId} | me: ${localData.currentUserID} | isMe: $isMe");
            
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
                                              child: MyText(
                                                title:
                                                formatDateHeader(msg.createdAt),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
            
                                      /// MESSAGE ROW
                                      // Row(
                                      //   mainAxisAlignment:
                                      //   isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                      //   crossAxisAlignment: CrossAxisAlignment.center,
                                      //   children: [
                                      //     /// ================= RECEIVED (LEFT) =================
                                      //     if (!isMe) ...[
                                      //       /// RECEIVER PROFILE
                                      //       CircleAvatar(
                                      //         radius: 14,
                                      //         backgroundColor: AppColor.primaryColor,
                                      //         child: MyText(
                                      //           title: chatProvider.getInitials(msg.senderName),
                                      //           color: AppColor.whiteTextColor,
                                      //           fontSize: 12,
                                      //           fontWeight: FontWeight.bold,
                                      //         ),
                                      //       ),
                                      //       const SizedBox(width: 6),
                                      //       /// MESSAGE BUBBLE
                                      //       GestureDetector(
                                      //         onLongPress: () {
                                      //           void _showDeleteOptions(BuildContext context, msg) {
                                      //             showModalBottomSheet(
                                      //               context: context,
                                      //               builder: (_) => Wrap(
                                      //                 children: [
                                      //                   ListTile(
                                      //                     leading: const Icon(Icons.delete),
                                      //                     title: const Text('Delete for me'),
                                      //                     onTap: () async {
                                      //                       Navigator.pop(context);
                                      //                       await chatProvider.DeleteMessage(
                                      //                         messageId: msg.id,
                                      //                         active: '2',
                                      //                         context: context,
                                      //                       );
                                      //                     },
                                      //                   ),
                                      //                   if (msg.senderId == localData.currentUserID)
                                      //                     ListTile(
                                      //                       leading: const Icon(Icons.delete_forever),
                                      //                       title: const Text('Delete for everyone'),
                                      //                       onTap: () async {
                                      //                         Navigator.pop(context);
                                      //                         await chatProvider.DeleteMessage(
                                      //                           messageId: msg.id,
                                      //                           active: '3',
                                      //                           context: context,
                                      //                         );
                                      //                       },
                                      //                     ),
                                      //                   ListTile(
                                      //                     leading: const Icon(Icons.close),
                                      //                     title: const Text('Cancel'),
                                      //                     onTap: () => Navigator.pop(context),
                                      //                   ),
                                      //                 ],
                                      //               ),
                                      //             );
                                      //           }
                                      //
                                      //           _showDeleteOptions(context, msg);
                                      //         },
                                      //
                                      //         child: CustomContainer(
                                      //           margin: const EdgeInsets.symmetric(vertical: 5),
                                      //           padding: const EdgeInsets.all(6),
                                      //           backgroundColor: AppColor.receivedMsgColor,
                                      //           borderRadius: BorderRadius.circular(10),
                                      //
                                      //           child: ConstrainedBox(
                                      //             constraints: BoxConstraints(
                                      //               maxWidth:
                                      //               MediaQuery.of(context).size.width * 0.60,
                                      //             ),
                                      //
                                      //             child: Row(
                                      //               mainAxisSize: MainAxisSize.min,
                                      //               crossAxisAlignment:
                                      //               CrossAxisAlignment.end,
                                      //               children: [
                                      //                 /// ⭐ ACTIVE MESSAGE
                                      //                 if (msg.active == 1 ||
                                      //                     msg.active == null ||
                                      //                     msg.active == 0) ...[
                                      //
                                      //                   /// IMAGE
                                      //                   if (msg.type == "image" && (msg.imagePath).isNotEmpty)
                                      //                     Flexible(
                                      //                       child: ConstrainedBox(
                                      //                         constraints: BoxConstraints(
                                      //                           maxWidth: MediaQuery.of(context).size.width * 0.5,
                                      //                           minWidth: 150,
                                      //                           minHeight: 200,
                                      //                         ),
                                      //                         child: GestureDetector(
                                      //                           behavior: HitTestBehavior.opaque, // 🔥 important fix
                                      //                           onTap: () {
                                      //                             final imageUrl = msg.imagePath.startsWith("/data/")
                                      //                                 ? msg.imagePath
                                      //                                 : chatProvider.getImageUrl(msg.imagePath);
                                      //
                                      //                             print("IMAGE CLICKED: $imageUrl"); // 🔥 debug
                                      //
                                      //                             Navigator.push(
                                      //                               context,
                                      //                               MaterialPageRoute(
                                      //                                 builder: (_) => ImageViewer(imageUrl: imageUrl),
                                      //                               ),
                                      //                             );
                                      //                           },
                                      //                           child: msg.imagePath.startsWith("/data/")
                                      //                               ? Image.file(
                                      //                             File(msg.imagePath),
                                      //                             width: 180,
                                      //                             height: 200,
                                      //                             fit: BoxFit.cover,
                                      //                           )
                                      //                               : Image.network(
                                      //                             chatProvider.getImageUrl(msg.imagePath),
                                      //                             fit: BoxFit.cover,
                                      //                           ),
                                      //                         ),
                                      //                       ),
                                      //                     ),
                                      //
                                      //                   if (msg.type == "video" && msg.videoPath.isNotEmpty)
                                      //                     Flexible(
                                      //                       child: ConstrainedBox(
                                      //                         constraints: BoxConstraints(
                                      //                           maxWidth: MediaQuery.of(context).size.width * 0.5,
                                      //                           minHeight: 200,
                                      //                         ),
                                      //                         child: GestureDetector(
                                      //                           onTap: () {
                                      //                             Navigator.push(
                                      //                               context,
                                      //                               MaterialPageRoute(
                                      //                                 builder: (_) => VideoPlayerScreen(
                                      //                                   videoUrl: msg.videoPath.startsWith("/data/")
                                      //                                       ? msg.videoPath
                                      //                                       : chatProvider.getVideoUrl(msg.videoPath),
                                      //                                 ),
                                      //                               ),
                                      //                             );
                                      //                           },
                                      //                           child: Stack(
                                      //                             alignment: Alignment.center,
                                      //                             children: [
                                      //                               // Thumbnail or placeholder
                                      //                               Container(
                                      //                                 width: 180,
                                      //                                 height: 200,
                                      //                                 color: Colors.black,
                                      //                                 child: const Center(
                                      //                                   child: Icon(Icons.video_library, color: Colors.white, size: 40),
                                      //                                 ),
                                      //                               ),
                                      //
                                      //                               // Play icon
                                      //                               const Icon(
                                      //                                 Icons.play_circle_fill,
                                      //                                 color: Colors.white,
                                      //                                 size: 50,
                                      //                               ),
                                      //                             ],
                                      //                           ),
                                      //                         ),
                                      //                       ),
                                      //                     ),
                                      //
                                      //                   /// VOICE
                                      //                   if (msg.type == "voice")
                                      //                     Flexible(
                                      //                       child: VoiceMessageBubble(
                                      //                         audioPath: msg.audioPath,
                                      //                       ),
                                      //                     ),
                                      //
                                      //                   /// TEXT
                                      //                   if (msg.type == "text")
                                      //                     Flexible(
                                      //                       child: MyText(
                                      //                         title: msg.message,
                                      //                         color:
                                      //                         AppColor.whiteTextColor,
                                      //                         softWrap: true,
                                      //                         maxLines: null,
                                      //                       ),
                                      //                     ),
                                      //
                                      //                   /// 📎 FILE (RECEIVED)
                                      //                   if (msg.type == "file" && msg.filePath.isNotEmpty)
                                      //                     Flexible(
                                      //                       child: GestureDetector(
                                      //                         onTap: () {
                                      //                           final fileUrl = msg.filePath.startsWith("/data/")
                                      //                               ? msg.filePath
                                      //                               : chatProvider.getFileUrl(msg.filePath);
                                      //
                                      //                           chatProvider.openFile(fileUrl);
                                      //                         },
                                      //                         child: Container(
                                      //                           padding: const EdgeInsets.all(10),
                                      //                           decoration: BoxDecoration(
                                      //                             color: Colors.blueGrey,
                                      //                             borderRadius: BorderRadius.circular(8),
                                      //                           ),
                                      //                           child: Row(
                                      //                             mainAxisSize: MainAxisSize.min,
                                      //                             children: [
                                      //
                                      //                               /// ICON
                                      //                               chatProvider.getFileIcon(msg.fileName),
                                      //
                                      //                               const SizedBox(width: 8),
                                      //
                                      //                               /// FILE NAME
                                      //                               Flexible(
                                      //                                 child: Text(
                                      //                                   msg.fileName,
                                      //                                   style: const TextStyle(color: Colors.white),
                                      //                                   overflow: TextOverflow.ellipsis,
                                      //                                 ),
                                      //                               ),
                                      //                             ],
                                      //                           ),
                                      //                         ),
                                      //                       ),
                                      //                     ),
                                      //                 ]
                                      //
                                      //                 /// ⭐ DELETE FOR EVERYONE
                                      //                 else if (msg.active == 3) ...[
                                      //                   Flexible(
                                      //                     child: MyText(
                                      //                       title:
                                      //                       "This message was deleted",
                                      //                       color: Colors.grey.shade300,
                                      //                     ),
                                      //                   ),
                                      //                 ],
                                      //
                                      //                 /// ERROR ICON
                                      //                 if (msg.isFailed) ...[
                                      //                   const SizedBox(width: 6),
                                      //                   GestureDetector(
                                      //                     onTap: () {
                                      //                       chatProvider
                                      //                           .resendMessage(msg);
                                      //                     },
                                      //                     child: const Icon(
                                      //                       Icons.error,
                                      //                       color: Colors.red,
                                      //                       size: 16,
                                      //                     ),
                                      //                   )
                                      //                 ],
                                      //               ],
                                      //             ),
                                      //           ),
                                      //         ),
                                      //       ),
                                      //       const SizedBox(width: 5),
                                      //       /// TIME (AFTER BUBBLE)
                                      //       MyText(
                                      //         title: formatMessageTime(msg.createdAt),
                                      //         color: AppColor.receivedMsgColor,
                                      //         fontSize: 10,
                                      //       ),
                                      //     ],
                                      //
                                      //     /// ================= SENT (RIGHT) =================
                                      //     if (isMe) ...[
                                      //
                                      //       /// TIME FIRST
                                      //       MyText(
                                      //         title: formatMessageTime(msg.createdAt),
                                      //         color: AppColor.receivedMsgColor,
                                      //         fontSize: 10,
                                      //       ),
                                      //       3.width,
                                      //       if (isMe)
                                      //         Icon(
                                      //           Icons.done_all,
                                      //           size: 16,
                                      //           color: msg.isRead == 1 ? Colors.blue : Colors.grey,
                                      //         ),
                                      //
                                      //       const SizedBox(width: 5),
                                      //
                                      //       /// MESSAGE BUBBLE
                                      //       GestureDetector(
                                      //         onLongPress: () {
                                      //           void _showDeleteOptions(BuildContext context, msg) {
                                      //             showModalBottomSheet(
                                      //               context: context,
                                      //               builder: (_) => Wrap(
                                      //                 children: [
                                      //                   ListTile(
                                      //                     leading: const Icon(Icons.delete),
                                      //                     title: const Text('Delete for me'),
                                      //                     onTap: () async {
                                      //                       Navigator.pop(context);
                                      //                       await chatProvider.DeleteMessage(
                                      //                         messageId: msg.id,
                                      //                         active: '2',
                                      //                         context: context,
                                      //                       );
                                      //                     },
                                      //                   ),
                                      //                   if (msg.senderId == localData.currentUserID)
                                      //                     ListTile(
                                      //                       leading: const Icon(Icons.delete_forever),
                                      //                       title: const Text('Delete for everyone'),
                                      //                       onTap: () async {
                                      //                         Navigator.pop(context);
                                      //                         await chatProvider.DeleteMessage(
                                      //                           messageId: msg.id,
                                      //                           active: '3',
                                      //                           context: context,
                                      //                         );
                                      //                       },
                                      //                     ),
                                      //                   ListTile(
                                      //                     leading: const Icon(Icons.close),
                                      //                     title: const Text('Cancel'),
                                      //                     onTap: () => Navigator.pop(context),
                                      //                   ),
                                      //                 ],
                                      //               ),
                                      //             );
                                      //           }
                                      //
                                      //           _showDeleteOptions(context, msg);
                                      //         },
                                      //
                                      //         child: CustomContainer(
                                      //           margin: const EdgeInsets.symmetric(vertical: 5),
                                      //           padding: const EdgeInsets.all(6),
                                      //           backgroundColor: AppColor.sendedMsgColor,
                                      //           borderRadius: BorderRadius.circular(10),
                                      //
                                      //           child: ConstrainedBox(
                                      //             constraints: BoxConstraints(
                                      //               maxWidth:
                                      //               MediaQuery.of(context).size.width * 0.60,
                                      //             ),
                                      //
                                      //             child: Row(
                                      //               mainAxisSize: MainAxisSize.min,
                                      //               crossAxisAlignment:
                                      //               CrossAxisAlignment.end,
                                      //               children: [
                                      //
                                      //                 /// ⭐ ACTIVE MESSAGE
                                      //                 if (msg.active == 1 ||
                                      //                     msg.active == null ||
                                      //                     msg.active == 0) ...[
                                      //
                                      //                   if (msg.type == "image" && (msg.imagePath).isNotEmpty)
                                      //                     Flexible(
                                      //                       child: ConstrainedBox(
                                      //                         constraints: BoxConstraints(
                                      //                           maxWidth: MediaQuery.of(context).size.width * 0.5,
                                      //                           minWidth: 150,
                                      //                           minHeight: 200,
                                      //                         ),
                                      //                         child: GestureDetector(
                                      //                           behavior: HitTestBehavior.opaque,
                                      //                           onTap: () {
                                      //                             final imageUrl = msg.imagePath.startsWith("/data/")
                                      //                                 ? msg.imagePath
                                      //                                 : chatProvider.getImageUrl(msg.imagePath);
                                      //
                                      //                             print("IMAGE CLICKED: $imageUrl");
                                      //
                                      //                             Navigator.push(
                                      //                               context,
                                      //                               MaterialPageRoute(
                                      //                                 builder: (_) => ImageViewer(imageUrl: imageUrl),
                                      //                               ),
                                      //                             );
                                      //                           },
                                      //                           child: msg.imagePath.startsWith("/data/")
                                      //                               ? Image.file(
                                      //                             File(msg.imagePath),
                                      //                             width: 180,
                                      //                             height: 200,
                                      //                             fit: BoxFit.cover,
                                      //                           )
                                      //                               : Image.network(
                                      //                             chatProvider.getImageUrl(msg.imagePath),
                                      //                             fit: BoxFit.cover,
                                      //                           ),
                                      //                         ),
                                      //                       ),
                                      //                     ),
                                      //
                                      //                   if (msg.type == "video" && msg.videoPath.isNotEmpty)
                                      //                     Flexible(
                                      //                       child: ConstrainedBox(
                                      //                         constraints: BoxConstraints(
                                      //                           maxWidth: MediaQuery.of(context).size.width * 0.5,
                                      //                           minHeight: 200,
                                      //                         ),
                                      //                         child: GestureDetector(
                                      //                           onTap: () {
                                      //                             Navigator.push(
                                      //                               context,
                                      //                               MaterialPageRoute(
                                      //                                 builder: (_) => VideoPlayerScreen(
                                      //                                   videoUrl: msg.videoPath.startsWith("/data/")
                                      //                                       ? msg.videoPath
                                      //                                       : chatProvider.getVideoUrl(msg.videoPath),
                                      //                                 ),
                                      //                               ),
                                      //                             );
                                      //                           },
                                      //                           child: Stack(
                                      //                             alignment: Alignment.center,
                                      //                             children: [
                                      //                               // Thumbnail or placeholder
                                      //                               Container(
                                      //                                 width: 180,
                                      //                                 height: 200,
                                      //                                 color: Colors.black,
                                      //                                 child: const Center(
                                      //                                   child: Icon(Icons.video_library, color: Colors.white, size: 40),
                                      //                                 ),
                                      //                               ),
                                      //
                                      //                               // Play icon
                                      //                               const Icon(
                                      //                                 Icons.play_circle_fill,
                                      //                                 color: Colors.white,
                                      //                                 size: 50,
                                      //                               ),
                                      //                             ],
                                      //                           ),
                                      //                         ),
                                      //                       ),
                                      //                     ),
                                      //
                                      //                   if (msg.type == "voice")
                                      //                     Flexible(
                                      //                       child: VoiceMessageBubble(
                                      //                         audioPath: msg.audioPath,
                                      //                       ),
                                      //                     ),
                                      //
                                      //                   if (msg.type == "text")
                                      //                     Flexible(
                                      //                       child: MyText(
                                      //                         title: msg.message,
                                      //                         color:
                                      //                         AppColor.whiteTextColor,
                                      //                         softWrap: true,
                                      //                         maxLines: null,
                                      //                       ),
                                      //                     ),
                                      //
                                      //                   /// 📎 FILE
                                      //                   if (msg.type == "file" && msg.filePath.isNotEmpty)
                                      //                     Flexible(
                                      //                       child: GestureDetector(
                                      //                         onTap: () {
                                      //                           final fileUrl = msg.filePath.startsWith("/data/")
                                      //                               ? msg.filePath
                                      //                               : chatProvider.getFileUrl(msg.filePath);
                                      //
                                      //                           chatProvider.openFile(fileUrl);
                                      //                         },
                                      //                         child: Container(
                                      //                           padding: const EdgeInsets.all(10),
                                      //                           decoration: BoxDecoration(
                                      //                             color: Colors.blueGrey,
                                      //                             borderRadius: BorderRadius.circular(8),
                                      //                           ),
                                      //                           child: Row(
                                      //                             mainAxisSize: MainAxisSize.min,
                                      //                             children: [
                                      //
                                      //                               /// ICON
                                      //                               chatProvider.getFileIcon(msg.fileName),
                                      //
                                      //                               const SizedBox(width: 8),
                                      //
                                      //                               /// FILE NAME
                                      //                               Flexible(
                                      //                                 child: Text(
                                      //                                   msg.fileName,
                                      //                                   style: const TextStyle(color: Colors.white),
                                      //                                   overflow: TextOverflow.ellipsis,
                                      //                                 ),
                                      //                               ),
                                      //                             ],
                                      //                           ),
                                      //                         ),
                                      //                       ),
                                      //                     ),
                                      //                 ]
                                      //
                                      //                 else if (msg.active == 3) ...[
                                      //                   Flexible(
                                      //                     child: MyText(
                                      //                       title:
                                      //                       "This message was deleted",
                                      //                       color: Colors.grey.shade300,
                                      //                     ),
                                      //                   ),
                                      //                 ],
                                      //
                                      //                 if (msg.isFailed) ...[
                                      //                   const SizedBox(width: 6),
                                      //                   GestureDetector(
                                      //                     onTap: () {
                                      //                       chatProvider
                                      //                           .resendMessage(msg);
                                      //                     },
                                      //                     child: const Icon(
                                      //                       Icons.error,
                                      //                       color: Colors.red,
                                      //                       size: 16,
                                      //                     ),
                                      //                   )
                                      //                 ],
                                      //               ],
                                      //             ),
                                      //           ),
                                      //         ),
                                      //       ),
                                      //     ],
                                      //   ],
                                      // ),
            
                                      Row(
                                        mainAxisAlignment:
                                        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
            
                                          /// LEFT SIDE (RECEIVED)
                                          if (!isMe) ...[
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
                                          ],
            
                                          /// TIME (LEFT SIDE BEFORE BUBBLE)
                                          if (isMe) ...[
                                            MyText(
                                              title: formatMessageTime(msg.createdAt),
                                              color: AppColor.receivedMsgColor,
                                              fontSize: 10,
                                            ),
                                            const SizedBox(width: 3),
                                            Icon(
                                              Icons.done_all,
                                              size: 16,
                                              color: msg.isRead == 1 ? Colors.blue : Colors.grey,
                                            ),
                                            const SizedBox(width: 5),
                                          ],
            
                                          /// 🔥 COMMON BUBBLE
                                          buildMessageBubble(context, msg, isMe,chatProvider),
            
                                          /// TIME (RIGHT SIDE AFTER BUBBLE)
                                          if (!isMe) ...[
                                            const SizedBox(width: 5),
                                            MyText(
                                              title: formatMessageTime(msg.createdAt),
                                              color: AppColor.receivedMsgColor,
                                              fontSize: 10,
                                            ),
                                          ],
                                        ],
                                      ),
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
                      child: Row(
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
            
                                  /// SHOW SEND OR MIC+IMAGE+Document
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
                                                child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                children: [
                                                  ///  CAMERA (now shows Image + Video)
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      showModalBottomSheet(
                                                        context: context,
                                                        builder: (_) => CustomContainer(
                                                          width: ScreenUtils.screenWidth,
                                                          height: 150,
                                                          backgroundColor: AppColor.containerColor,
                                                          borderRadius: BorderRadius.only(
                                                            topLeft: Radius.circular(20),
                                                            topRight: Radius.circular(20),
                                                          ),
                                                          child: Padding(
                                                            padding: const EdgeInsets.all(20.0),
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              // mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                InkWell(
                                                                    onTap: () {
                                                                      Navigator.pop(context);
                                                                      chatProvider.pickFromCamera(context, widget.otherUserId);
                                                                    },
                                                                  child: Column(
                                                                    children: [
                                                                      Icon(Icons.photo_camera, size: 80,),
                                                                      MyText(title: "Take Photo", fontSize: 12,fontWeight: FontWeight.bold,)
                                                                    ],
                                                                  ),
                                                                ),
                                                                InkWell(
                                                                    onTap: () {
                                                                      Navigator.pop(context);
                                                                      chatProvider.pickVideoFromCamera(
                                                                          context, widget.otherUserId);
                                                                    },
                                                                  child: Column(
                                                                    children: [
                                                                      Icon(Icons.videocam, size: 80,),
                                                                      MyText(title: "Record Video", fontSize: 12,fontWeight: FontWeight.bold,)
                                                                    ],
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
            
                                                    child: CustomContainer(
                                                      height: 150,
                                                      backgroundColor: Colors.grey[200],
                                                      borderRadius: BorderRadius.circular(15),
                                                      padding: const EdgeInsets.all(10),
                                                      child: Column(
                                                        children: [
                                                          CustomContainer(
                                                            height: 110,
                                                            width: 120,
                                                            child: const Image(
                                                              image: AssetImage("assets/images/camera_picker.png"),
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
                                                  ///  GALLERY (now shows Image + Video)
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      showModalBottomSheet(
                                                        context: context,
                                                        builder: (_) => CustomContainer(
                                                          width: ScreenUtils.screenWidth,
                                                          height: 150,
                                                          backgroundColor: AppColor.containerColor,
                                                          borderRadius: BorderRadius.only(
                                                            topLeft: Radius.circular(20),
                                                            topRight: Radius.circular(20),
                                                          ),
                                                          child: Padding(
                                                            padding: const EdgeInsets.all(20.0),
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              // mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                InkWell(
                                                                  onTap: () {
                                                                    Navigator.pop(context);
                                                                    chatProvider.pickFromGallery(context, widget.otherUserId);
                                                                  },
                                                                  child: Column(
                                                                    children: [
                                                                      Icon(Icons.photo_library, size: 80,),
                                                                      MyText(title: "Pick Images", fontSize: 12,fontWeight: FontWeight.bold,)
                                                                    ],
                                                                  ),
                                                                ),
                                                                InkWell(
                                                                  onTap: () {
                                                                    Navigator.pop(context);
                                                                    chatProvider.pickVideoFromGallery(
                                                                        context, widget.otherUserId);
                                                                  },
                                                                  child: Column(
                                                                    children: [
                                                                      Icon(Icons.video_library, size: 80,),
                                                                      MyText(title: "Pick Video", fontSize: 12,fontWeight: FontWeight.bold,)
                                                                    ],
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: CustomContainer(
                                                      height: 150,
                                                      backgroundColor: Colors.grey[200],
                                                      borderRadius: BorderRadius.circular(15),
                                                      padding: const EdgeInsets.all(10),
                                                      child: Column(
                                                        children: [
                                                          CustomContainer(
                                                            height: 110,
                                                            width: 120,
                                                            child: const Image(
                                                              image: AssetImage("assets/images/image_picker.png"),
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
                                        IconButton(
                                          icon: Icon(Icons.attach_file, color: Colors.grey[800]),
                                          onPressed: () {
                                            chatProvider.pickDocument(
                                                context, widget.otherUserId);
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
                                  imagePath: "",
                                  filePath: '',
                                  fileName: ''
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
          ),
        );
      },
    );
  }

  Widget buildMessageContent(BuildContext context, msg, chatProvider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [

        /// ACTIVE MESSAGE
        if (msg.active == 1 || msg.active == null || msg.active == 0) ...[

          /// IMAGE
          if (msg.type == "image" && (msg.imagePath).isNotEmpty)
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.5,
                  minWidth: 150,
                  minHeight: 200,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final imageUrl = msg.imagePath.startsWith("/data/")
                        ? msg.imagePath
                        : chatProvider.getImageUrl(msg.imagePath);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImageViewer(imageUrl: imageUrl),
                      ),
                    );
                  },
                  child: msg.imagePath.startsWith("/data/")
                      ? Image.file(
                    File(msg.imagePath),
                    width: 180,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                      : Image.network(
                    chatProvider.getImageUrl(msg.imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          /// VIDEO
          if (msg.type == "video" && msg.videoPath.isNotEmpty)
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.5,
                  minHeight: 200,
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerScreen(
                          videoUrl: msg.videoPath.startsWith("/data/")
                              ? msg.videoPath
                              : chatProvider.getVideoUrl(msg.videoPath),
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 180,
                        height: 200,
                        color: Colors.black,
                        child: const Center(
                          child: Icon(Icons.video_library, color: Colors.white, size: 40),
                        ),
                      ),
                      const Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
                    ],
                  ),
                ),
              ),
            ),

          /// VOICE
          if (msg.type == "voice")
            Flexible(child: VoiceMessageBubble(audioPath: msg.audioPath)),

          /// TEXT
          if (msg.type == "text")
            Flexible(
              child: MyText(
                title: msg.message,
                color: AppColor.whiteTextColor,
                softWrap: true,
                maxLines: null,
              ),
            ),

          /// FILE
          if (msg.type == "file" && msg.filePath.isNotEmpty)
            Flexible(
              child: GestureDetector(
                onTap: () {
                  final fileUrl = msg.filePath.startsWith("/data/")
                      ? msg.filePath
                      : chatProvider.getFileUrl(msg.filePath);

                  chatProvider.openFile(fileUrl);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      chatProvider.getFileIcon(msg.fileName),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          msg.fileName,
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ]

        /// DELETE FOR EVERYONE
        else if (msg.active == 3) ...[
          Flexible(
            child: MyText(
              title: "This message was deleted",
              color: Colors.grey.shade300,
            ),
          ),
        ],

        /// ERROR
        if (msg.isFailed) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              chatProvider.resendMessage(msg);
            },
            child: const Icon(Icons.error, color: Colors.red, size: 16),
          )
        ],
      ],
    );
  }

  Widget buildMessageBubble(BuildContext context, msg, bool isMe,chatProvider) {
    return GestureDetector(
      onLongPress: () {
        final parentContext = context;

        showDialog(
          context: parentContext,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: AppColor.containerColor,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, // Title left
                children: [

                  /// ✅ TITLE (LEFT)
                  MyText(
                    title: isMe
                        ? "Delete Message ?"
                        : "Delete Message from ${widget.otherUserName} ?"
                  ),

                  const SizedBox(height: 15),

                  /// ✅ BUTTONS (RIGHT)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isMe)
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext);

                              await chatProvider.DeleteMessage(
                                messageId: msg.id,
                                active: '3',
                                context: parentContext,
                              );
                            },
                            child: MyText(title: "Delete for everyone",fontWeight: FontWeight.w500,),
                          ),

                        TextButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);

                            await chatProvider.DeleteMessage(
                              messageId: msg.id,
                              active: '2',
                              context: parentContext,
                            );
                          },
                          child: MyText(title: "Delete for me",fontWeight: FontWeight.w500,),
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          child: MyText(title: "Cancel",fontWeight: FontWeight.w500,),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: CustomContainer(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(6),
        backgroundColor:
        isMe ? AppColor.sendedMsgColor : AppColor.receivedMsgColor,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.60,
          ),
          child: buildMessageContent(context, msg, chatProvider),
        ),
      ),
    );
  }
}
class ImageViewer extends StatelessWidget {
  final String imageUrl;

  const ImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final isLocal = imageUrl.startsWith("/data/");

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: isLocal
              ? Image.file(File(imageUrl))
              : Image.network(imageUrl),
        ),
      ),
    );
  }
}




