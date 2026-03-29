import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('lib directory not found');
    exit(1);
  }

  print('Walking lib directory...');
  libDir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      _check(entity.path, content, '{', '}');
      _check(entity.path, content, '(', ')');
      _check(entity.path, content, '[', ']');
    }
  });
  print('Done.');
}

void _check(String path, String content, String open, String close) {
  final openCount = content.split(open).length - 1;
  final closeCount = content.split(close).length - 1;
  if (openCount != closeCount) {
    print('Mismatch in $path: $open $openCount, $close $closeCount');
  }
}
