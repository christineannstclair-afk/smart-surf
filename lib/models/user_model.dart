enum SurfLevel {
  whitewater,
  assistedGreen,
  independentGreen,
  developingTurns,
  linkingTurns,
}

class UserModel {
  final String name;
  final SurfLevel level;
  final String comfortWaveHeight;
  final List<String> workingOn;

  UserModel({
    required this.name,
    required this.level,
    required this.comfortWaveHeight,
    required this.workingOn,
  });
}