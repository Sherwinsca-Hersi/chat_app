import 'package:chat_app/api/api.dart';
import 'package:chat_app/res/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/chat_provider.dart';


class VoiceMessageBubble extends StatefulWidget {
  final String audioPath;

  const VoiceMessageBubble({super.key, required this.audioPath});

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  @override
  void initState() {
    super.initState();

    if (widget.audioPath.isNotEmpty) {

      String fullPath = widget.audioPath.startsWith("/")
          ? widget.audioPath
          : "${ApiUrls.audioUrl}${widget.audioPath}";

      Future.microtask(() {
        final provider = context.read<ChatProvider>();

        /// download (existing)
        if (!widget.audioPath.startsWith("/")) {
          provider.downloadAudio(fullPath);
        }

        /// duration load
        provider.loadAudioDuration(fullPath);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    String playPath =
    widget.audioPath.startsWith("/")
        ? widget.audioPath
        : "${ApiUrls.audioUrl}${widget.audioPath}";

    bool isPlaying =
        chatProvider.isPlaying &&
            chatProvider.currentAudio == playPath;

    bool isLoading =
        chatProvider.loadingAudio != null &&
            chatProvider.loadingAudio == playPath;

    const int waveCount = 15;

    const List<double> heights = [
      6, 10, 14, 8, 16,
      12, 7, 18, 9, 13,
      11, 9, 6, 15, 8,
      17, 10, 12, 7, 14
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [

        /// ▶️ Play / Pause / Loading
        IconButton(
          icon: isLoading
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : Icon(
            isPlaying
                ? Icons.pause
                : Icons.play_arrow,
            color: Colors.grey[350],
          ),
          onPressed: () {
            if (widget.audioPath.isEmpty) {
              debugPrint("Audio path empty");
              return;
            }

            if (chatProvider.currentAudio == playPath) {
              isPlaying
                  ? chatProvider.pauseAudio()
                  : chatProvider.resumeAudio();
            } else {
              chatProvider.playVoice(playPath);
            }
          },
        ),

        const SizedBox(width: 6),

        /// 🎧 Waveform + Duration
        StreamBuilder<Duration>(
          stream: chatProvider.playerPositionStream,
          builder: (context, snapshot) {

            final position = snapshot.data ?? Duration.zero;

            // ✅ CHANGE 1: Use per-audio duration from map instead of global duration
            final Duration totalDuration =
                chatProvider.audioDurations[playPath] ?? Duration.zero;

            double progress = 0.0;

            // ✅ CHANGE 2: Use totalDuration (per-audio) instead of chatProvider.duration
            if (chatProvider.currentAudio == playPath &&
                totalDuration.inMilliseconds > 0 &&
                position.inMilliseconds > 0) {
              progress = (position.inMilliseconds /
                  totalDuration.inMilliseconds)
                  .clamp(0.0, 1.0);
            }

            int activeCount = (progress * waveCount).ceil();

            // ✅ CHANGE 3: Show position when playing THIS audio, else show its own total duration
            Duration displayDuration =
            (chatProvider.currentAudio == playPath && isPlaying)
                ? position
                : totalDuration;

            String formatDuration(Duration d) {
              String twoDigits(int n) =>
                  n.toString().padLeft(2, "0");
              final minutes =
              twoDigits(d.inMinutes.remainder(60));
              final seconds =
              twoDigits(d.inSeconds.remainder(60));
              return "$minutes:$seconds";
            }

            return Row(
              children: [
                /// 🔥 Seekable waveform
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) =>
                      _seekAudio(details.localPosition.dx,
                          context, playPath),
                  onHorizontalDragUpdate: (details) =>
                      _seekAudio(details.localPosition.dx,
                          context, playPath),
                  child: Container(
                    height: 40,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children:
                      List.generate(waveCount, (index) {

                        bool isActive =
                            index < activeCount;

                        return Padding(
                          padding:
                          const EdgeInsets.symmetric(
                              horizontal: 1.5),
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 250),
                            curve: Curves.easeInOut,
                            width: 3,
                            height: heights[index],
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColor.iconColor
                                  : Colors.grey[350],
                              borderRadius:
                              BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                /// ⏱ Duration
                Text(
                  formatDuration(displayDuration),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

void _seekAudio(double dx, BuildContext context, String playPath) {
  final chatProvider = context.read<ChatProvider>();

  // ✅ Also use per-audio duration for seek calculation
  final Duration totalDuration =
      chatProvider.audioDurations[playPath] ?? Duration.zero;

  if (totalDuration.inMilliseconds == 0) return;

  const double totalWidth = 3 * 20 + 1.5 * 2 * 20;

  double percent = (dx / totalWidth).clamp(0.0, 1.0);

  Duration newPosition = Duration(
    milliseconds:
    (totalDuration.inMilliseconds * percent).toInt(),
  );

  chatProvider.seekAudio(newPosition);
}