import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_externa/core/network/odoo_rpc_client.dart';

void main() {
  group('OdooRpcClient.normalizeUrl', () {
    final client = OdooRpcClient();

    test('agrega https si falta', () {
      expect(
        client.normalizeUrl('odoo.ejemplo.com'),
        'https://odoo.ejemplo.com',
      );
    });

    test('quita barra final', () {
      expect(
        client.normalizeUrl('https://odoo.ejemplo.com/'),
        'https://odoo.ejemplo.com',
      );
    });

    test('lanza si url vacia', () {
      expect(() => client.normalizeUrl(''), throwsA(isA<Exception>()));
    });
  });
}
