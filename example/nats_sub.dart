import 'package:nats_dart/nats_dart.dart';

main() async {
  print("Listening to 'add.problem':");
  final nats = await Nats.connect();

  Subscription sub = await nats.subscribe("add.problem");
  sub.onMessage.listen((Message msg) async {
    print("Got a problem to solve!");
    int result = msg.dataAsString
        .split(' ')
        .map(int.tryParse)
        .fold(0, (a, b) => a + b);
    await nats.publish("add.result", result);
  });
}
