import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:chat_app/api/api.dart';
import 'package:chat_app/data/local_data.dart';
import 'package:chat_app/res/colors.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/message_response.dart';
import '../model/user_response.dart';
import '../repo/message_repo.dart';
import '../res/components/customText.dart';



class ChatProvider with ChangeNotifier{

  final MessageRepository _messageRepository= MessageRepository();


  bool _isLoading = false;
  bool get isLoading => _isLoading;


  List<Message> _messages = [];
  List<Message> get messages => _messages;

  List<Users> _users = [];
  List<Users> get users => _users;


  List<Users>? filteredUsers = [];


  void initializeUsers(){
    filteredUsers = List.from(_users);
    log("Filtered Users: $filteredUsers");
    notifyListeners();
  }

  ///User Search Controller
  final TextEditingController userSearchController = TextEditingController();


  void searchUsers(String query) {

    final q = query.toLowerCase().trim();

    log("Filter query:$q");

    if (q.isEmpty) {
      filteredUsers = _users;
      log("Filtered User in empty:${jsonEncode(filteredUsers?.map((e)=>e.toJson()).toList())}");
      log("Users in empty: ${jsonEncode(_users.map((e)=>e.toJson()).toList())}");
    } else {
      final queryPhone = q.replaceAll(RegExp(r'\D'), '');

      filteredUsers = _users.where((user) {

        final name = user.name.toLowerCase();
        final email = user.email.toLowerCase();
        final phone = user.mobile.replaceAll(RegExp(r'\D'), '');

        log("name:$name");

        log("Filtered User:${jsonEncode(filteredUsers?.map((e)=>e.toJson()).toList())}");
        log("Users: ${jsonEncode(_users.map((e)=>e.toJson()).toList())}");

        final matchesName = name.contains(q);
        final matchesEmail = email.contains(q);

        // Phone search only if query has digits
        final matchesPhone =
            queryPhone.isNotEmpty && phone.contains(queryPhone);

        return matchesName || matchesEmail || matchesPhone;


      }).toList();
    }

    notifyListeners();
  }
  ScrollController chatScrollController = ScrollController();

  // To Hide and show icons in TextField
  bool get hasText => messageController.text.trim().isNotEmpty;

  ///Scroll To Bottom
  // void scrollToBottom() {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //
  //     if (chatScrollController.hasClients) {
  //
  //       chatScrollController.animateTo(
  //         chatScrollController.position.maxScrollExtent + 80,
  //         duration: const Duration(milliseconds: 300),
  //         curve: Curves.easeOut,
  //       );
  //
  //     }
  //
  //   });
  // }

  bool isNearBottom() {

    if (!chatScrollController.hasClients) return false;

    final maxScroll = chatScrollController.position.maxScrollExtent;
    final currentScroll = chatScrollController.position.pixels;

    return (maxScroll - currentScroll) < 200;
  }

  // void scrollToBottom({bool force = false}) {
  //
  //   if (!chatScrollController.hasClients) return;
  //
  //   if (!force && !isNearBottom()) return;
  //
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //
  //     Future.delayed(const Duration(milliseconds: 50), () {
  //
  //       if (!chatScrollController.hasClients) return;
  //
  //       chatScrollController.animateTo(
  //         chatScrollController.position.maxScrollExtent,
  //         duration: const Duration(milliseconds: 300),
  //         curve: Curves.easeOut,
  //       );
  //
  //     });
  //
  //   });
  //
  // }

