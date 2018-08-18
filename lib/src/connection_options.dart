part of 'wire.dart';

class ConnectionOptions {
  final String host;

  final int port;

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