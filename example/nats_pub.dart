import 'dart:async';
import 'dart:math';
import 'package:nats_dart/nats_dart.dart';

final rand = Random();

main() async {
  final nats = await Nats.connect();

  Subscription sub = await nats.subscribe("add.result");
  sub.onMessage.listen((Message msg) {
    print(msg.dataAsString);
  });

  while (true) {
    await nats.publish('add.problem', '${rand.nextInt(5000)} ${rand.nextInt(5000)}');
    await Future.delayed(Duration(seconds: 10));
  }
}
