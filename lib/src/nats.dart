import 'dart:async';
import 'dart:convert';
import 'wire.dart';

class Message {
  final String subject;
  final String replyTo;
  final Iterable<int> data;
  final Subscription subscription;

  Message(this.subject, this.replyTo, this.data, this.subscription);

  String get dataAsString => utf8.decode(data);

  String toString() => '$subject $dataAsString';
}

class Subscription {
  final String subscriptionId;

  final String subject;

  final String queueGroup;

  final _controller = StreamController<Message>();

  final Nats _connection;

  Stream<Message> _onMessage;
  Stream<Message> get onMessage => _onMessage;

  Subscription._(
      this._connection, this.subscriptionId, this.subject, this.queueGroup) {
    _onMessage = _controller.stream.asBroadcastStream();
  }

  // TODO automatic unsubscribe

  /// Stop listening to the subject
  Future<void> unsubscribe() async {
    await _controller.close();
    await _connection._unsubscribe(this);
  }

  /// Indicates whether the subscription is still active. This will return false
  /// if the subscription has already been closed.
  bool get isValid => _controller.isClosed;
}

/// A connection to a NATS server.
///
/// Use [publish] method to publish messages to NATS server.
/// Use [subscribe] method to subscribe to messages.
abstract class Nats {
  Future<void> publish(
      String subject, /* String | Iterable<int> | dynamic */ data,
      {String replyTo});

  /// Subs
  Future<Subscription> subscribe(String subject, {String queueGroup});

  static Future<Nats> connect(
      {String host: 'localhost',
      int port: 4222,
      ConnectionOptions options: const ConnectionOptions()}) async {
    Comm comm = await Comm.connect(host: host, port: port, options: options);
    return NatsImpl(comm);
  }

  Future<void> _unsubscribe(Subscription subscription);
}

class NatsImpl implements Nats {
  final Comm _comm;

  NatsImpl(this._comm) {
    _comm.onMessage.listen(_processReceived);
  }

  ConnectionOptions get options => _comm.connectionOptions;

  ConnectionInfo get info => _comm.connectionInfo;

  Future<void> publish(
          String subject, /* String | Iterable<int> | dynamic */ data,
          {String replyTo}) =>
      _comm.sendPub(subject, data, replyTo: replyTo);

  /// Subs
  Future<Subscription> subscribe(String subject, {String queueGroup}) async {
    String subscriptionId =
        await _comm.sendSub(subject, queueGroup: queueGroup);
    final sub = Subscription._(this, subscriptionId, subject, queueGroup);
    _subscriptions[subscriptionId] = sub;
    return sub;
  }

  Future<void> close() async {
    try {
      await _comm.close();
    } catch(e) {}

    // TODO close all subscriptions
  }

  final _subscriptions = <String, Subscription>{};

  Future<void> _unsubscribe(Subscription subscription) async {
    if (subscription._connection != this)
      throw Exception("Subscription doesn't belong to this connection!");
    Subscription sub = _subscriptions.remove(subscription.subscriptionId);
    if (sub == null) return;
    await _comm.sendUnsub(subscription.subscriptionId);
  }

  void _processReceived(WireMsg msg) {
    String subscriptionId = msg.sid;
    Subscription sub = _subscriptions[subscriptionId];
    if (sub == null) return;
    sub._controller.add(Message(msg.subject, msg.replyTo, msg.payload, sub));
  }
}
