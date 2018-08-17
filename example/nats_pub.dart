import 'package:nats/nats.dart';
import 'dart:math';

final rand = Random();

main() async {
  final nats = await Nats.connect();

  Subscription sub = await nats.subscribe("add.result");
  sub.onMessage.listen((Message msg) {
    print(msg.dataAsString);
  });

  for(int i = 0; i < 10; i++) {
    await nats.publish('add.problem', '20 5');
  }
}
