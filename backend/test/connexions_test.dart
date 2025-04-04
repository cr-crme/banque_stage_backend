import 'dart:convert';

import 'package:backend/connexions.dart';
import 'package:common/communication_protocol.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:test/test.dart';

import 'web_socket_mock.dart';

String _prepareHandshake() {
  return jsonEncode(
      CommunicationProtocol(requestType: RequestType.handshake, data: {
    'token':
        JWT({'app_secret': '1234567890'}).sign(SecretKey('secret passphrase'))
  }).serialize());
}

void main() {
  test('Add new client with handshake timeout', () async {
    final connexions = Connexions(timeout: Duration(milliseconds: 200));
    final client = WebSocketMock();
    final isConnectedFuture = connexions.add(client);

    // Simulate a timeout
    expect(await isConnectedFuture, false);
    expect(client.isConnected, false);
  });

  test('Add new client missing handshake', () async {
    final connexions = Connexions(timeout: Duration(milliseconds: 200));
    final client = WebSocketMock();
    final isConnectedFuture = connexions.add(client);

    // Simulate a missing handshake
    client.streamController.add('');
    expect(await isConnectedFuture, false);
    expect(client.isConnected, false);
  });

  test('Add new client with invalid handshake', () async {
    final connexions = Connexions();
    final client = WebSocketMock();
    final isConnectedFuture = connexions.add(client);

    // Simulate an invalid handshake
    client.streamController.add(jsonEncode(
        CommunicationProtocol(requestType: RequestType.handshake).serialize()));
    expect(await isConnectedFuture, false);
    expect(client.isConnected, false);
  });

  test('Add new client with invalid token', () async {
    final connexions = Connexions();
    final client = WebSocketMock();
    final isConnectedFuture = connexions.add(client);

    // Simulate an invalid token
    client.streamController.add(jsonEncode(
        CommunicationProtocol(requestType: RequestType.handshake, data: {
      'token': JWT({'app_secret': 'invalid'}).sign(SecretKey('invalid'))
    }).serialize()));
    expect(await isConnectedFuture, false);
    expect(client.isConnected, false);
  });

  test('Add a new client to Connexions and disconnect', () async {
    final connexions = Connexions();
    final client = WebSocketMock();

    // Listen to incoming messages from connexions
    client.incommingStreamController.stream.listen((message) {
      final protocol = CommunicationProtocol.deserialize(jsonDecode(message));
      expect(protocol.requestType, RequestType.handshake);
    });
    final isConnectedFuture = connexions.add(client);

    // Send the handshake message
    client.streamController.add(_prepareHandshake());
    expect(await isConnectedFuture, true);
    expect(client.isConnected, true);
    expect(connexions.clientCount, 1);

    // Simulate a client disconnect
    await client.close();
    await Future.delayed(Duration(milliseconds: 100));
    expect(connexions.clientCount, 0);
  });

  test('Add a new client to Connexions and experience error', () async {
    final connexions = Connexions();
    final client = WebSocketMock();
    connexions.add(client);

    // Send the handshake message
    client.streamController.add(_prepareHandshake());
    expect(connexions.clientCount, 1);

    // Simulate an error
    client.streamController.addError('Simulated error');
    await Future.delayed(Duration(milliseconds: 100));
    expect(connexions.clientCount, 0);
  });

  test('Send a GET teachers request', () async {
    final connexions = Connexions();
    final client = WebSocketMock();
    connexions.add(client);
    client.streamController.add(_prepareHandshake());

    // Listen to incoming messages from connexions
    client.incommingStreamController.stream.listen((message) {
      final protocol = CommunicationProtocol.deserialize(jsonDecode(message));
      expect(protocol.requestType, RequestType.response);
      expect(protocol.field, RequestFields.teachers);
      expect(protocol.data, isA<Map<String, dynamic>>());
      expect(protocol.data!['0'], isA<Map<String, dynamic>>());
      expect(protocol.data!['0']['name'], isA<String>());
      expect(protocol.data!['0']['name'], 'John Doe');
      expect(protocol.data!['0']['age'], isA<int>());
      expect(protocol.data!['0']['age'], 60);
      expect(protocol.data!['1'], isA<Map<String, dynamic>>());
      expect(protocol.data!['1']['name'], isA<String>());
      expect(protocol.data!['1']['name'], 'Jane Doe');
      expect(protocol.data!['1']['age'], isA<int>());
      expect(protocol.data!['1']['age'], 50);
      expect(protocol.response, Response.success);
    });

    // Simulate a GET request
    client.streamController.add(
      jsonEncode(CommunicationProtocol(
              requestType: RequestType.get, field: RequestFields.teachers)
          .serialize()),
    );
  });

  test('Send a POST teacher request and receive the update', () async {
    final connexions = Connexions();
    final client1 = WebSocketMock();
    connexions.add(client1);
    client1.streamController.add(_prepareHandshake());
    final client2 = WebSocketMock();
    connexions.add(client2);
    client2.streamController.add(_prepareHandshake());

    int updateCount = 0;

    // Listen to incoming messages from connexions
    client1.incommingStreamController.stream.listen((message) {
      final protocol = CommunicationProtocol.deserialize(jsonDecode(message));
      if (protocol.requestType != RequestType.update) return;
      expect(protocol.requestType, RequestType.update);
      expect(protocol.field, RequestFields.teacher);
      expect(protocol.data, isA<Map<String, dynamic>>());
      expect(protocol.data!['name'], 'John Smith');
      expect(protocol.data!['age'], 45);
      expect(protocol.response, isNull);
      updateCount++;
    });
    client2.incommingStreamController.stream.listen((message) {
      final protocol = CommunicationProtocol.deserialize(jsonDecode(message));
      if (protocol.requestType != RequestType.update) return;
      expect(protocol.requestType, RequestType.update);
      expect(protocol.field, RequestFields.teacher);
      expect(protocol.data, isA<Map<String, dynamic>>());
      expect(protocol.data!['name'], 'John Smith');
      expect(protocol.data!['age'], 45);
      expect(protocol.response, isNull);
      updateCount++;
    });

    // Simulate a POST request
    client1.streamController.add(
      jsonEncode(CommunicationProtocol(
          requestType: RequestType.post,
          field: RequestFields.teacher,
          data: {'id': '1', 'name': 'John Smith', 'age': 45}).serialize()),
    );

    // Wait for the update to be sent to both clients
    await Future.delayed(Duration(milliseconds: 200));
    expect(updateCount, 2);
    expect(connexions.clientCount, 2);
  });

  test('Send an ill-formed message', () async {
    final connexions = Connexions();
    final client = WebSocketMock();
    connexions.add(client);
    client.streamController.add(_prepareHandshake());

    // Listen to incoming messages from connexions
    client.incommingStreamController.stream.listen((message) {
      final protocol = CommunicationProtocol.deserialize(jsonDecode(message));
      expect(protocol.requestType, RequestType.response);
      expect(protocol.field, isNull);
      expect(protocol.data, isA<Map<String, dynamic>>());
      expect(protocol.response, Response.failure);
    });

    // Simulate an ill-formed message
    client.streamController.add('An ill-formed message');
  });
}
