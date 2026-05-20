import 'package:excel/excel.dart';

import '../domain/bulk_import_row.dart';

/// Genera y parsea plantillas Excel para carga masiva (codigo, detalle, cantidad).
class BulkExcelService {
  static const templateSheetName = 'Carga masiva';
  static const headers = ['codigo', 'detalle', 'cantidad'];

  static List<int> buildTemplateBytes() {
    final excel = Excel.createExcel();
    final defaultName = excel.getDefaultSheet()!;
    excel.rename(defaultName, templateSheetName);
    final sheet = excel.tables[templateSheetName]!;

    sheet.appendRow(headers.map(TextCellValue.new).toList());
    sheet.appendRow([
      TextCellValue('EJEMPLO01'),
      TextCellValue('Descripcion del producto'),
      DoubleCellValue(1),
    ]);

    final encoded = excel.encode();
    if (encoded == null || encoded.isEmpty) {
      throw StateError('No se pudo generar la plantilla Excel');
    }
    return encoded;
  }

  static List<BulkImportRow> parseBytes(List<int> bytes) {
    if (bytes.isEmpty) {
      throw FormatException('El archivo Excel esta vacio');
    }

    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw FormatException('El Excel no contiene hojas');
    }

    final sheet = excel.tables.values.first;
    final rows = sheet.rows;
    if (rows.isEmpty) {
      throw FormatException('La hoja no tiene filas');
    }

    var startIndex = 0;
    var colCodigo = 0;
    var colDetalle = 1;
    var colCantidad = 2;

    final first = rows.first;
    if (_looksLikeHeader(first)) {
      startIndex = 1;
      final mapped = _mapHeaderColumns(first);
      if (mapped.$1 == null || mapped.$3 == null) {
        throw FormatException(
          'Encabezados requeridos: codigo, detalle, cantidad',
        );
      }
      colCodigo = mapped.$1!;
      colDetalle = mapped.$2 ?? 1;
      colCantidad = mapped.$3!;
    }

    final result = <BulkImportRow>[];
    for (var i = startIndex; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || _rowIsEmpty(row)) continue;

      final codigo = _cellString(row, colCodigo)?.trim() ?? '';
      if (codigo.isEmpty) continue;

      final detalle = _cellString(row, colDetalle)?.trim();
      final cantidad = _cellDouble(row, colCantidad);
      if (cantidad == null || cantidad <= 0) {
        throw FormatException(
          'Fila ${i + 1}: cantidad invalida para codigo "$codigo"',
        );
      }

      result.add(
        BulkImportRow(
          codigo: codigo,
          detalle: (detalle == null || detalle.isEmpty) ? null : detalle,
          cantidad: cantidad,
          sheetRowNumber: i + 1,
        ),
      );
    }

    if (result.isEmpty) {
      throw FormatException('No hay filas de datos en el Excel');
    }

    return result;
  }

  static bool _looksLikeHeader(List<Data?> row) {
    final texts = <String>[];
    for (var i = 0; i < row.length; i++) {
      final s = _cellString(row, i);
      if (s != null) texts.add(s.trim().toLowerCase());
    }
    return texts.contains('codigo') && texts.contains('cantidad');
  }

  static (int?, int?, int?) _mapHeaderColumns(List<Data?> row) {
    int? codigo;
    int? detalle;
    int? cantidad;
    for (var i = 0; i < row.length; i++) {
      final t = _cellString(row, i)?.trim().toLowerCase();
      if (t == null) continue;
      if (t == 'codigo' || t == 'código') codigo = i;
      if (t == 'detalle' || t == 'descripcion' || t == 'descripción') {
        detalle = i;
      }
      if (t == 'cantidad' || t == 'qty' || t == 'cant') cantidad = i;
    }
    return (codigo, detalle, cantidad);
  }

  static bool _rowIsEmpty(List<Data?> row) {
    return row.every((c) => _cellStringFromData(c)?.trim().isEmpty ?? true);
  }

  static String? _cellString(List<Data?> row, int index) {
    if (index < 0 || index >= row.length) return null;
    return _cellStringFromData(row[index]);
  }

  static String? _cellStringFromData(Data? cell) {
    if (cell == null) return null;
    final v = cell.value;
    if (v == null) return null;
    if (v is TextCellValue) return v.value.toString();
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) return v.value.toString();
    if (v is BoolCellValue) return v.value.toString();
    if (v is DateCellValue) return v.asDateTimeLocal().toString();
    if (v is DateTimeCellValue) return v.asDateTimeLocal().toString();
    if (v is FormulaCellValue) return v.formula;
    return v.toString();
  }

  static double? _cellDouble(List<Data?> row, int index) {
    if (index < 0 || index >= row.length) return null;
    final text = _cellString(row, index);
    if (text == null || text.trim().isEmpty) return null;
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }
}
