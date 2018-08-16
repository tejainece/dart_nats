import 'dart:io';
import 'dart:async';
import 'dart:convert';

class Comm {
  Socket _socket;
  List<int> _buffer = List<int>();

  Comm() {
    _socket.listen(_handleRx);
  }

  void sendConnect() {
    // TODO
  }

  void sendPub(String subject, List<int> bytes, {String replyTo}) {
    // TODO
  }

  void sendSub(String subject, {String queueGroup}) {
    // TODO
  }

  void sendUnsub(String subject, {String queueGroup}) {
    // TODO
  }

  Handler _handler;

  void _handleRx(List<int> data) {
    _buffer.addAll(data);
    if(_handler == null) {
      CmdType packetType = _findPacket(_buffer);
      if (packetType != null) {
        switch (packetType) {
          case CmdType.info:
            _handler = InfoHandler();
            break;
            // TODO
        }
        // TODO handle packet
      }
    }
    if(_handler.handle(data)) {
      // TODO process response
      _handler = null;
    }
  }


}

CmdType _findPacket(Iterable<int> buffer) {
  final int length = buffer.length;
  if(length >= 5) {
    String cmd = String.fromCharCodes(buffer.take(5)).toUpperCase();
    if(cmd == 'INFO ') {
      return CmdType.unsub;
    } else if(cmd == '-ERR ') {
      return CmdType.err;
    }
  } else if(length >= 4) {
    String cmd = String.fromCharCodes(buffer.take(4)).toUpperCase();
    if(cmd == 'PING') {
      return CmdType.ping;
    } else if(cmd == 'MSG ') {
      return CmdType.msg;
    }
  } else if(length >= 3) {
    String cmd = String.fromCharCodes(buffer.take(3)).toUpperCase();
    if(cmd == '+OK') {
      return CmdType.ok;
    }
  }
  return null;
}

abstract class Handler {
  bool handle(List<int> data);
}

class InfoHandler implements Handler {


  @override
  bool handle(List<int> data) {

  }
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