import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChatMessageShimmer extends StatelessWidget {
  const ChatMessageShimmer({super.key});

  @override
  Widget build(BuildContext context) {

    // ✅ Realistic chat pattern (instead of index % 2)
    final List<bool> shimmerPattern = [
      false, false, true, true, true, false, false, true, false, true, true, false
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: shimmerPattern.length,
      itemBuilder: (context, index) {

        bool isMe = shimmerPattern[index];

        // ✅ Check previous message (for grouping)
        bool isSameUserAsPrevious =
            index > 0 && shimmerPattern[index] == shimmerPattern[index - 1];

        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Align(
            alignment:
            isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: EdgeInsets.only(
                top: isSameUserAsPrevious ? 4 : 10, // 👈 grouping spacing
                bottom: 4,
              ),
              padding: const EdgeInsets.all(12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                // ✅ WhatsApp style bubble
                // borderRadius: BorderRadius.only(
                //   topLeft: const Radius.circular(12),
                //   topRight: const Radius.circular(12),
                //   bottomLeft:
                //   isMe ? const Radius.circular(12) : const Radius.circular(0),
                //   bottomRight:
                //   isMe ? const Radius.circular(0) : const Radius.circular(12),
                // ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ✅ line 1 (dynamic width)
                  Container(
                    height: 10,
                    width: isMe
                        ? (index % 3 == 0 ? 140 : 100)
                        : (index % 3 == 0 ? 180 : 150),
                    color: Colors.white,
                  ),

                  const SizedBox(height: 6),

                  // ✅ line 2 (dynamic width)
                  Container(
                    height: 10,
                    width: isMe
                        ? (index % 2 == 0 ? 80 : 60)
                        : (index % 2 == 0 ? 140 : 110),
                    color: Colors.white,
                  ),

                  const SizedBox(height: 6),

                  // ✅ timestamp shimmer
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      height: 8,
                      width: 30,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}