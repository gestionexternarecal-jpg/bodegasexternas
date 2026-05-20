import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_externa/core/utils/ecuador_datetime.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting(EcuadorDateTime.locale);
  });

  group('EcuadorDateTime', () {
    test('parseOdooUtc treats naive datetime as UTC', () {
      final utc = EcuadorDateTime.parseOdooUtc('2024-06-15 20:30:00');
      expect(utc, isNotNull);
      expect(utc!.isUtc, isTrue);
      expect(utc.hour, 20);
    });

    test('toEcuador subtracts five hours from UTC', () {
      final utc = DateTime.utc(2024, 6, 15, 20, 30);
      final ec = EcuadorDateTime.toEcuador(utc);
      expect(ec.hour, 15);
      expect(ec.minute, 30);
    });

    test('formatDateTime uses dd/MM/yyyy and 12h', () {
      final utc = DateTime.utc(2024, 6, 15, 20, 30);
      final text = EcuadorDateTime.formatDateTime(utc);
      expect(text, contains('15/06/2024'));
      expect(text, contains('03:30'));
    });
  });
}
