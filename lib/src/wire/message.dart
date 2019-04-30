part of bitcoin.wire;

typedef Message _MessageGenerator();

abstract class Message extends BitcoinSerializable {
  static const String CMD_ADDR = "addr";
  static const String CMD_GETADDR = "getaddr";
  static const String CMD_VERACK = "verack";
  static const String CMD_VERSION = "version";
  static const String CMD_PING = "ping";
  static const String CMD_PONG = "pong";
  static const String CMD_REJECT = "reject";

  static final Map<String, _MessageGenerator> _MESSAGE_GENERATORS = {
    CMD_ADDR: () => new AddressMessage.empty(),
    CMD_GETADDR: () => new GetAddressMessage.empty(),
    CMD_VERACK: () => new VerackMessage.empty(),
    CMD_VERSION: () => new VersionMessage.empty(),
    CMD_PING: () => PingMessage.empty(),
    CMD_PONG: () => PongMessage.empty(),
    CMD_REJECT: () => RejectMessage.empty(),
  };

  static const int HEADER_LENGTH = 24; // = 4 + COMMAND_LENGTH + 4 + 4;
  static const int COMMAND_LENGTH = 12;

  String get command;

  int _byteSize = 0;

  int get byteSize => _byteSize;

  Message();

  factory Message.forCommand(String command) {
    if (!_MESSAGE_GENERATORS.containsKey(command)) {
      throw new ArgumentError("$command");
    }
    return _MESSAGE_GENERATORS[command]();
  }

  void bitcoinDeserialize(bytes.Reader reader, int pver);
  void bitcoinSerialize(bytes.Buffer buffer, int pver);

  /// Decode a serialized message.
  static Message decode(Uint8List msgBytes, int pver) {
    if (msgBytes.length < HEADER_LENGTH) throw new SerializationException("Too few bytes to be a Message");

    // create a Reader for deserializing
    var reader = new bytes.Reader(msgBytes);

    // verify the magic value
    reader.readBytes(4);

    // read the command, length and checksum
    String cmd = _readCommand(readBytes(reader, COMMAND_LENGTH));
    int payloadLength = readUintLE(reader);
    Uint8List checksum = readBytes(reader, 4);

    // create a checksum reader to be able to determine the checksum afterwards
    ChecksumReader payloadReader = new ChecksumReader(reader, new crypto.DoubleSHA256Digest());
    int preLength = reader.remainingLength;

    // generate an empty concrete message instance and make it parse
    Message msg = new Message.forCommand(cmd);
    msg.bitcoinDeserialize(payloadReader, pver);
    int postLength = reader.remainingLength;

    // check if the payload was of the claimed size
    if (preLength - postLength != payloadLength) {
      throw new SerializationException("Incorrect payload length in message header "
          "(actual: ${(preLength - postLength)}, expected: $payloadLength");
    }

    // check the checksum
    Uint8List actualChecksum = payloadReader.checksum().sublist(0, 4);
    if (!utils.equalLists(checksum, actualChecksum)) {
      throw new SerializationException("Incorrect checksum provided in serialized message "
          "(actual: ${CryptoUtils.bytesToHex(actualChecksum)}, "
          "expected: ${CryptoUtils.bytesToHex(checksum)})");
    }

    msg._byteSize = HEADER_LENGTH + payloadLength;

    return msg;
  }

  /// Encode a message to serialized format.
  static Uint8List encode(Message msg, int magicValue, int pver, {bool withChecksum = true, Endian magicEndian: Endian.big}) {
    // serialize the payload
    ChecksumBuffer payloadBuffer = new ChecksumBuffer(new crypto.DoubleSHA256Digest());
    msg.bitcoinSerialize(payloadBuffer, pver);

    final cmd = _encodeCommand(msg.command);
    final buffer = ByteBuffer(4 + cmd.length + 4 + 4 + payloadBuffer.length);
    buffer.addUint32(magicValue, magicEndian);
    buffer.addBytes(cmd);
    buffer.addUint32(payloadBuffer.length);
    if (withChecksum) {
      buffer.addBytes(payloadBuffer.checksum().sublist(0, 4));
    }
    buffer.addBytes(payloadBuffer.asBytes());
    return buffer.toBytes();
  }

  static String _readCommand(Uint8List bytes) {
    int word = COMMAND_LENGTH;
    while (bytes[word - 1] == 0) word--;
    return ascii.decode(bytes.sublist(0, word));
  }

  static List<int> _encodeCommand(String command) {
    List<int> commandBytes = new List.from(ascii.encode(command));
    while (commandBytes.length < COMMAND_LENGTH) commandBytes.add(0);
    return commandBytes;
  }
}

class ByteBuffer {
  Uint8List _bytes;
  ByteData _data;
  int _offsetInBytes = 0;

  ByteBuffer(int initialCapacity) {
    _bytes = Uint8List(initialCapacity);
    _data = _bytes.buffer.asByteData();
  }

  void ensureCapacity(int capacity) {
    final int newLength = _offsetInBytes + capacity;
    if (newLength >= _bytes.length) {
      _bytes = Uint8List(newLength)..setAll(0, _bytes);
      _data = _bytes.buffer.asByteData();
    }
  }

  void addBytes(List<int> bytes) {
    ensureCapacity(bytes.length);
    _bytes.setAll(_offsetInBytes, bytes);
    _offsetInBytes += bytes.length;
  }

  void addUint32(int value, [Endian endian = Endian.little]) {
    ensureCapacity(4);
    _data.setUint32(_offsetInBytes, value, endian);
    _offsetInBytes += 4;
  }

  List<int> toBytes() {
    return _bytes.sublist(0, _offsetInBytes);
  }
}
