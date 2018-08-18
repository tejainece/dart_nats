part of 'wire.dart';

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
  List<String> _connectUrls = <String>[];

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
    _connectUrls = (map['connect_urls'] as List).cast<String>() ?? <String>[];
    _proto = map['proto'];
    _clientId = map['client_id'];
  }
}