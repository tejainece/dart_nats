/// Connection options to NATS server
class ConnectionOptions {
  /// Host of NATS server to connect to.
  final String host;

  /// Port of NATS server to connect to.
  final int port;

  /// Turns on +OK protocol acknowledgements.
  final bool verbose;

  /// Turns on additional strict format checking, e.g. for properly formed
  /// subjects.
  final bool pedantic;

  /// Indicates whether the client requires an SSL connection.
  final bool sslRequired;

  /// Client authorization token.
  final String authToken;

  /// Connection username (if auth_required is set).
  final String user;

  /// Connection password (if auth_required is set).
  final String pass;

  /// Optional client name.
  final String name;

  /// The implementation language of the client.
  final String lang;

  /// The version of the client.
  final String version;

  /// Sending 0 (or absent) indicates client supports original protocol. Sending
  /// 1 indicates that the client supports dynamic reconfiguration of cluster
  /// topology changes by asynchronously receiving INFO messages with known
  /// servers it can reconnect to.
  final int protocol;

  /// If set to true, the server (version 1.2.0+) will not send originating
  /// messages from this connection to its own subscriptions. Clients should
  /// set this to true only for server supporting this feature, which is when
  /// proto in the INFO protocol is set to at least 1.
  final bool echo;

  const ConnectionOptions(
      {this.host: 'localhost',
        this.port: 4222,
        this.verbose: false,
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