part of bitcoin.wire;

class RejectMessage extends Message {
  @override
  String get command => Message.CMD_REJECT;

  String message;
  String reason;

  /// Create an empty instance.
  RejectMessage.empty();

  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    message = readVarStr(reader);
    reader.readByte();
    reason = readVarStr(reader);
  }

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {}
}
