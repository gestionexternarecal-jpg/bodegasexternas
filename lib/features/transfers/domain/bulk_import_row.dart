/// Fila leida desde Excel para carga masiva en la grilla.
class BulkImportRow {
  const BulkImportRow({
    required this.codigo,
    this.detalle,
    required this.cantidad,
    this.sheetRowNumber,
  });

  final String codigo;
  final String? detalle;
  final double cantidad;
  final int? sheetRowNumber;
}

class BulkImportReport {
  const BulkImportReport({
    required this.totalRows,
    required this.loadedRows,
    required this.failedRows,
    required this.skippedRows,
  });

  final int totalRows;
  final int loadedRows;
  final int failedRows;
  final int skippedRows;
}
