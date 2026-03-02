class ComplaintSession {
  static String? helpId;

  static bool get isActive => helpId != null;

  static void start(String id) {
    helpId = id;
  }

  static void clear() {
    helpId = null;
  }
}