  void scrollToBottom({bool force = false}) {

    if (!chatScrollController.hasClients) return;

    if (!force && !isNearBottom()) return;

    Future.delayed(const Duration(milliseconds: 50), () {
      if (!chatScrollController.hasClients) return;

      chatScrollController.jumpTo(
        chatScrollController.position.maxScrollExtent,
      );
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!chatScrollController.hasClients) return;

      chatScrollController.jumpTo(
        chatScrollController.position.maxScrollExtent,
      );
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!chatScrollController.hasClients) return;

      chatScrollController.jumpTo(
        chatScrollController.position.maxScrollExtent,
      );
    });
  }

  ///Controllers
  final TextEditingController messageController = TextEditingController();

  String getInitials(String name) {
    List<String> parts = name.trim().split(" ");

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> UserData({
    required BuildContext context,
    bool isRefresh = true,
    required dynamic currentUser,
  }) async {

    try {

      if (isRefresh) {
        _isLoading = true;
        notifyListeners();
      }

      log("CurrentUser:$currentUser");

      final response = await _messageRepository.getUserData(currentUser: currentUser);

      if (response.status == true) {

        _users = response.data;

        filteredUsers = List.from(_users);

        log("Users Loaded: ${jsonEncode(_users.map((e)=>e.toJson()).toList())}");

      } else {
        log("Users Provider: Something went wrong");
      }

    } catch (e) {

      log("Users Provider Error: $e");

    } finally {

      _isLoading = false;
      notifyListeners();

    }

  }

  Future<void> MessageData({
    required BuildContext context,
    bool isRefresh = true,
    required dynamic otherUser,
  }) async {

    try {

      if (isRefresh) {
        _isLoading = true;
        notifyListeners();
      }

      final response = await _messageRepository.getMessages(otherUser: otherUser);



      if (response.status == true) {

        _messages = response.data;

        log("Messages Loaded: ${jsonEncode(_messages.map((e)=>e.toJson()).toList())}");

      } else {
        log("Message Provider: Something went wrong");
      }

    } catch (e) {

      log("Message Provider Error: $e");

    } finally {

      _isLoading = false;
      notifyListeners();

    }

  }


  String getChatId(int a, int b) {
    return a < b ? "${a}_$b" : "${b}_$a";
  }

  // Send Message

  Future<void> sendMessage({
    required BuildContext context,
    required int senderId,
    required int otherUser,
    required String type,
    required String audioPath, required String imagePath,
  }) async {

    log("I am in the sendMessage Type:$type");

    final text = messageController.text.trim();

    if (type == "text" && text.isEmpty) {
      return;
    }

    messageController.clear();

    // 1️⃣ First show message in UI
    final tempMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch,
      senderId: senderId,
      receiverId: otherUser,
      message: type == "voice" ? audioPath : text,
      createdAt: DateTime.now(),
      senderName: localData.currentUserName,
      type: type,
      audioPath: audioPath,
      imagePath : imagePath,
    );

    _messages.add(tempMessage);
    notifyListeners();

    log("TempMessage:${tempMessage}");

    scrollToBottom();

    try {

      final response = await _messageRepository.sendMessages(
          message: type == "voice" ?  audioPath : text,
          otherUser: otherUser,
          senderId: senderId,
          type: type,
          audioPath: audioPath,
          imagePath : imagePath
      );

      if (response.status == true) {

        log("Message saved in server");

      } else {

        tempMessage.isFailed = true;
        notifyListeners();

      }

    } catch (e) {

      // ❗ network error
      tempMessage.isFailed = true;
      notifyListeners();

      log("Message Provider Error: $e");

    }

  }

  Future<void> resendMessage(Message msg) async {

    try {

      final response = await _messageRepository.sendMessages(
        senderId: msg.senderId,
        otherUser: msg.receiverId,
        message: msg.type == "text" ? msg.message : "",
        type: msg.type,
        audioPath: msg.type == "voice" ? msg.message : null,
        imagePath: msg.type == "image" ? msg.message : null,
      );

      if (response.status == true) {

        msg.isFailed = false;
        notifyListeners();

      } else {

        msg.isFailed = true;
        notifyListeners();

      }

    } catch (e) {

      msg.isFailed = true;
      notifyListeners();

    }
  }


  /// Audio Recorder
  final AudioRecorder _recorder = AudioRecorder();
  bool isRecording = false;
  String? audioPath;

  Duration recordingDuration = Duration.zero;
  Timer? _recordTimer;

  /// Audio Player
  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;
  String? currentAudio;
  String? loadingAudio;

  Stream<Duration> get playerPositionStream => _player.onPositionChanged;

  ///Play Mic Click
  Future<void> playMicClick() async {
    log("Playing click sound");

    await _player.play(
      AssetSource('audio/voice_msg.mp3'),
      volume: 0.7,
    );
  }

  /// START RECORDING
  Future<void> startRecording() async {

    if (!await _recorder.hasPermission()) {
      debugPrint("Microphone permission denied");
      return;
    }

    await playMicClick(); // 🔊 play fully first

    await Future.delayed(
      const Duration(milliseconds: 120),
    ); // ⚡ allow sound to start

    final dir = await getApplicationDocumentsDirectory();

    audioPath =
    '${dir.path}/audio_message_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: audioPath!,
    );

    recordingDuration = Duration.zero;

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        recordingDuration += const Duration(seconds: 1);
        notifyListeners();
      },
    );

    isRecording = true;
    notifyListeners();
  }

  /// STOP RECORDING
  Future<void> stopRecording(int otherUserId, BuildContext context) async {
    final resultPath = await _recorder.stop();

    /// stop timer
    _recordTimer?.cancel();

    isRecording = false;

    if (resultPath != null) {
      audioPath = resultPath;
      log("Recorded file saved: $audioPath");
      await sendVoiceMessage(audioPath!, otherUserId, context);
    }

    recordingDuration = Duration.zero;

    notifyListeners();
  }

  ///Delete Recording
  Future<void> deleteRecording() async {
    try {
      await _recorder.stop();
    } catch (_) {}

    _recordTimer?.cancel();

    recordingDuration = Duration.zero;
    isRecording = false;
    audioPath = null;

    notifyListeners();
  }

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(d.inMinutes);
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  /// AUDIO PROGRESS
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  double get progress {
    if (duration.inMilliseconds == 0) return 0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  /// PLAYER LISTENERS
  void initPlayerListeners() {
    // total duration
    _player.onDurationChanged.listen((d) {
      duration = d;
      notifyListeners();
    });

    // current position
    _player.onPositionChanged.listen((p) {
      position = p;
      notifyListeners();
    });

    // player state (replaces onPlayerComplete)
    _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        isPlaying = false;
        currentAudio = null;
        position = Duration.zero;
        notifyListeners();
      } else if (state == PlayerState.playing) {
        isPlaying = true;
        notifyListeners();
      } else if (state == PlayerState.paused || state == PlayerState.stopped) {
        isPlaying = false;
        notifyListeners();
      }
    });
  }

  /// SEND VOICE MESSAGE
  Future<void> sendVoiceMessage(
      String path, int otherUserId, BuildContext context) async {
    await sendMessage(
      context: context,
      senderId: localData.currentUserID,
      otherUser: otherUserId,
      type: "voice",
      audioPath: path,
      imagePath: "",
    );
  }

  /// PLAY VOICE
  // Future<void> playVoice(String path) async {
  //   try {
  //     log("playVoice called for: $path");
  //
  //     // Stop previous audio if different
  //     if (currentAudio != null && currentAudio != path) {
  //       log("Stopping previous audio: $currentAudio");
  //       await _player.stop();
  //       isPlaying = false;
  //       currentAudio = null;
  //       notifyListeners();
  //     }
  //
  //     String fileToPlay = path;
  //
  //     // Handle remote audio
  //     if (path.startsWith("http")) {
  //       log("Downloading remote audio...");
  //       loadingAudio = path;
  //       notifyListeners();
  //
  //       final response = await http.get(Uri.parse(path));
  //       if (response.statusCode != 200) {
  //         loadingAudio = null;
  //         notifyListeners();
  //         debugPrint("Failed to download audio: ${response.statusCode}");
  //         return;
  //       }
  //
  //       final dir = await getTemporaryDirectory();
  //       final tempFile =
  //       File("${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a");
  //       await tempFile.writeAsBytes(response.bodyBytes);
  //       fileToPlay = tempFile.path;
  //
  //       loadingAudio = null;
  //       notifyListeners();
  //       log("Remote audio downloaded to: $fileToPlay");
  //     }
  //
  //     // Reset states
  //     currentAudio = path;
  //     isPlaying = true;
  //     position = Duration.zero;
  //     duration = Duration.zero;
  //     notifyListeners();
  //     log("Starting playback...");
  //
  //     // Setup listeners before playing
  //     _player.onDurationChanged.listen((d) {
  //       duration = d;
  //       log("Audio duration updated: $duration");
  //       notifyListeners();
  //     });
  //
  //     _player.onPositionChanged.listen((p) {
  //       position = p;
  //       log("Audio position: $position / $duration");
  //
  //       // Optional manual completion check if duration is known
  //       if (duration.inMilliseconds > 0 &&
  //           p.inMilliseconds >= duration.inMilliseconds - 50) {
  //         log("Manual completion triggered");
  //         isPlaying = false;
  //         currentAudio = null;
  //         position = Duration.zero;
  //         notifyListeners();
  //       }
  //     });
  //
  //     _player.onPlayerComplete.listen((event) {
  //       log("Audio completed");
  //       isPlaying = false;
  //       currentAudio = null;
  //       position = Duration.zero;
  //       notifyListeners();
  //     });
  //
  //     // Play audio
  //     await _player.play(DeviceFileSource(fileToPlay));
  //     log("Audio play command sent");
  //   } catch (e, st) {
  //     debugPrint("Audio Play Error: $e");
  //     log("Stacktrace: $st");
  //
  //     isPlaying = false;
  //     currentAudio = null;
  //     loadingAudio = null;
  //     position = Duration.zero;
  //     duration = Duration.zero;
  //     notifyListeners();
  //   }
  // }

  Future<String> downloadAudio(String url) async {
    final dir = await getApplicationDocumentsDirectory();

    final fileName = url.split('/').last;
    final filePath = "${dir.path}/$fileName";

    final file = File(filePath);

    /// Already downloaded → reuse
    if (await file.exists()) {
      return filePath;
    }

    /// Download
    await Dio().download(url, filePath);

    return filePath;
  }

  Future<void> playVoice(String path) async {
    try {
      log("playVoice called for: $path");

      // Stop previous audio if different
      if (currentAudio != null && currentAudio != path) {
        log("Stopping previous audio: $currentAudio");
        await _player.stop();
        isPlaying = false;
        currentAudio = null;
        notifyListeners();
      }

      // Reset states
      currentAudio = path;
      isPlaying = true;
      position = Duration.zero;
      duration = Duration.zero;
      notifyListeners();

      log("Starting playback...");

      /// LISTENERS (⚠️ ideally setup once in init)
      _player.onDurationChanged.listen((d) {
        duration = d;
        log("Audio duration updated: $duration");
        notifyListeners();
      });

      _player.onPositionChanged.listen((p) {
        position = p;
        notifyListeners();

        // Manual completion safety
        if (duration.inMilliseconds > 0 &&
            p.inMilliseconds >= duration.inMilliseconds - 50) {
          isPlaying = false;
          currentAudio = null;
          position = Duration.zero;
          notifyListeners();
        }
      });

      _player.onPlayerComplete.listen((event) {
        log("Audio completed");
        isPlaying = false;
        currentAudio = null;
        position = Duration.zero;
        notifyListeners();
      });

      /// 🔥 KEY CHANGE — STREAM INSTEAD OF DOWNLOAD
      // if (path.startsWith("http")) {
      //   await _player.play(UrlSource(path)); // ✅ Direct streaming
      // } else {
      //   await _player.play(DeviceFileSource(path)); // Local file
      // }

      if (path.startsWith("http")) {
        path = await downloadAudio(path); // returns local path
      }

      await _player.play(DeviceFileSource(path));

      log("Audio play command sent");
    } catch (e, st) {
      debugPrint("Audio Play Error: $e");
      log("Stacktrace: $st");

      isPlaying = false;
      currentAudio = null;
      loadingAudio = null;
      position = Duration.zero;
      duration = Duration.zero;
      notifyListeners();
    }
  }

  /// STOP AUDIO
  Future<void> stopAudio() async {
    await _player.stop();
    isPlaying = false;
    currentAudio = null;
    position = Duration.zero;
    notifyListeners();
  }

  /// Pause the currently playing audio
  Future<void> pauseAudio() async {
    try {
      await _player.pause();
      isPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Pause Audio Error: $e");
    }
  }

  /// Resume the currently paused audio
  Future<void> resumeAudio() async {
    try {
      await _player.resume();
      isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Resume Audio Error: $e");
    }
  }

  Future<void> seekAudio(Duration position) async {
    await _player.seek(position);
  }

  /// DISPOSE PLAYER
  void disposePlayer() {
    _player.dispose();
  }

  ///Image Picker (Single Selection Image Without Preview
  // final ImagePicker _picker = ImagePicker();
  // bool isPickingImage = false;
  // Future<void> pickImage(BuildContext context, int otherUser) async {
  //   try
  //   {
  //     final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  //     if (pickedFile != null) {
  //       // Send image
  //       sendMessage( context: context, senderId: localData.currentUserID, otherUser: otherUser, audioPath: '',
  //           // no audio
  //           type: 'image', imagePath: pickedFile.path,
  //       );
  //     }
  //   } catch (e) {
  //     print("Error picking image: $e");
  //   }
  // }
  //
  // String getImageUrl(String path) {
  //   if (path.startsWith("http") || path.startsWith("https")) {
  //     return path;
  //     // already full URL
  //   } else if (path.startsWith("/data/")) {
  //     return path;
  //     // local file path
  //   } else if (path.isNotEmpty) {
  //     return "${ApiUrls.imageUrl}$path";
  //   } else {
  //     return "";
  //   }
  // }

  ///Image Picker
  final ImagePicker _picker = ImagePicker();
  bool isPickingImage = false;

  /// Store selected images
  List<File> selectedImages = [];

  /// Pick image from camera
  Future<void> pickFromCamera(BuildContext context, int otherUser) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        File file = File(pickedFile.path);
        selectedImages.add(file);
        _sendImages(context, otherUser);
      }
    } catch (e) {
      print("Error picking camera image: $e");
    }
  }

  /// Pick multiple images from gallery
  Future<void> pickFromGallery(BuildContext context, int otherUser) async {
    try {

      final List<XFile>? pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles != null && pickedFiles.isNotEmpty) {

        selectedImages = pickedFiles.map((e) => File(e.path)).toList();

        /// Preview before sending
        // await showDialog(
        //   context: context,
        //   builder: (context) {
        //     return StatefulBuilder(
        //       builder: (context, setState) {
        //
        //         Future addMoreImages() async {
        //
        //           final List<XFile>? pickedFiles = await _picker.pickMultiImage();
        //
        //           if (pickedFiles != null && pickedFiles.isNotEmpty) {
        //
        //             List<File> newImages =
        //             pickedFiles.map((e) => File(e.path)).toList();
        //
        //             setState(() {
        //               selectedImages.addAll(newImages); // add new images
        //             });
        //
        //           }
        //         }
        //
        //         return AlertDialog(
        //           backgroundColor: AppColor.containerColor,
        //           shape: RoundedRectangleBorder(
        //             borderRadius: BorderRadius.circular(10)
        //           ),
        //           title: Row(
        //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //             children: [
        //               Text("Preview Images"),
        //               /// ➕ Add more images
        //               IconButton(
        //                 icon: Icon(Icons.add),
        //                 onPressed: () async {
        //                   await addMoreImages();
        //                 },
        //               )
        //
        //             ],
        //           ),
        //
        //           content: CustomContainer(
        //             containerWidth: double.maxFinite,
        //             containerHeight: 300,
        //             borderRadius: BorderRadius.circular(10),
        //             childWidget: GridView.builder(
        //               gridDelegate:
        //               const SliverGridDelegateWithFixedCrossAxisCount(
        //                 crossAxisCount: 3,
        //                 mainAxisSpacing: 5,
        //                 crossAxisSpacing: 5,
        //               ),
        //
        //               itemCount: selectedImages.length,
        //
        //               itemBuilder: (context, index) {
        //
        //                 return Stack(
        //                   children: [
        //
        //                     Image.file(
        //                       selectedImages[index],
        //                       fit: BoxFit.cover,
        //                       width: double.infinity,
        //                     ),
        //
        //                     /// ❌ Remove image
        //                     Positioned(
        //                       right: 0,
        //                       top: 0,
        //                       child: GestureDetector(
        //                         onTap: () {
        //
        //                           setState(() {
        //                             selectedImages.removeAt(index);
        //                           });
        //
        //                         },
        //                         child: Container(
        //                           color: Colors.black54,
        //                           child: const Icon(
        //                             Icons.close,
        //                             color: Colors.white,
        //                           ),
        //                         ),
        //                       ),
        //                     )
        //
        //                   ],
        //                 );
        //
        //               },
        //             ),
        //           ),
        //
        //           actions: [
        //
        //             TextButton(
        //               onPressed: () {
        //                 Navigator.pop(context);
        //                 _sendImages(context, otherUser);
        //               },
        //               child: MyText(title: "Send",textColor: AppColor.primaryColor,fontWeight: FontWeight.bold,),
        //             ),
        //
        //             TextButton(
        //               onPressed: () {
        //                 selectedImages.clear();
        //                 Navigator.pop(context);
        //               },
        //               child: MyText(title: "Cancel",textColor: Colors.grey,fontWeight: FontWeight.bold,),
        //             ),
        //
        //           ],
        //         );
        //       },
        //     );
        //   },
        // );

        await showDialog(
          context: context,
          builder: (context) {

            int selectedIndex = 0;

            return StatefulBuilder(
              builder: (context, setState) {

                Future addMoreImages() async {

                  final List<XFile>? pickedFiles = await _picker.pickMultiImage();

                  if (pickedFiles != null && pickedFiles.isNotEmpty) {

                    List<File> newImages =
                    pickedFiles.map((e) => File(e.path)).toList();

                    setState(() {
                      selectedImages.addAll(newImages);
                    });

                  }
                }

                return AlertDialog(
                  backgroundColor: AppColor.containerColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),

                  title: const Text("Preview Images"),

                  content: SizedBox(
                    width: double.maxFinite,
                    height: 350,

                    child: Column(
                      children: [

                        /// 🔵 BIG IMAGE PREVIEW
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              selectedImages[selectedIndex],
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// 🔵 HORIZONTAL IMAGE LIST
                        SizedBox(
                          height: 70,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [

                              /// 🔵 SCROLLABLE IMAGE LIST
                              Flexible(
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: selectedImages.length,

                                  separatorBuilder: (context, index) => const SizedBox(width: 6),

                                  itemBuilder: (context, index) {

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedIndex = index;
                                        });
                                      },

                                      child: Stack(
                                        children: [

                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: selectedIndex == index
                                                    ? AppColor.primaryColor
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                            ),

                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: Image.file(
                                                selectedImages[index],
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),

                                          /// ❌ REMOVE IMAGE
                                          Positioned(
                                            right: 2,
                                            top: 2,
                                            child: GestureDetector(
                                              onTap: () {

                                                setState(() {

                                                  selectedImages.removeAt(index);

                                                  if (selectedImages.isEmpty) {
                                                    Navigator.pop(context);
                                                    return;
                                                  }

                                                  if (selectedIndex >= selectedImages.length) {
                                                    selectedIndex = selectedImages.length - 1;
                                                  }

                                                });

                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          )

                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(width: 8),

                              /// ➕ FIXED ADD BUTTON
                              InkWell(
                                onTap: () async {
                                  await addMoreImages();
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.add),
                                ),
                              ),

                            ],
                          ),
                        )

                      ],
                    ),
                  ),

                  actions: [

                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _sendImages(context, otherUser);
                      },
                      child: MyText(
                        title: "Send",
                        color: AppColor.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        selectedImages.clear();
                        Navigator.pop(context);
                      },
                      child: MyText(
                        title: "Cancel",
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  ],
                );
              },
            );
          },
        );
      }
    } catch (e) {
      print("Error picking gallery images: $e");
    }
  }

  /// Send all selected images
  void _sendImages(BuildContext context, int otherUser) {
    for (var img in selectedImages) {
      sendMessage(
        context: context,
        senderId: localData.currentUserID,
        otherUser: otherUser,
        audioPath: '', // no audio
        type: 'image',
        imagePath: img.path,
      );
    }
    selectedImages.clear(); // clear after sending
  }

  /// Your existing function to get image url
  String getImageUrl(String path) {
    if (path.startsWith("http") || path.startsWith("https")) {
      return path; // already full URL
    } else if (path.startsWith("/data/")) {
      return path; // local file path
    } else if (path.isNotEmpty) {
      return "${ApiUrls.imageUrl}$path";
    } else {
      return "";
    }
  }


  ///Make phone Call
  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      print("Could not launch dialer");
    }
  }
  ///Send Email

  Future<void> openGmail(String email) async {

    final Uri gmailUri = Uri.parse(
        "https://mail.google.com/mail/?view=cm&fs=1&to=$email");

    if (await canLaunchUrl(gmailUri)) {
      await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
    } else {
      print("Could not open Gmail");
    }

  }



  ///Delete Messages
  Future<void> DeleteMessage({
    required BuildContext context,
    required dynamic messageId,
    required String active,
  }) async {

    /// 🔥 Find message index
    final index = _messages.indexWhere((m) => m.id == messageId);

    if (index == -1) return;

    final backupMessage = _messages[index];

    if (active == '2') {
      /// Delete for me → delay + remove
      Future.delayed(const Duration(milliseconds: 400), () {
        if (index < _messages.length) {
          _messages.removeAt(index);
          notifyListeners();
        }
      });

    } else if (active == '3') {
      /// Delete for everyone → delay + mark
      Future.delayed(const Duration(milliseconds: 400), () {
        if (index < _messages.length) {
          _messages[index].active = 3;
          notifyListeners();
        }
      });
    }

    notifyListeners();

    try {

      final response = await _messageRepository.deleteMessages(
        messageId: messageId,
        active: active,
      );

      if (response.status == true) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: MyText(
              title: response.message,
              color: AppColor.whiteTextColor,
            ),
            duration: Duration(seconds: 2),
          ),
        );

      } else {

        /// ❌ Restore if server says failed
        _restoreMessage(index, backupMessage);

      }

    } catch (e) {

      /// ❌ Restore on network error
      _restoreMessage(index, backupMessage);

      log("Delete Message Provider Error: $e");
    }
  }

  void _restoreMessage(int index, Message backupMessage) {
    _messages.insert(index, backupMessage);
    notifyListeners();
  }

}