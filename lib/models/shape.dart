class Shape {
  final String name;
  final String imageUrl;

  Shape({
    required this.name,
    required this.imageUrl,
  });

  factory Shape.fromJson(Map<String, dynamic> json) => Shape(
    name: json['name'],
    imageUrl: json['imageUrl'],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'imageUrl': imageUrl,
  };
}
