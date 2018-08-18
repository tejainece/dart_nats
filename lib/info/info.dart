class ConnectionInfo {
  /// The unique identifier of the NATS server
  final String serverId;

  /// The version of the NATS server
  final String version;

  /// The version of golang the NATS server was built with
  final String go;

  /// The IP address of the NATS server host
  final String host;

  /// The port number the NATS server is configured to listen on
  final int port;

  /// If this is set, then the client should try to authenticate upon connect.
  final bool authRequired;

  /// If this is set, then the client must authenticate using SSL.
  final bool sslRequired;

  /// Maximum payload size that the server will accept from the client.
  final int maxPayload;

  /// An optional list of server urls that a client can connect to.
  final Iterable<String> connectUrls;

  /// An integer indicating the protocol version of the server. The server
  /// version 1.2.0 sets this to 1 to indicate that it supports the “Echo” feature.
  final int proto;

  /// An optional unsigned integer (64 bits) representing the internal client
  /// identifier in the server. This can be used to filter client connections in
  /// monitoring, correlate with error logs, etc…
  final int clientId;

  ConnectionInfo(
      {this.serverId,
        this.version,
        this.go,
        this.host,
        this.port,
        this.authRequired,
        this.sslRequired,
        this.maxPayload,
        this.connectUrls: const <String>[],
        this.proto,
        this.clientId});

  factory ConnectionInfo.fromMap(Map<String, dynamic> map) {
    return ConnectionInfo(
        serverId: map['server_id'],
        version: map['version'],
        go: map['go'],
        host: map['host'],
        port: map['port'],
        authRequired: map['auth_required'],
        sslRequired: map['ssl_required'],
        maxPayload: map['max_payload'],
        connectUrls: (map['connect_urls'] as List).cast<String>() ?? <String>[],
        proto: map['proto'],
        clientId: map['client_id']);
  }
}