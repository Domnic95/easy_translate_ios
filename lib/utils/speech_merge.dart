import 'dart:math' as math;

String smartMergeSpeech(String acc, String next) {
  if (acc.isEmpty) return next;
  if (next.isEmpty) return acc;

  final a = acc.toLowerCase();
  final n = next.toLowerCase();

  if (n.contains(a)) return next;

  if (a.contains(n)) return acc;

  final maxOverlap = math.min(acc.length, next.length);
  for (var len = maxOverlap; len > 0; len--) {
    if (a.endsWith(n.substring(0, len))) {
      return acc + next.substring(len);
    }
  }

  return '$acc $next';
}
