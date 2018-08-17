import 'dart:async';
import 'package:nats/nats.dart';

main() async {
  Comm comm = await Comm.connect();

  await comm.sendSub("chat");

  for(int i = 0; i < 10; i++) {
    // await comm.sendPub("hello", "Hello❤");
    await Future.delayed(Duration(seconds: 5));
  }
}
