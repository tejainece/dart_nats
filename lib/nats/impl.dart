part of 'nats.dart';

class NatsImpl implements Nats {
  Comm _comm;
  BigInt _idGen = BigInt.one;
  Future _connectionWaiter;

  NatsImpl(this.options) {
    _reconnect();
  }

  final ConnectionOptions options;

  ConnectionInfo _info;

  ConnectionInfo get info => _info;

  final _subscriptions = <String, Subscription>{};

  Future<void> _waitForConnection() async {
    while (_connectionWaiter != null) {
      await _connectionWaiter;
    }
  }

  Future<void> publish(
      String subject, /* String | Iterable<int> | dynamic */ data,
      {String replyTo}) async {
    await _waitForConnection();
    if(_comm == null) throw Exception("Connection is closed!");
    _comm.sendPub(subject, data, replyTo: replyTo);
  }

  /// Subs
  Future<Subscription> subscribe(String subject, {String queueGroup}) async {
    await _waitForConnection();
    if(_comm == null) throw Exception("Connection is closed!");
    String subscriptionId = _newSubscriptionId();
    _comm.sendSub(subscriptionId, subject, queueGroup: queueGroup);
    final sub = Subscription._(this, subscriptionId, subject, queueGroup);
    _subscriptions[subscriptionId] = sub;
    return sub;
  }

  Future<void> unsubscribe(Subscription subscription) async {
    if (subscription._connection != this)
      throw Exception("Subscription doesn't belong to this connection!");
    if(_comm == null) throw Exception("Connection is closed!");
    Subscription sub = _subscriptions.remove(subscription.subscriptionId);
    if (sub == null) return;
    await _comm.sendUnsub(subscription.subscriptionId);
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

  void _processReceived(WireMsg msg) {
    String subscriptionId = msg.sid;
    Subscription sub = _subscriptions[subscriptionId];
    if (sub == null) return;
    sub._controller.add(Message(msg.subject, msg.replyTo, msg.payload, sub));
  }

  Future<void> _tryToConnect(String host, int port) async {
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
    _comm.onDisconnect = _reconnect;
    for (Subscription sub in _subscriptions.values) {
      if (_comm == null) break;
      _comm.sendSub(sub.subscriptionId, sub.subject,
          queueGroup: sub.queueGroup);
    }
    _comm.onMessage.listen(_processReceived); // TODO subscribe
  }

  Future<void> _reconnect() async {
    var completer = Completer();
    _connectionWaiter = completer.future;

    Iterable<String> urls;

    if (_info != null) {
      urls = _info.connectUrls;
      _info = null;
    } else {
      urls = [];
    }

    _comm = null;

    await _tryToConnect(options.host, options.port);

    if (_comm != null) {
      await _onConnect();
      completer.complete();
      _connectionWaiter = null;
      return;
    }

    for (String connStr in urls) {
      Iterable<String> parts = connStr.split(':');
      await _tryToConnect(parts.first, int.tryParse(parts.last));
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