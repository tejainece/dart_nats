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
      {ConnectionOptions options: const ConnectionOptions()}) async {
    var ret = NatsImpl(options);
    await ret._waitForConnection();
    return ret;
  }

  Future<void> _unsubscribe(Subscription subscription);
}

class NatsImpl implements Nats {
  Comm _comm;
  BigInt _idGen = BigInt.one;
  Future _connectionWaiter;

  NatsImpl(this.options) {
    _onDisconnect();
  }

  final ConnectionOptions options;

  ConnectionInfo _info;

  ConnectionInfo get info => _info;

  Future<void> _waitForConnection() async {
    while (_connectionWaiter != null) {
      await _connectionWaiter;
    }
  }

  Future<void> publish(
      String subject, /* String | Iterable<int> | dynamic */ data,
      {String replyTo}) async {
    await _waitForConnection();
    _comm.sendPub(subject, data, replyTo: replyTo);
  }

  /// Subs
  Future<Subscription> subscribe(String subject, {String queueGroup}) async {
    await _waitForConnection();
    String subscriptionId = _newSubscriptionId();
    _comm.sendSub(subscriptionId, subject, queueGroup: queueGroup);
    final sub = Subscription._(this, subscriptionId, subject, queueGroup);
    _subscriptions[subscriptionId] = sub;
    return sub;
  }

  Future<void> close() async {
    try {
      await _comm.close();
    } catch (e) {}
  }

  String _newSubscriptionId() {
    String ret = _idGen.toString();
    _idGen = _idGen + BigInt.one;
    return ret;
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

  Future<void> _reconnect(String host, int port) async {
    print("Trying to reconnect to $host:$port ...");
    Comm comm;
    try {
      comm = await Comm.connect(host: host, port: port);
    } catch (e) {
      return;
    }
    ConnectionInfo info;
    try {
      info = await comm.onInfo.first.timeout(Duration(seconds: 5));
      comm.sendConnect(json.encode(options.toJson()));
    } catch (e) {
      await comm.close();
      return;
    }
    _comm = comm;
    _info = info;
  }

  void _onConnect() {
    _comm.onDisconnect = _onDisconnect;
    for (Subscription sub in _subscriptions.values) {
      if (_comm == null) break;
      _comm.sendSub(sub.subscriptionId, sub.subject,
          queueGroup: sub.queueGroup);
    }
    _comm.onMessage.listen(_processReceived); // TODO subscribe
  }

  Future<void> _onDisconnect() async {
    var completer = Completer();
    _connectionWaiter = completer.future;
    print("Disconnected! Reconnecting ... ");
    Iterable<String> urls;

    if (_info != null) {
      urls = _info.connectUrls;
      _info = null;
    } else {
      urls = [];
    }

    _comm = null;

    await _reconnect(options.host, options.port);

    if (_comm != null) {
      await _onConnect();
      completer.complete();
      _connectionWaiter = null;
      return;
    }

    for (String connStr in urls) {
      Iterable<String> parts = connStr.split(':');
      await _reconnect(parts.first, int.tryParse(parts.last));
      if (_comm != null) {
        await _onConnect();
        completer.complete();
        _connectionWaiter = null;
        return;
      }
    }

    throw Exception("NATS_Dart: No server to connect!");
  }
}
