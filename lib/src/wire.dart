import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'handlers.dart';

export 'handlers.dart' show WireMsg;

class ConnectionOptions {
  final bool verbose;

  final bool pedantic;

  final bool sslRequired;

  final String authToken;

  final String user;

  final String pass;

  final String name;

  final String lang;

  final String version;

  final int protocol;

  final bool echo;

  const ConnectionOptions(
      {this.verbose: false,
      this.pedantic: false,
      this.sslRequired: false,
      this.authToken,
      this.user,
      this.pass,
      this.name,
      this.lang: 'Dart',
      this.version: "2.0.0",
      this.protocol: 1,
      this.echo: false});

  bool get hasAuth => authToken != null || (user != null && pass != null);

  Map<String, dynamic> toJson() {
    final ret = <String, dynamic>{};

    if (!verbose) ret['verbose'] = false;
    if (!pedantic) ret['pedantic'] = false;
    if (!pedantic) ret['pedantic'] = false;
    ret['ssl_required'] = sslRequired;
    if (authToken != null) ret['auth_token'] = authToken;
    if (user != null) ret['user'] = user;
    if (pass != null) ret['pass'] = pass;
    if (name != null) ret['name'] = name;
    if (lang != null) ret['lang'] = lang;
    if (version != null) ret['version'] = version;
    if (protocol != null) ret['protocol'] = protocol;
    if (echo != null) ret['echo'] = echo;

    return ret;
  }
}

class ConnectionInfo {
  /// The unique identifier of the NATS server
  String _serverId;

  /// The version of the NATS server
  String _version;

  /// The version of golang the NATS server was built with
  String _go;

  /// The IP address of the NATS server host
  String _host;

  /// The port number the NATS server is configured to listen on
  int _port;

  /// If this is set, then the client should try to authenticate upon connect.
  bool _authRequired;

  /// If this is set, then the client must authenticate using SSL.
  bool _sslRequired;

  /// Maximum payload size that the server will accept from the client.
  int _maxPayload;

  /// An optional list of server urls that a client can connect to.
  List<String> _connectUrls;

  /// An integer indicating the protocol version of the server. The server
  /// version 1.2.0 sets this to 1 to indicate that it supports the “Echo” feature.
  int _proto;

  /// An optional unsigned integer (64 bits) representing the internal client
  /// identifier in the server. This can be used to filter client connections in
  /// monitoring, correlate with error logs, etc…
  int _clientId;

  /// The unique identifier of the NATS server
  String get serverId => _serverId;

  /// The version of the NATS server
  String get version => _version;

  /// The version of golang the NATS server was built with
  String get go => _go;

  /// The IP address of the NATS server host
  String get host => _host;

  /// The port number the NATS server is configured to listen on
  int get port => _port;

  /// If this is set, then the client should try to authenticate upon connect.
  bool get authRequired => _authRequired;

  /// If this is set, then the client must authenticate using SSL.
  bool get sslRequired => _sslRequired;

  /// Maximum payload size that the server will accept from the client.
  int get maxPayload => _maxPayload;

  /// An optional list of server urls that a client can connect to.
  Iterable<String> get connectUrls => _connectUrls;

  /// An integer indicating the protocol version of the server. The server
  /// version 1.2.0 sets this to 1 to indicate that it supports the “Echo” feature.
  int get proto => _proto;

  /// An optional unsigned integer (64 bits) representing the internal client
  /// identifier in the server. This can be used to filter client connections in
  /// monitoring, correlate with error logs, etc…
  int get clientId => _clientId;

  void fromMap(Map<String, dynamic> map) {
    _serverId = map['server_id'];
    _version = map['version'];
    _go = map['go'];
    _host = map['host'];
    _port = map['port'];
    _authRequired = map['auth_required'];
    _sslRequired = map['ssl_required'];
    _maxPayload = map['max_payload'];
    _connectUrls = map['connect_urls'];
    _proto = map['proto'];
    _clientId = map['client_id'];
  }
}

class Comm {
  Socket _socket;
  final _buffer = List<int>(); // TODO replace with circular buffer
  StreamSubscription _socketListener;
  BigInt _idGen = BigInt.one;
  final ConnectionOptions connectionOptions;
  final _connected = Completer<Comm>();
  Future get whenConnected => _connected.future;
  final connectionInfo = ConnectionInfo();
  final _msgEmitter = StreamController<WireMsg>();
  Stream<WireMsg> _onMessage;
  Stream<WireMsg> get onMessage => _onMessage;

  Comm._(this._socket, this.connectionOptions) {
    _onMessage = _msgEmitter.stream.asBroadcastStream();
    _socketListener = _socket.listen(_handleRx);
  }

