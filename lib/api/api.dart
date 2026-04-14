class ApiUrls {
  static const String domain = "https://dash.fullcomm.in";

  static const String subdomain = "V1";

  static const String script = "$domain/$subdomain/chatscript.php";

  static const String audioUrl = "$script?data=getFile&file=";

  static const String imageUrl = "$script?data=getImageFile&file=";

  static const String fileUrl = "$script?data=getDocumentFile&file=";

  static const String videoUrl = "$script?data=getVideoFile&file=";

}
