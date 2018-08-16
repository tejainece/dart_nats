import 'dart:io';
import 'dart:convert';
import 'package:nats/nats.dart';

main() async {
  final socket = await Socket.connect('localhost', 4222);
  socket.listen((d) {
    print(String.fromCharCodes(d));
  });
  socket.add(
      'CONNECT {"verbose":false,"pedantic":false,"tls_required":false,"name":"","lang":"go","version":"1.2.2","protocol":1}\r\n'
          .runes
          .toList());
  socket.flush();
}
