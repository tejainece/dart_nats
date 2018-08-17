const int _lf = 10;
const int _cr = 13;

abstract class Handler {
  bool handle(List<int> data);
}

class InfoHandler implements Handler {
  int _state = 0;

  int get state => _state;

  String _info;

  String get info => _info;

  int _readPos = 0;

  bool _prevCarRet = false;

  @override
  bool handle(List<int> data) {
    final int dLen = data.length - 1;
    switch (_state) {
      case 0:
        data.removeRange(0, 5);
        _state = 1;
        continue case1;
      case1:
      case 1:
        for (; _readPos <= dLen; _readPos++) {
          int ch = data[_readPos];
          if (_prevCarRet) {
            if (ch == _lf) {
              _info = String.fromCharCodes(data.take(_readPos - 1));
              data.removeRange(0, _readPos + 1);
              _state = 2;
              return true;
            }
          }
          _prevCarRet = ch == _cr;
        }
        break;
      default:
        throw Exception("Finished reading the message!");
    }
    return false;
  }
}

class PingHandler implements Handler {
  int _state = 0;
  @override
  bool handle(List<int> data) {
    if (_state == 1) throw Exception("Finished reading the message!");

    if (_state == 0) {
      if (data.length < 6) return false;
      String cmd = String.fromCharCodes(data.take(6)).toUpperCase();
      if (cmd != "PING\r\n")
        throw ProtocolError("Invalid 'PING' command received!");
      data.removeRange(0, 6);
      _state = 1;
      return true;
    }

    return false;
  }
}

class OkHandler implements Handler {
  int _state = 0;
  @override
  bool handle(List<int> data) {
    if (_state == 1) throw Exception("Finished reading the message!");

    if (_state == 0) {
      if (data.length < 5) return false;
      String cmd = String.fromCharCodes(data.take(5)).toUpperCase();
      if (cmd != "+OK\r\n")
        throw ProtocolError("Invalid 'OK' command received!");
      data.removeRange(0, 5);
      _state = 1;
      return true;
    }

    return false;
  }
}

class MsgHandler implements Handler, WireMsg {
  int _state = 0;

  int _readPos = 0;

  bool _prevCarRet = false;

  String _subject;
  String _sid;
  String _replyTo;
  Iterable<int> _payload;
  int _payloadLength;

  String get subject => _subject;
  String get sid => _sid;
  String get replyTo => _replyTo;
  Iterable<int> get payload => _payload;

  @override
  bool handle(List<int> data) {
    final int dLen = data.length - 1;
    switch (_state) {
      case 0:
        data.removeRange(0, 4);
        _state = 1;
        continue case1;
      case1:
      case 1:
        for (; _readPos <= dLen; _readPos++) {
          int ch = data[_readPos];
          if (_prevCarRet) {
            if (ch == _lf) {
              String info = String.fromCharCodes(data.take(_readPos - 1));
              List<String> parts = info.split(' ');
              if (parts.length < 3 || parts.length > 4) {
                throw ProtocolError("Invalid MSG command received!");
              }
              _subject = parts[0];
              _sid = parts[1];
              if (parts.length == 3) {
                _payloadLength = int.tryParse(parts[2]);
              } else {
                _replyTo = parts[2];
                _payloadLength = int.tryParse(parts[3]);
              }
              if (_payloadLength == null)
                ProtocolError("Invalid MSG command received!");
              data.removeRange(0, _readPos + 1);
              _state = 2;
              continue case2;
            }
          }
          _prevCarRet = ch == _cr;
        }
        break;
      case2:
      case 2:
        if (data.length < (_payloadLength + 2)) break;
        if (data[_payloadLength] != _cr || data[_payloadLength + 1] != _lf)
          ProtocolError("Invalid MSG command received!");
        _payload = data.take(_payloadLength).toList();
        data.removeRange(0, _payloadLength + 2);
        _state = 3;
        return true;
        break;
      default:
        throw Exception("Finished reading the message!");
    }
    return false;
  }
}

class ProtocolError implements Exception {
  final String message;

  const ProtocolError(this.message);

  String toString() => "NATS protocol error: $message";
}

abstract class WireMsg {
  String get sid;
  String get subject;
  String get replyTo;
  Iterable<int> get payload;
}