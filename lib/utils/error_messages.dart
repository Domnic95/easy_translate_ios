String friendlyTranslationError(Object e) {
  final type = e.runtimeType.toString();
  final s = e.toString();

  if (type == 'LanguageNotSupportedException' ||
      s.contains('LanguageNotSupportedException')) {
    return 'This language pair is not supported. Try another language.';
  }
  if (type.contains('Timeout') || s.contains('TimeoutException')) {
    return 'Request timed out. Check your connection and try again.';
  }
  if (s.contains('SocketException') ||
      s.contains('HandshakeException') ||
      s.contains('Failed host lookup') ||
      s.contains('Network is unreachable')) {
    return 'No internet connection. Try again when online.';
  }
  if (s.contains('ClientException') || s.contains('HttpException')) {
    return 'Translation service temporarily unavailable. Please try again.';
  }
  return 'Translation failed. Please try again.';
}
