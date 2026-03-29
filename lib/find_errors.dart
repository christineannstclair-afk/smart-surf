import 'dart:io';

void main() {
  final lines = File('build_log.txt').readAsLinesSync();
  int count = 0;
  for (final line in lines) {
    if (line.contains('Error:') || line.contains('.dart:')) {
      print(line);
      count++;
      if (count > 40) return;
    }
  }
}
