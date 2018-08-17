import 'package:nats/nats.dart';

main() async {
  final nats = await Nats.connect();

  Subscription sub = await nats.subscribe("add.problem");
  sub.onMessage.listen((Message msg) async {
    int result = msg.dataAsString
        .split(' ')
        .map(int.tryParse)
        .fold(0, (a, b) => a + b);
    await nats.publish("add.result", result);
  });
}
