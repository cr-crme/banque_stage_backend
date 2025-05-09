import 'package:common/exceptions.dart';
import 'package:common/models/generic/address.dart';
import 'package:common/models/generic/phone_number.dart';
import 'package:common/models/itineraries/itinerary.dart';
import 'package:common/models/persons/person.dart';

List<String> _stringListFromSerialized(List? list) =>
    (list ?? []).map<String>((e) => e).toList();

class Teacher extends Person {
  final String schoolId;
  final List<String> groups;
  final List<Itinerary> itineraries;

  Teacher({
    super.id,
    required super.firstName,
    required super.middleName,
    required super.lastName,
    required this.schoolId,
    required this.groups,
    required super.email,
    required super.phone,
    required super.address,
    required super.dateBirth,
    required this.itineraries,
  }) {
    if (address.isNotEmpty) {
      throw ArgumentError('Address should not be set for a teacher');
    }
    if (dateBirth != null) {
      throw ArgumentError('Date of birth should not be set for a teacher');
    }
  }

  Teacher.fromSerialized(super.map)
      : schoolId = map['school_id'] ?? '',
        groups = _stringListFromSerialized(map['groups']),
        itineraries = map['itineraries'] == null
            ? []
            : (map['itineraries'] as List)
                .map<Itinerary>((e) => Itinerary.fromSerialized(e))
                .toList(),
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => super.serializedMap()
    ..addAll({
      'school_id': schoolId,
      'groups': groups,
      'itineraries': itineraries.map((e) => e.serializedMap()).toList(),
    });

  @override
  Teacher copyWith({
    String? id,
    String? firstName,
    String? middleName,
    String? lastName,
    String? schoolId,
    List<String>? groups,
    String? email,
    PhoneNumber? phone,
    Address? address,
    DateTime? dateBirth,
    List<Itinerary>? itineraries,
  }) =>
      Teacher(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        middleName: middleName ?? this.middleName,
        lastName: lastName ?? this.lastName,
        schoolId: schoolId ?? this.schoolId,
        groups: groups ?? this.groups,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        dateBirth: dateBirth ?? this.dateBirth,
        address: address ?? this.address,
        itineraries: itineraries ?? this.itineraries,
      );

  Teacher copyWithData(Map<String, dynamic> data) {
    // Make sure data does not contain unrecognized fields
    if (data.keys.any((key) => ![
          'id',
          'first_name',
          'middle_name',
          'last_name',
          'school_id',
          'groups',
          'phone',
          'email',
          'date_birth',
          'address',
          'itineraries',
        ].contains(key))) {
      throw InvalidFieldException('Invalid field data detected');
    }
    return Teacher(
      id: data['id']?.toString() ?? id,
      firstName: data['first_name'] ?? firstName,
      middleName: data['middle_name'] ?? middleName,
      lastName: data['last_name'] ?? lastName,
      schoolId: data['school_id'] ?? schoolId,
      groups: data['groups'] == null
          ? groups
          : _stringListFromSerialized(data['groups']),
      phone: data['phone'] == null
          ? phone
          : PhoneNumber.fromSerialized(data['phone']),
      email: data['email'] ?? email,
      dateBirth: null,
      address: data['address'] == null
          ? address
          : Address.fromSerialized(data['address']),
      itineraries: data['itineraries'] == null
          ? itineraries
          : (data['itineraries'] as List)
              .map<Itinerary>((e) => Itinerary.fromSerialized(e))
              .toList(),
    );
  }

  @override
  String toString() {
    return 'Teacher{${super.toString()}, schoolId: $schoolId, groups: $groups}';
  }
}
