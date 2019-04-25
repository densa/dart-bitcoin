import 'package:bignum/bignum.dart';
import 'package:bitcoin/wire.dart';
import 'package:convert/convert.dart';
import 'package:test/test.dart';

void main() {
  /*test('check VersionMessage encoded', () {
    final expected = hex.decode('e3e1f3e876657273696f6e00000000006f000000198f3a68'
        '7f1101000000000000000000d4d9c15c00000000000000000000000000000000000000000000'
        'ffff7f000001208d000000000000000000000000000000000000ffff7f000001208d01000000'
        '00000000192f426974636f696e20436173683a2e312d437261776c65722f0000000000');
    final bytes = Message.encode(
      _buildVersionMessage('Bitcoin Cash', 70015, 8333),
      0xe3e1f3e8,
      70015,
      withChecksum: true,
    );
    expect(bytes, equals(expected));
  });*/

  test('check VerackMessage encoded', () {
    final expected = hex.decode('e3e1f3e876657261636b000000000000000000005df6e0e2');
    final bytes = Message.encode(
      VerackMessage(),
      0xe3e1f3e8,
      70015,
      withChecksum: true,
    );
    expect(bytes, equals(expected));
  });
}

VersionMessage _buildVersionMessage(String coinName, int pver, int port) {
  final services = BigInteger.ZERO;
  final time = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  VersionMessage ver = new VersionMessage(
    clientVersion: pver,
    services: services,
    time: time,
    myAddress: PeerAddress.localhost(services: services, port: port),
    theirAddress: PeerAddress.localhost(services: services, port: port),
    nonce: 1,
    subVer: "/" + coinName + ":" + ".1-Crawler" + "/",
    lastHeight: 0,
    relayBeforeFilter: false,
    coinName: coinName,
  );
  return ver;
}
