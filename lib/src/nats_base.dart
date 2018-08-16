import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

class Subscription {
  final String subject;

  StreamController<Message> _controller;

  Stream<Message> get onMessage => _controller.stream.asBroadcastStream();
  // TODO

  Subscription(this.subject);

  // TODO automatic unsubscribe

  /// Stop listening to the subject
  Future<void> unsubscribe() async {
    await _controller.close();
    // TODO
  }

  /// Indicates whether the subscription is still active. This will return false
  /// if the subscription has already been closed.
  bool get isValid => _controller.isClosed;
}

class Message {
  final String subject;
  final String reply;
  final Uint8List data;
  final Subscription subscription;

  Message();
}

/// A connection to a NATS server.
///
/// Use [publish] method to publish messages to NATS server.
/// Use [subscribe] method to subscribe to messages.
abstract class Nats {
  Future<void> publish(String subject, Uint8List data);

  /// Subs
  Future<Subscription> subscribe(String subject);

  static Future<Nats> connect(String url) async {
    // TODO
  }
}

class NatsImpl implements Nats {
  Future<void> publish(String subject, Uint8List data) async {
    // TODO
  }

  /// Subs
  Future<Subscription> subscribe(String subject) async {
    // TODO
  }
}

class Comm {
  Socket _socket;

  Future<void> send(String message) async {
    // TODO
  }

  StreamController<Message> _messages;

  Stream<Message> get onMessage => _messages.stream.asBroadcastStream();
}
