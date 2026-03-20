import 'package:intl/intl.dart';

// String formatMessageTime(DateTime time) {
//   final now = DateTime.now();
//   final difference = now.difference(time);
//
//   if (difference.inSeconds < 60) {
//     return "Just now";
//   }
//
//   if (difference.inMinutes < 60) {
//     return "${difference.inMinutes} min ago";
//   }
//
//   if (difference.inHours < 24 &&
//       now.day == time.day &&
//       now.month == time.month &&
//       now.year == time.year) {
//     return DateFormat('hh:mm a').format(time); // 10:45 AM
//   }
//
//   if (difference.inDays == 1) {
//     return "Yesterday";
//   }
//
//   return DateFormat('dd MMM, hh:mm a').format(time);
// }
String formatMessageTime(DateTime time) {

  final now = DateTime.now();
  final difference = now.difference(time);

  /// ⭐ Very recent
  if (difference.inSeconds < 60) {
    return "Just now";
  }

  /// ⭐ Within 1 hour
  if (difference.inMinutes < 60) {
    return "${difference.inMinutes} min";
  }

  /// ⭐ SAME DAY → show time only
  if (now.day == time.day &&
      now.month == time.month &&
      now.year == time.year) {
    return DateFormat('h:mm a').format(time); // 2:30 PM
  }

  /// ⭐ OTHER DAYS → STILL TIME ONLY (header shows date)
  return DateFormat('h:mm a').format(time);
}
String formatDateHeader(DateTime date) {

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final msgDate = DateTime(date.year, date.month, date.day);

  if (msgDate == today) {
    return "Today";
  }

  if (msgDate == today.subtract(const Duration(days: 1))) {
    return "Yesterday";
  }

  return DateFormat("MMM d").format(date); // Mar 5
}