import 'dart:ui';

// Use as a helper in face recognition, not related to database
class Recognition {
  String name;
  Rect location;
  List<double> embeddings;
  double distance;

  /// Constructs a Category.
  Recognition(this.name, this.location, this.embeddings, this.distance);
}
