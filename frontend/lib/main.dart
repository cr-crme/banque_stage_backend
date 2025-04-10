import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:common/communication_protocol.dart';
import 'package:common/models/address.dart';
import 'package:common/models/enterprise.dart';
import 'package:common/models/phone_number.dart';
import 'package:common/models/teacher.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_client/web_socket_client.dart';

final Map<String, Teacher> _dummyTeachers = {};
Future<void> _updateTeachers(Map<String, dynamic> data) async {
  if (data.containsKey("id")) {
    // Update a single teacher
    final id = data["id"];
    final teacherData = data;
    _dummyTeachers[id] = _dummyTeachers.containsKey(id)
        ? _dummyTeachers[id]!.copyWithData(teacherData)
        : Teacher.fromSerialized(teacherData);
  } else {
    // Update all teachers
    _dummyTeachers.clear();
    for (final entry in data.entries) {
      final id = entry.key;
      final teacherData = entry.value;
      _dummyTeachers[id] = _dummyTeachers.containsKey(id)
          ? _dummyTeachers[id]!.copyWithData(teacherData)
          : Teacher.fromSerialized(teacherData);
    }
  }
}

final Map<String, Enterprise> _dummyEnterprises = {};
Future<void> _updateEnterprises(Map<String, dynamic> data) async {
  if (data.containsKey("id")) {
    // Update a single enterprise
    final id = data["id"];
    final enterpriseData = data;
    _dummyEnterprises[id] = _dummyEnterprises.containsKey(id)
        ? _dummyEnterprises[id]!.copyWithData(enterpriseData)
        : Enterprise.fromSerialized(enterpriseData);
  } else {
    // Update all enterprises
    _dummyEnterprises.clear();
    for (final entry in data.entries) {
      final id = entry.key;
      final enterpriseData = entry.value;
      _dummyEnterprises[id] = _dummyEnterprises.containsKey(id)
          ? _dummyEnterprises[id]!.copyWithData(enterpriseData)
          : Enterprise.fromSerialized(enterpriseData);
    }
  }
}

void main() {
  runApp(const MyApp());
}

class Token {
  final String? accessToken;
  final String? idToken;

  Token({required this.accessToken, required this.idToken});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController();
  WebSocket? _socket;
  bool _handshakeReceived = false;
  bool get isConnecting => _socket != null && !_handshakeReceived;
  bool get isConnected => _socket != null && _handshakeReceived;

