import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../view_model/chat_provider.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {

  late ChatProvider chatProvider;

  @override
  void initState() {
    super.initState();

    chatProvider = Provider.of<ChatProvider>(context, listen: false);

    Future.microtask(() {
      chatProvider.initialize(widget.videoUrl);
    });

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    chatProvider.disposeVideo();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: chatProvider.isVideoLoading ||
              chatProvider.videoController == null ||
              !chatProvider.videoController!.value.isInitialized
              ? const CircularProgressIndicator()
              : Column(
            children: [
              /// 🎥 VIDEO AREA (flexible)
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio:
                    chatProvider.videoController!.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [

                        VideoPlayer(chatProvider.videoController!),

                        /// ▶️ PLAY / PAUSE
                        GestureDetector(
                          onTap: () {
                            chatProvider.togglePlayPause();
                          },
                          child: Icon(
                            chatProvider.videoController!.value.isPlaying
                                ? Icons.pause_circle
                                : Icons.play_circle,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// 🔽 CONTROLS AREA
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                color: Colors.black,

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    /// ⏱ SEEK BAR
                    Slider(
                      value: chatProvider.currentPosition.inSeconds.toDouble(),
                      max: chatProvider.totalDuration.inSeconds.toDouble(),
                      min: 0,
                      activeColor: Colors.red,
                      inactiveColor: Colors.grey,

                      onChangeStart: (value) {
                        chatProvider.pauseVideo();
                      },
                      onChanged: (value) {
                        chatProvider.updateSeekPreview(value.toInt());
                      },
                      onChangeEnd: (value) {
                        chatProvider.seekAndPlay(value.toInt());
                      },
                    ),

                    /// TIME
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          chatProvider.formatDuration(
                              chatProvider.currentPosition),
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          chatProvider.formatDuration(
                              chatProvider.totalDuration),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    /// CONTROLS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),

                        IconButton(
                          icon: const Icon(Icons.fullscreen,
                              color: Colors.white),
                          onPressed: () {
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.landscapeLeft,
                              DeviceOrientation.landscapeRight,
                            ]);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}