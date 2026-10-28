class VisitorModel {
  static const _unset = Object();

  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String visitorType;
  final String project;
  final String purpose;
  final String status;
  final String createdAt;
  final String? checkInTime;
  final String? checkOutTime;

  const VisitorModel({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    required this.visitorType,
    required this.project,
    required this.purpose,
    this.status = 'Registered',
    required this.createdAt,
    this.checkInTime,
    this.checkOutTime,
  });

  factory VisitorModel.fromJson(Map<String, dynamic> json) {
    return VisitorModel(
      id: _stringValue(json['id']),
      name: _stringValue(json['name']),
      mobile: _stringValue(json['mobile']),
      email: json['email']?.toString(),
      visitorType: _stringValue(json['visitor_type']),
      project: _stringValue(json['project']),
      purpose: _stringValue(json['purpose']),
      status: _stringValue(json['status'], fallback: 'Registered'),
      createdAt: _stringValue(json['created_at']),
      checkInTime: _nullableString(json['check_in_time']),
      checkOutTime: _nullableString(json['check_out_time']),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'name': name,
      'mobile': mobile,
      'email': email,
      'visitor_type': visitorType,
      'project': project,
      'purpose': purpose,
      'status': status,
      'created_at': createdAt,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
    };
  }

  VisitorModel copyWith({
    String? id,
    String? name,
    String? mobile,
    Object? email = _unset,
    String? visitorType,
    String? project,
    String? purpose,
    String? status,
    String? createdAt,
    Object? checkInTime = _unset,
    Object? checkOutTime = _unset,
  }) {
    return VisitorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: identical(email, _unset) ? this.email : email as String?,
      visitorType: visitorType ?? this.visitorType,
      project: project ?? this.project,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      checkInTime: identical(checkInTime, _unset)
          ? this.checkInTime
          : checkInTime as String?,
      checkOutTime: identical(checkOutTime, _unset)
          ? this.checkOutTime
          : checkOutTime as String?,
    );
  }

  static String _stringValue(dynamic value, {String fallback = ''}) =>
      value == null ? fallback : value.toString();

  static String? _nullableString(dynamic value) => value?.toString();
}
