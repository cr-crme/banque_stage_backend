import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';

const _regExp =
    r'^(?:\+\(d{1,3})?\s?\(?(\d{3})(?:[-.\)\s]|\)\s)?(\d{3})[-.\s]?(\d{4})(?:\s(?:poste)?\s(\d{1,6}))?$';

class PhoneNumber extends ItemSerializable {
  final String? areaCode;
  final String? cityCode;
  final String? number;
  final String? extension;

  static bool isValid(String number) => RegExp(_regExp).hasMatch(number);

  PhoneNumber(
      {super.id, this.areaCode, this.cityCode, this.number, this.extension});

  static PhoneNumber get empty => PhoneNumber();

  factory PhoneNumber.fromString(number, {String? id}) {
    final reg = RegExp(_regExp);
    if (!reg.hasMatch(number)) return PhoneNumber.empty;

    final result = RegExp(_regExp).firstMatch(number)!;
    if (result.groupCount != 4) {
      throw 'Invalid number if PhoneNumber constructor';
    }

    return PhoneNumber(
        id: id,
        areaCode: result.group(1),
        cityCode: result.group(2),
        number: result.group(3),
        extension: result.group(4));
  }

  @override
  Map<String, dynamic> serializedMap() => {'phone_number': toString()};

  static PhoneNumber fromSerialized(map) =>
      PhoneNumber.fromString(map['phone_number'], id: map['id']);

  @override
  String toString() {
    return areaCode == null || cityCode == null || number == null
        ? ''
        : '($areaCode) $cityCode-$number${extension != null ? ' poste $extension' : ''}';
  }
}
