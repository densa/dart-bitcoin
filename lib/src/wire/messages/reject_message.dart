part of bitcoin.wire;

class RejectMessage extends Message {
  @override
  String get command => Message.CMD_REJECT;

  String message;
  int code;
  String reason;
  int data;

  /// Create an empty instance.
  RejectMessage.empty();

  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    message = readVarStr(reader);
    code = readVarInt(reader);
    reason = readVarStr(reader);
    data = readVarInt(reader);
  }

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {}
}
