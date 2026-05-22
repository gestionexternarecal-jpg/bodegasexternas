import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/bulk_excel_service.dart';
import 'product_entry_grid.dart';

/// Descarga plantilla y carga Excel en la grilla de productos.
class BulkUploadSection extends StatelessWidget {
  const BulkUploadSection({
    super.key,
    required this.gridKey,
    required this.onImportFinished,
    this.embedded = false,
  });

  final GlobalKey<ProductEntryGridState> gridKey;
  final VoidCallback onImportFinished;

  /// Sin tarjeta propia; para usar en una fila junto a otros controles.
  final bool embedded;

  Future<void> _downloadTemplate(BuildContext context) async {
    try {
      final bytes = BulkExcelService.buildTemplateBytes();
      final path = await FilePicker.saveFile(
        dialogTitle: 'Guardar plantilla de carga masiva',
        fileName: 'plantilla_carga_masiva.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (path == null) return;

      await File(path).writeAsBytes(bytes);
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        message: 'Plantilla guardada correctamente',
      );
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        message: 'Error al guardar plantilla: $e',
        isError: true,
      );
    }
  }

  Future<void> _pickAndImport(BuildContext context) async {
    final grid = gridKey.currentState;
    if (grid == null) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (file.path == null) {
          throw StateError('No se pudo leer el archivo');
        }
        final diskBytes = await File(file.path!).readAsBytes();
        if (!context.mounted) return;
        await _runImport(context, grid, diskBytes);
        return;
      }
      if (!context.mounted) return;
      await _runImport(context, grid, bytes);
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        message: e is FormatException ? e.message : 'Error al importar: $e',
        isError: true,
      );
    }
  }

  Future<void> _runImport(
    BuildContext context,
    ProductEntryGridState grid,
    List<int> bytes,
  ) async {
    final rows = BulkExcelService.parseBytes(bytes);
    if (!context.mounted) return;

    final progress = ValueNotifier<int>(0);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Cargando Excel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Buscando productos y validando stock...'),
            const SizedBox(height: 16),
            ValueListenableBuilder<int>(
              valueListenable: progress,
              builder: (_, current, __) {
                final total = rows.length;
                return LinearProgressIndicator(
                  value: total == 0 ? null : current / total,
                );
              },
            ),
          ],
        ),
      ),
    );

    try {
      final report = await grid.importBulkRows(
        rows,
        onProgress: (done, total) => progress.value = done,
      );
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      onImportFinished();
      AppSnackbar.show(
        context,
        message: 'Carga masiva: ${report.loadedRows} de ${report.totalRows} '
            'lineas cargadas'
            '${report.failedRows > 0 ? ' (${report.failedRows} con error)' : ''}',
        isError: report.failedRows > 0 && report.loadedRows == 0,
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        AppSnackbar.show(
          context,
          message: e is FormatException ? e.message : 'Error: $e',
          isError: true,
        );
      }
    } finally {
      progress.dispose();
    }
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'CARGA MASIVA',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _downloadTemplate(context),
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Descargar plantilla'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _pickAndImport(context),
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: const Text('Cargar Excel'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (embedded) return content;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: content,
      ),
    );
  }
}
