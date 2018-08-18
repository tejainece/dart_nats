import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'handlers.dart';

import 'package:nats_dart/info/info.dart';

export 'handlers.dart' show WireMsg;

export 'package:nats_dart/info/info.dart';
export 'package:nats_dart/info/options.dart';

class Comm {
  final Socket _socket;
  final _buffer = List<int>(); // TODO replace with circular buffer
  StreamSubscription _socketListener;

  final _infoEmitter = StreamController<ConnectionInfo>();
  Stream<ConnectionInfo> _onInfo;
  Stream<ConnectionInfo> get onInfo => _onInfo;

  final _msgEmitter = StreamController<WireMsg>();
  Stream<WireMsg> _onMessage;
  Stream<WireMsg> get onMessage => _onMessage;

  Function onDisconnect;

  Comm._(this._socket, {this.onDisconnect}) {
    _onMessage = _msgEmitter.stream.asBroadcastStream();
    _onInfo = _infoEmitter.stream.asBroadcastStream();
    _socketListener =
        _socket.listen(_handleRx, cancelOnError: true, onDone: _disconnected);
  }

  Future<void> _disconnected() async {
    if (_socketListener != null) {
      await _socketListener.cancel();
      _socketListener = null;
    }
    if (onDisconnect != null) onDisconnect();
  }

  static Future<Comm> connect(
      {String host: 'localhost', int port: 4222}) async {
    Socket socket =
        await Socket.connect(host, port, timeout: Duration(seconds: 5));
    socket.encoding = utf8;
    final ret = Comm._(socket);
    return ret;
  }

  Future<void> close() async {
    try {
      await _socket.close();
    } catch (e) {}
    if (_socketListener != null) {
      try {
        await _socketListener.cancel();
      } catch (e) {}
    }
    _socketListener = null;
  }

  bool _trySend(Function func) {
    if (_socketListener == null) return false;
    try {
      func();
    } catch (e) {
      return false;
    }
    return true;
  }

  bool sendConnect(String options) {
    return _trySend(() {
      _socket.write('CONNECT ');
      _socket.write(options);
      _socket.write('\r\n');
    });
  }

  bool sendPub(String subject, /* String | Iterable<int> | dynamic */ payload,
      {String replyTo}) {
    return _trySend(() {
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
    });
  }

  /// Sends a 'SUB' subscription message and returns the subscription id
  bool sendSub(String subscriptionId, String subject, {String queueGroup}) {
    return _trySend(() {
      _socket.write('SUB $subject ');
      if (queueGroup != null) _socket.write('$queueGroup ');
      _socket.write(subscriptionId);
      _socket.write('\r\n');
    });
  }

  bool sendUnsub(String subscriptionId, {int maxMsgs}) {
    return _trySend(() {
      _socket.write('UNSUB $subscriptionId');
      if (maxMsgs != null) _socket.write(' $maxMsgs');
      _socket.write('\r\n');
    });
  }

  bool _sendPong() {
    return _trySend(() {
      _socket.write('PONG');
      _socket.write('\r\n');
    });
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
            _infoEmitter.add(ConnectionInfo.fromMap(json.decode(payload)));
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