  static Future<Comm> connect(
      {String host: 'localhost',
      int port: 4222,
      ConnectionOptions options: const ConnectionOptions()}) async {
    final socket = await Socket.connect(host, port);
    socket.encoding = utf8;
    final ret = Comm._(socket, options);
    await ret.whenConnected;
    return ret;
  }

  Future<void> close() async {
    try {
      await _socket.close();
    } catch (e) {}
    try {
      await _socketListener.cancel();
    } catch (e) {}
    _socket = null;
    _socketListener = null;
  }

  Future<void> _sendConnect() async {
    String payload = json.encode(connectionOptions.toJson());
    _socket.write('CONNECT ');
    _socket.write(payload);
    _socket.write('\r\n');
    // await _socket.flush();
  }

  Future<void> sendPub(
      String subject, /* String | Iterable<int> | dynamic */ payload,
      {String replyTo}) async {
    Iterable<int> bytes;
    if (payload is String) {
      bytes = utf8.encode(payload);
    } else if (payload is Iterable<int>) {
      bytes = bytes;
    } else if (payload != null) {
      bytes = utf8.encode(payload.toString());
    } else {
      bytes = <int>[];
    }
    _socket.write('PUB $subject ');
    if (replyTo != null) _socket.write('$replyTo ');
    _socket.write(bytes.length);
    _socket.write('\r\n');
    _socket.add(bytes);
    _socket.write('\r\n');
    // await _socket.flush();
  }

  String _newSubscriptionId() {
    String ret = _idGen.toString();
    _idGen = _idGen + BigInt.one;
    return ret;
  }

  /// Sends a 'SUB' subscription message and returns the subscription id
  Future<String> sendSub(String subject, {String queueGroup}) async {
    _socket.write('SUB $subject ');
    if (queueGroup != null) _socket.write('$queueGroup ');
    final String subscriptionId = _newSubscriptionId();
    _socket.write(subscriptionId);
    _socket.write('\r\n');
    // await _socket.flush();
    return subscriptionId;
  }

  Future<void> sendUnsub(String subscriptionId, {int maxMsgs}) async {
    _socket.write('UNSUB $subscriptionId');
    if (maxMsgs != null) _socket.write(' $maxMsgs');
    _socket.write('\r\n');
    // await _socket.flush();
  }

  Future<void> _sendPong() async {
    _socket.write('PONG');
    _socket.write('\r\n');
    // await _socket.flush();
  }

  Handler _handler;

  Future<void> _handleRx(List<int> data) async {
    _buffer.addAll(data);
    while (true) {
      if (_handler == null) {
        CmdType packetType = _findPacket(_buffer);
        if (packetType != null) {
          switch (packetType) {
            case CmdType.info:
              _handler = InfoHandler();
              break;
            case CmdType.ping:
              _handler = PingHandler();
              break;
            case CmdType.msg:
              _handler = MsgHandler();
              break;
            case CmdType.ok:
              _handler = OkHandler();
              break;
            default:
              throw Exception(
                  "Received unknown NATS command: ${packetType.index}!");
              break;
          }
        } else {
          break;
        }
      } else {
        if (_handler.handle(_buffer)) {
          if (_handler is MsgHandler) {
            _msgEmitter.add(_handler as MsgHandler);
          } else if (_handler is PingHandler) {
            await _sendPong();
          } else if (_handler is InfoHandler) {
            String payload = (_handler as InfoHandler).info;
            connectionInfo.fromMap(json.decode(payload));
            if (!_connected.isCompleted) {
              await _sendConnect();
              _connected.complete(this);
            }
          }
          _handler = null;
        }
      }
    }
  }
}

CmdType _findPacket(Iterable<int> buffer) {
  final int length = buffer.length;
  if (length >= 3) {
    String cmd = String.fromCharCodes(buffer.take(3)).toUpperCase();
    if (cmd == '+OK') {
      return CmdType.ok;
    }
  }
  if (length >= 4) {
    String cmd = String.fromCharCodes(buffer.take(4)).toUpperCase();
    if (cmd == 'PING') {
      return CmdType.ping;
    } else if (cmd == 'MSG ') {
      return CmdType.msg;
    }
  }
  if (length >= 5) {
    String cmd = String.fromCharCodes(buffer.take(5)).toUpperCase();
    if (cmd == 'INFO ') {
      return CmdType.info;
    } else if (cmd == '-ERR ') {
      return CmdType.err;
    }
  }
  return null;
}

enum CmdType {
  info,
  connect,
  pub,
  sub,
  unsub,
  msg,
  ping,
  pong,
  ok,
  err,
}