  @override
  build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
                onPressed: isConnecting || isConnected ? null : _connect,
                child: Text(isConnecting ? 'Connecting...' : 'Connect')),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: isConnected ? _addRandomTeacher : null,
                child: Text('Add random teacher')),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: isConnected ? _getTeachers : null,
                child: Text('Get teachers')),
            SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                    onPressed: isConnected && _controller.text.isNotEmpty
                        ? _changeTeacher
                        : null,
                    child: Text('Change teacher')),
                SizedBox(width: 20),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _controller,
                    enabled: isConnected,
                    decoration: InputDecoration(
                      labelText: 'New first name',
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                )
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: isConnected ? _addRandomEnterprise : null,
                child: Text('Add random Enterprise')),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: isConnected ? _getEnterprises : null,
                child: Text('Get enterprises')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isConnected ? _closeConnexion : null,
              child: Text('Disconnect'),
            ),
            ..._dummyTeachers.entries.map((entry) {
              final teacher = entry.value;
              return TeacherTile(teacher: teacher);
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _connect() async {
    if (isConnected) return;

    // Get the JWT token
    String token = _getJwtToken();

    // Send a get request to the server
    try {
      _socket = WebSocket(
        Uri.parse('ws://localhost:3456/connect'),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        timeout: const Duration(seconds: 5),
      );
      setState(() {});
      _socket!.connection.listen((event) {
        if (event is Connected || event is Reconnected) {
          _socket!.send(jsonEncode(CommunicationProtocol(
              requestType: RequestType.handshake,
              data: {'token': token}).serialize()));
        } else if (event is Disconnected) {
          debugPrint('Disconnected from server');
          _handshakeReceived = false;
          setState(() {});
        }
      });
      _socket!.messages.listen(_incommingMessage);

      final started = DateTime.now();
      while (!_handshakeReceived) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (DateTime.now().isAfter(started.add(const Duration(seconds: 5)))) {
          throw Exception('Handshake timeout');
        }
      }
    } catch (e) {
      _socket = null;
      debugPrint('Error: $e');
    }
    setState(() {});
  }

  Future<void> _incommingMessage(message) async {
    try {
      final map = jsonDecode(message);
      final protocol = CommunicationProtocol.deserialize(map);
      switch (protocol.requestType) {
        case RequestType.handshake:
          {
            _handshakeReceived = true;
            setState(() {});
            debugPrint('Handshake received');
            return;
          }
        case RequestType.response:
        case RequestType.update:
          {
            debugPrint('Message received: $message');
            if (protocol.requestType == RequestType.response &&
                protocol.data == null) {
              return;
            }
            switch (protocol.field) {
              case RequestFields.teachers:
              case RequestFields.teacher:
                if (protocol.data == null) throw Exception('No data received');
                _updateTeachers(protocol.data!);
                setState(() {});
                break;
              case RequestFields.enterprises:
              case RequestFields.enterprise:
                if (protocol.data == null) throw Exception('No data received');
                _updateEnterprises(protocol.data!);
                setState(() {});
                break;
              case null:
                throw Exception('Unsupported request field: ${protocol.field}');
            }
            return;
          }
        case RequestType.get:
        case RequestType.post:
        case RequestType.delete:
          throw Exception('Unsupported request type: ${protocol.requestType}');
      }
    } catch (e) {
      debugPrint('Error: $e');
      return;
    }
  }

  Future<void> _addRandomTeacher() async {
    if (!isConnected) return;

    // Send a post request to the server
    try {
      final random = Random();
      final firstName =
          ['John', 'Jane', 'Alice', 'Bob', 'Charlie'][random.nextInt(5)];
      final lastName =
          ['Doe', 'Smith', 'Johnson', 'Williams', 'Brown'][random.nextInt(5)];
      final phone = PhoneNumber.fromString(
          '${random.nextInt(900) + 100}-${random.nextInt(900) + 100}-${random.nextInt(9000) + 1000}');
      final groups = <String>[];
      for (int i = 0; i < random.nextInt(5); i++) {
        groups.add(random.nextInt(100).toString());
      }

      final message = jsonEncode(CommunicationProtocol(
        requestType: RequestType.post,
        field: RequestFields.teacher,
        data: Teacher(
          firstName: firstName,
          middleName: null,
          lastName: lastName,
          schoolId: random.nextInt(100).toString(),
          groups: groups,
          email:
              '${firstName.toLowerCase()}.${lastName.toLowerCase()}@banque_stage.org',
          phone: phone,
          address: Address.empty,
          dateBirth: null,
        ).serialize(),
      ).serialize());
      _socket?.send(message);
      debugPrint('Message sent: $message');
    } catch (e) {
      debugPrint('Error: $e');
      return;
    }
  }

  Future<void> _addRandomEnterprise() async {
    if (!isConnected) return;

    // Send a post request to the server
    try {
      final random = Random();
      final name = ['The', 'Best', 'The', 'Great', 'The'][random.nextInt(5)] +
          [
            'Company',
            'Enterprise',
            'Business',
            'Corporation',
            'Firm'
          ][random.nextInt(5)];

      final message = jsonEncode(CommunicationProtocol(
        requestType: RequestType.post,
        field: RequestFields.enterprise,
        data: Enterprise(
          name: name,
        ).serialize(),
      ).serialize());
      _socket?.send(message);
      debugPrint('Message sent: $message');
    } catch (e) {
      debugPrint('Error: $e');
      return;
    }
  }

  Future<void> _getTeachers() async {
    if (!isConnected) return;

    // Send a get request to the server
    try {
      final message = jsonEncode(CommunicationProtocol(
        requestType: RequestType.get,
        field: RequestFields.teachers,
      ).serialize());
      _socket?.send(message);
      debugPrint('Message sent: $message');
    } catch (e) {
      debugPrint('Error: $e');
      return;
    }
  }

  Future<void> _getEnterprises() async {
    if (!isConnected) return;

    // Send a get request to the server
    try {
      final message = jsonEncode(CommunicationProtocol(
        requestType: RequestType.get,
        field: RequestFields.enterprises,
      ).serialize());
      _socket?.send(message);
      debugPrint('Message sent: $message');
    } catch (e) {
      debugPrint('Error: $e');
      return;
    }
  }

  Future<void> _changeTeacher() async {
    if (!isConnected || _controller.text.isEmpty) return;

    // Send a post request to the server
    try {
      // TODO: This if we can get the error message
      final message = jsonEncode(CommunicationProtocol(
        requestType: RequestType.post,
        field: RequestFields.teacher,
        data: {'id': _dummyTeachers.keys.first, 'firstName': _controller.text},
      ).serialize());
      _socket?.send(message);
      debugPrint('Message sent: $message');
    } catch (e) {
      debugPrint('Error: $e');
      return;
    }
  }

  Future<void> _closeConnexion() async {
    if (!isConnected) return;

    // Close the WebSocket connection
    try {
      _socket?.close();
      _socket = null;
      _handshakeReceived = false;
      debugPrint('Connection closed');
    } catch (e) {
      debugPrint('Error: $e');
      return;
    }
    setState(() {});
  }
}

class TeacherTile extends StatelessWidget {
  const TeacherTile({
    super.key,
    required this.teacher,
  });

  final Teacher teacher;

  @override
  Widget build(BuildContext context) {
    return Text('${teacher.toString()} '
        '(${teacher.phone}) '
        '[${teacher.groups.join(', ')}]');
  }
}

String _getJwtToken() {
  // Create a fake JWT signed token to simulate a login.
  // TODO: At some point, this should be replaced with a real JWT token.
  return JWT({'app_secret': '1234567890'}).sign(SecretKey('secret passphrase'));
}
