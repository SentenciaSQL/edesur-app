class DemoException implements Exception {
  DemoException(this.message);
  final String message;

  @override
  String toString() => message;
}
