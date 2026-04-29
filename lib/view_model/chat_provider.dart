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
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../model/message_response.dart';
import '../model/user_response.dart';
import '../repo/message_repo.dart';
import '../res/components/customText.dart';

import 'package:file_picker/file_picker.dart';



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
    _isLoading = false;
    notifyListeners();
  }

  // void clearChat(String userId) {
  //   currentChatUserId = userId;
  //   _messages = [];
  //   _isLoading = true;
  //   hasLoadedOnce = false;
  //   stopPolling();
  //   notifyListeners();
  // }

  void resetChat() {
    messages.clear();
    hasLoadedOnce = false;
    _isLoading = true;
    stopPolling();
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


  void updateLastMessage(String userId, String message) {
    int index = users.indexWhere((u) => u.id.toString() == userId);

    if (index != -1) {
      var user = users.removeAt(index);

      user.lastMessage = message;
      user.lastChatTime = DateTime.now().toString();

      users.insert(0, user);

      notifyListeners();
    }
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

  String? currentChatUserId;

  bool hasLoadedOnce = false;

  Timer? _pollingTimer;
  bool _isFetching = false;

  void startPolling(String userId, BuildContext context, dynamic otherUser) {
    stopPolling(); // prevent duplicate timers

    log("I am called Again by polling!!!");

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {

      /// 🔥 stop if user changed chat
      if (currentChatUserId != userId) {
        stopPolling();
        return;
      }

      await MessageData(
        context: context,
        otherUser: otherUser,
        isPolling: true, // 🔥 identify polling call
      );
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // Future<void> MessageData({
  //   required BuildContext context,
  //   required dynamic otherUser,
  // }) async {
  //
  //   final userId = otherUser.toString();
  //   currentChatUserId = userId;
  //
  //   try {
  //
  //     _isLoading = true;
  //     hasLoadedOnce = false;
  //     notifyListeners();
  //
  //     final response = await _messageRepository.getMessages(
  //       otherUser: otherUser,
  //     );
  //
  //     if (currentChatUserId != userId) return;
  //
  //     if (response.status == true) {
  //       _messages = response.data;
  //     }
  //
  //   } catch (e) {
  //     log("Error: $e");
  //   } finally {
  //
  //     if (currentChatUserId == userId) {
  //       _isLoading = false;
  //       hasLoadedOnce = true; // ⭐ data ready
  //       notifyListeners();
  //     }
  //   }
  // }

  ///Till Morning 1.11 PM
  // Future<void> MessageData({
  //   required BuildContext context,
  //   required dynamic otherUser,
  //   bool isPolling = false, // 🔥 new param
  // }) async {
  //   if (_isFetching) return;
  //
  //   final userId = otherUser.toString();
  //   currentChatUserId = userId;
  //
  //   _isFetching = true;
  //
  //   try {
  //
  //     /// Don't show loading every polling
  //     if (!isPolling) {
  //       _isLoading = true;
  //       hasLoadedOnce = false;
  //       notifyListeners();
  //     }
  //
  //     final response = await _messageRepository.getMessages(
  //       otherUser: otherUser,
  //     );
  //
  //     /// user changed chat → ignore response
  //     if (currentChatUserId != userId) return;
  //
  //     if (response.status == true) {
  //
  //       final newMessages = response.data;
  //
  //       if (!isPolling) {
  //         /// First load → full replace
  //         _messages = newMessages;
  //       } else {
  //         /// Polling → merge messages
  //
  //         for (var msg in newMessages) {
  //
  //           /// 🔍 Check if already exists (by ID OR by content match)
  //           final existingIndex = _messages.indexWhere((m) =>
  //           m.id == msg.id ||
  //               (
  //                   m.senderId == msg.senderId &&
  //                       m.receiverId == msg.receiverId &&
  //                       m.message == msg.message &&
  //                       m.type == msg.type
  //               )
  //           );
  //
  //           if (existingIndex == -1) {
  //             /// ✅ New message → add
  //             _messages.add(msg);
  //           } else {
  //             /// 🔥 Replace temp with server message
  //             _messages[existingIndex] = msg;
  //           }
  //         }
  //       }
  //     }
  //
  //   } catch (e) {
  //     log("Error: $e");
  //   } finally {
  //
  //     if (currentChatUserId == userId) {
  //
  //       /// ❌ avoid loader flicker during polling
  //       if (!isPolling) {
  //         _isLoading = false;
  //         hasLoadedOnce = true;
  //       }
  //
  //       notifyListeners();
  //     }
  //
  //     _isFetching = false; // 🔥 release lock
  //   }
  // }

  ///Temp Id for the Polling
  String? tempId;

  Future<void> MessageData({
    required BuildContext context,
    required dynamic otherUser,
    bool isPolling = false,
  }) async {

    if (_isFetching) return;

    final userId = otherUser.toString();
    currentChatUserId = userId;

    _isFetching = true;

    try {

      if (!isPolling) {
        _isLoading = true;
        hasLoadedOnce = false;
        notifyListeners();
      }

      final response = await _messageRepository.getMessages(
        otherUser: otherUser,
      );

      if (currentChatUserId != userId) return;

      if (response.status == true) {

        final newMessages = response.data;

        if (!isPolling) {

          _messages = newMessages;

        } else {

          for (var msg in newMessages) {

            final existingIndex = _messages.indexWhere((m) =>
            m.id == msg.id ||

                /// 🔥 SMART MATCH (fallback)
                (
                    m.senderId == msg.senderId &&
                        m.receiverId == msg.receiverId &&
                        m.type == msg.type &&
                        (
                            m.message == msg.message || // text
                                m.audioPath == msg.audioPath || // voice
                                m.imagePath == msg.imagePath || // image
                                m.videoPath == msg.videoPath // video
                        ) &&
                        m.createdAt.difference(msg.createdAt).inSeconds.abs() < 5
                )
            );

            if (existingIndex == -1) {
              _messages.add(msg);
            } else {
              _messages[existingIndex] = msg;
            }
          }
        }

        /// 🔥 SORT FIX (VERY IMPORTANT)
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }

    } catch (e) {
      log("Error: $e");
    } finally {

      if (currentChatUserId == userId) {

        if (!isPolling) {
          _isLoading = false;
          hasLoadedOnce = true;
        }

        notifyListeners();
      }

      _isFetching = false;
    }
  }

  // Send Message

  Future<void> sendMessage({
    required BuildContext context,
    required int senderId,
    required int otherUser,
    required String type,

    String? audioPath,
    String? imagePath,
    String? videoPath,
    String? filePath,
    String? fileName,
  }) async {

    final text = messageController.text.trim();

    if (type == "text" && text.isEmpty) return;

    messageController.clear();

    /// 🧠 LOCAL MESSAGE
    final tempMessage = Message(
      id: 0, // 🔥 IMPORTANT (dummy id)

      senderId: senderId,
      receiverId: otherUser,

      message: type == "voice"
          ? audioPath ?? ""
          : type == "video"
          ? "Video"
          : type == "file"
          ? fileName ?? "File"
          : text,

      createdAt: DateTime.now(),
      senderName: localData.currentUserName,
      type: type,

      audioPath: audioPath ?? "",
      imagePath: imagePath ?? "",
      videoPath: videoPath ?? "",
      filePath: filePath ?? "",
      fileName: fileName ?? "",
    );

    _messages.add(tempMessage);

    updateLastMessage(
      otherUser.toString(),
      type == "voice"
          ? "Voice message"
          : type == "image"
          ? "Image"
          : type == "video"
          ? "Video"
          : type == "file"
          ? fileName ?? "File"
          : text,
    );

    notifyListeners();

    /// 🔽 Scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatScrollController.hasClients) {
        chatScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {

      final response = await _messageRepository.sendMessages(
        message: type == "voice"
            ? audioPath
            : type == "video"
            ? videoPath
            : text,

        otherUser: otherUser,
        senderId: senderId,
        type: type,

        audioPath: audioPath,
        imagePath: imagePath,
        videoPath: videoPath,
        filePath: filePath,
        fileName: fileName,
      );

      if (response.status == true) {

        /// 🔥 FIND AND UPDATE MESSAGE
        // final index = _messages.indexWhere((m) =>
        // m.id == 0 && // 🔥 local message
        //     m.senderId == senderId &&
        //     m.type == type &&
        //     (
        //         m.message == tempMessage.message ||
        //             m.audioPath == tempMessage.audioPath ||
        //             m.imagePath == tempMessage.imagePath ||
        //             m.videoPath == tempMessage.videoPath
        //     )
        // );

        final index = _messages.indexOf(tempMessage);

        if (index != -1) {

          _messages[index].id = response.id;

          _messages[index].filePath =
              response.filePath ?? _messages[index].filePath;

          _messages[index].fileName =
              response.fileName ?? _messages[index].fileName;

          _messages[index].imagePath =
              response.imagePath ?? _messages[index].imagePath;

          _messages[index].audioPath =
              response.audioPath ?? _messages[index].audioPath;

          _messages[index].videoPath =
              response.videoPath ?? _messages[index].videoPath;
        }

        notifyListeners();

      } else {

        tempMessage.isFailed = true;
        notifyListeners();
      }

    } catch (e) {

      tempMessage.isFailed = true;
      notifyListeners();
    }
  }

  Future<void> resendMessage(Message msg) async {

    final newTempId = DateTime.now().millisecondsSinceEpoch.toString();

    msg.isFailed = false;

    notifyListeners();

    try {

      final response = await _messageRepository.sendMessages(
        senderId: msg.senderId,
        otherUser: msg.receiverId,
        message: msg.type == "text" ? msg.message : "",
        type: msg.type,

        audioPath: msg.type == "voice" ? msg.audioPath : null,
        imagePath: msg.type == "image" ? msg.imagePath : null,
        videoPath: msg.type == "video" ? msg.videoPath : null,
        filePath: msg.type == "file" ? msg.filePath : null,
        fileName: msg.fileName,
      );

      if (response.status == true) {

        msg.id = response.id;
        msg.isFailed = false;

      } else {

        msg.isFailed = true;
      }

      notifyListeners();

    } catch (e) {

      msg.isFailed = true;
      notifyListeners();
    }
  }

  final Map<String, Duration> audioDurations = {};

  /// Audio Recorder
  final AudioRecorder _recorder = AudioRecorder();
  bool isRecording = false;
  String? audioPath;

  Duration recordingDuration = Duration.zero;
  Timer? _recordTimer;

  /// Audio Player
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _durationPlayer = AudioPlayer();
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
      filePath: '', fileName: '',
    );
  }

  // Future<void> loadAudioDuration(String path) async {
  //   try {
  //     log("Loading duration for: $path");
  //
  //     String localPath = path;
  //
  //     /// If network → download first
  //     if (path.startsWith("http")) {
  //       localPath = await downloadAudio(path);
  //     }
  //
  //     /// 🔥 IMPORTANT → set source மட்டும் போதும் (play வேண்டாம்)
  //     await _durationPlayer.setSource(DeviceFileSource(localPath));
  //
  //     duration = await _durationPlayer.getDuration() ?? Duration.zero;
  //
  //     log("Duration loaded: $duration");
  //
  //     notifyListeners();
  //   } catch (e) {
  //     log("Duration load error: $e");
  //   }
  // }

  // Future<void> loadAudioDuration(String path) async {
  //   try {
  //     // ✅ Already loaded — skip
  //     if (audioDurations.containsKey(path)) return;
  //
  //     log("Loading duration for: $path");
  //
  //     String localPath = path;
  //
  //     /// If network → download first
  //     if (path.startsWith("http")) {
  //       localPath = await downloadAudio(path);
  //     }
  //
  //     /// set source மட்டும்
  //     await _durationPlayer.setSource(DeviceFileSource(localPath));
  //
  //     final dur = await _durationPlayer.getDuration() ?? Duration.zero;
  //
  //     log("Duration loaded: $dur for $path");
  //
  //     // ✅ CHANGE: global duration-ல save பண்ணாம, map-ல save பண்ணு
  //     audioDurations[path] = dur;
  //
  //     notifyListeners();
  //   } catch (e) {
  //     log("Duration load error: $e");
  //   }
  // }

  Future<void> loadAudioDuration(String path) async {
    try {
      // ✅ Already loaded — skip
      if (audioDurations.containsKey(path)) return;

      log("Loading duration for: $path");

      String localPath = path;

      /// If network → download first
      if (path.startsWith("http")) {
        localPath = await downloadAudio(path);
      }


      final tempPlayer = AudioPlayer();

      await tempPlayer.setSource(DeviceFileSource(localPath));

      final dur = await tempPlayer.getDuration() ?? Duration.zero;

      log("Duration loaded: $dur for $path");

      audioDurations[path] = dur;

      await tempPlayer.dispose();

      notifyListeners();
    } catch (e) {
      log("Duration load error: $e");
    }
  }

  /// PLAY VOICE
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
        filePath: '', fileName: '',
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

  ///Video Picker
  void showVideoOptions(BuildContext context, int otherUser) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text("Record Video"),
            onTap: () {
              Navigator.pop(context);
              pickVideoFromCamera(context, otherUser);
            },
          ),

          ListTile(
            leading: const Icon(Icons.video_library),
            title: const Text("Gallery Video"),
            onTap: () {
              Navigator.pop(context);
              pickVideoFromGallery(context, otherUser);
            },
          ),

        ],
      ),
    );
  }

  Future<void> pickVideoFromCamera(BuildContext context, int otherUser) async {
    try {
      final XFile? video =
      await _picker.pickVideo(source: ImageSource.camera);

      if (video != null) {
        sendMessage(
          context: context,
          senderId: localData.currentUserID,
          otherUser: otherUser,
          type: "video",

          videoPath: video.path,   // ✅ THIS IS REQUIRED

          imagePath: '',
          filePath: '',
          fileName: '',
          audioPath: '',
        );
      }
    } catch (e) {
      print("Camera video error: $e");
    }
  }

  Future<void> pickVideoFromGallery(BuildContext context, int otherUser) async {
    try {
      final XFile? video =
      await _picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        sendMessage(
          context: context,
          senderId: localData.currentUserID,
          otherUser: otherUser,
          type: "video",

          videoPath: video.path,   // ✅ THIS IS REQUIRED

          imagePath: '',
          filePath: '',
          fileName: '',
          audioPath: '',
        );
      }
    } catch (e) {
      print("Gallery video error: $e");
    }
  }

  String getVideoUrl(String path) {
    if (path.startsWith("http") || path.startsWith("https")) {
      return path; // already full URL
    } else if (path.startsWith("/data/")) {
      return path; // local file path
    } else if (path.isNotEmpty) {
      return "${ApiUrls.videoUrl}$path";
    } else {
      return "";
    }
  }

  VideoPlayerController? videoController;

  bool isVideoLoading = true;

  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  /// 🔥 MAIN INIT
  // Future<void> initialize(String videoUrl) async {
  //   isVideoLoading = true;
  //   notifyListeners();
  //
  //   await videoController?.dispose();
  //
  //   /// 🔥 DOWNLOAD VIDEO FIRST
  //   final file = await _getVideoFile(videoUrl);
  //
  //   /// 🔥 PLAY FROM LOCAL FILE
  //   videoController = VideoPlayerController.file(file);
  //
  //   await videoController!.initialize();
  //
  //   totalDuration = videoController!.value.duration;
  //
  //   videoController!.addListener(_videoListener);
  //
  //   isVideoLoading = false;
  //   notifyListeners();
  //
  //   await videoController!.play();
  // }

  Future<void> initialize(String videoUrl) async {
    isVideoLoading = true;
    notifyListeners();

    await videoController?.dispose();

    final dir = await getTemporaryDirectory();
    final fileName = videoUrl.split('/').last;
    final file = File('${dir.path}/$fileName');

    /// ✅ CASE 1: already downloaded → local
    if (await file.exists()) {
      videoController = VideoPlayerController.file(file);
    } else {
      /// ✅ CASE 2: first time → play network (FAST)
      videoController =
          VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      /// 🔥 download in background
      _downloadInBackground(videoUrl, file);
    }

    await videoController!.initialize();

    totalDuration = videoController!.value.duration;

    videoController!.addListener(_videoListener);

    isVideoLoading = false;
    notifyListeners();

    await videoController!.play();
  }

  Future<void> _downloadInBackground(String url, File file) async {
    try {
      if (await file.exists()) return;

      final response = await http.get(Uri.parse(url));
      await file.writeAsBytes(response.bodyBytes);

      /// 🔥 OPTIONAL: switch to local after download
      final currentPos = videoController?.value.position ?? Duration.zero;

      await videoController?.dispose();

      videoController = VideoPlayerController.file(file);

      await videoController!.initialize();

      videoController!.addListener(_videoListener);

      await videoController!.seekTo(currentPos);
      await videoController!.play();

      notifyListeners();
    } catch (e) {
      debugPrint("Download error: $e");
    }
  }

  /// 🔥 DOWNLOAD + CACHE
  Future<File> _getVideoFile(String url) async {
    final dir = await getTemporaryDirectory();

    /// create unique file name
    final fileName = url.split('/').last;
    final file = File('${dir.path}/$fileName');

    /// ✅ if already downloaded → reuse
    if (await file.exists()) {
      return file;
    }

    /// 🔥 download
    final response = await http.get(Uri.parse(url));

    await file.writeAsBytes(response.bodyBytes);

    return file;
  }

  /// 🔥 LISTENER
  void _videoListener() {
    if (videoController == null) return;

    final value = videoController!.value;

    if (value.isInitialized) {
      currentPosition = value.position;
      totalDuration = value.duration;
    }

    notifyListeners();
  }

  /// ▶️ Play / Pause
  void togglePlayPause() {
    if (videoController == null) return;

    if (videoController!.value.isPlaying) {
      videoController!.pause();
    } else {
      videoController!.play();
    }

    notifyListeners();
  }

  /// ⏸ Pause while dragging
  void pauseVideo() {
    videoController?.pause();
  }

  /// 👀 Preview while dragging
  void updateSeekPreview(int seconds) {
    currentPosition = Duration(seconds: seconds);
    notifyListeners();
  }

  /// 🔥 SEEK FIX (NO DELAY NOW ⚡)
  Future<void> seekAndPlay(int seconds) async {
    if (videoController == null) return;

    final controller = videoController!;
    final position = Duration(seconds: seconds);

    try {
      await controller.seekTo(position);
      await controller.play(); // ⚡ instant (local file)
    } catch (e) {
      debugPrint("Seek error: $e");
    }

    notifyListeners();
  }

  /// 🧹 Dispose
  void disposeVideo() {
    videoController?.removeListener(_videoListener);
    videoController?.dispose();
    videoController = null;
  }

  ///Pick Document
  Future<void> pickDocument(BuildContext context, int otherUser) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt',
          'mp4', 'mov', 'avi', 'mkv', '3gp',
          'apk'
        ],
        withData: false,
      );

      /// ❌ No file selected
      if (result == null || result.files.isEmpty) {
        print("No file selected");
        return;
      }

      final pickedFile = result.files.single;

      /// ❌ path null check
      if (pickedFile.path == null || pickedFile.path!.isEmpty) {
        print("File path is null or empty ❌");
        return;
      }

      File file = File(pickedFile.path!);
      String fileName = pickedFile.name;

      print("Picked File Path: ${file.path}");
      print("File Name: $fileName");

      /// 🔥 FILE EXISTS CHECK (IMPORTANT)
      if (!await file.exists()) {
        print("File does not exist ❌");
        return;
      }

      /// 🔥 FILE SIZE CHECK (10MB)
      final fileSizeInBytes = await file.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      print("File Size: ${fileSizeInMB.toStringAsFixed(2)} MB");

      if (fileSizeInMB > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File too large (Max 10MB)")),
        );
        return;
      }

      /// 🔥 FINAL DEBUG BEFORE SEND
      print("SENDING FILE...");
      print("filePath => ${file.path}");
      print("fileName => $fileName");

      /// ✅ SEND MESSAGE
      await sendMessage(
        context: context,
        senderId: localData.currentUserID,
        otherUser: otherUser,
        type: "file",

        /// IMPORTANT → NULL instead of ""
        audioPath: null,
        imagePath: null,

        filePath: file.path,
        fileName: fileName,
      );

    } catch (e) {
      print("Error picking document: $e");
    }
  }

  String getFileUrl(String path) {
    if (path.startsWith("http") || path.startsWith("https")) {
      return path;
    } else if (path.startsWith("/data/")) {
      return path; // local
    } else if (path.isNotEmpty) {
      log("File Url Path: ${ApiUrls.fileUrl}$path");
      return "${ApiUrls.fileUrl}$path";
    } else {
      return "";
    }
  }

  Future<void> openFile(String path) async {
    try {
      String filePath = path;

      /// 🔥 CASE 1: LOCAL FILE → DIRECT OPEN
      if (path.startsWith("/") || path.startsWith("file://")) {
        await OpenFilex.open(path);
        return;
      }

      /// 🔥 CASE 2: SERVER FILE (RELATIVE PATH)
      if (!path.startsWith("http")) {

        /// convert to full URL
        final fileUrl = "${ApiUrls.imageUrl}$path";

        final dir = await getApplicationDocumentsDirectory();
        final fileName = path.split('/').last;
        filePath = "${dir.path}/$fileName";

        final file = File(filePath);

        /// download only if not exists
        if (!await file.exists()) {
          print("Downloading file from: $fileUrl");
          await Dio().download(fileUrl, filePath);
        } else {
          print("File already exists locally");
        }
      }

      /// 🔥 CASE 3: FULL URL
      else if (path.startsWith("http")) {

        final dir = await getApplicationDocumentsDirectory();
        final fileName = path.split('/').last;
        filePath = "${dir.path}/$fileName";

        final file = File(filePath);

        if (!await file.exists()) {
          print("Downloading file from: $path");
          await Dio().download(path, filePath);
        }
      }

      /// 🔥 OPEN FILE
      await OpenFilex.open(filePath);

    } catch (e) {
      debugPrint("Open File Error: $e");
    }
  }

  Icon getFileIcon(String? fileName) {
    if (fileName == null) {
      return const Icon(Icons.insert_drive_file, color: Colors.grey);
    }

    if (fileName.endsWith(".pdf")) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red);
    } else if (fileName.endsWith(".xls") || fileName.endsWith(".xlsx")) {
      return const Icon(Icons.table_chart, color: Colors.green);
    } else if (fileName.endsWith(".doc") || fileName.endsWith(".docx")) {
      return const Icon(Icons.description, color: Colors.blue);
    } else {
      return const Icon(Icons.insert_drive_file, color: Colors.grey);
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