part of 'nats.dart';

/// A message usually used to deliver a subscription.
class Message {
  /// Subject of the message.
  final String subject;

  /// Subject to reply to to reach the sender of this message.
  final String replyTo;

  /// Data or payload of the message.
  final Iterable<int> data;

  /// Subscription that is delivering this message.
  final Subscription subscription;

  Message(this.subject, this.replyTo, this.data, this.subscription);

  /// Returns payload as string
  String get dataAsString => utf8.decode(data);

  String toString() => '$subject $dataAsString';
}