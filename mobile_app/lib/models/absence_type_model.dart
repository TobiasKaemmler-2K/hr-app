class AbsenceTypeModel {
  final String id;
  final String name;
  final String? description;

  AbsenceTypeModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory AbsenceTypeModel.fromJson(Map<String, dynamic> json) {
    return AbsenceTypeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}
