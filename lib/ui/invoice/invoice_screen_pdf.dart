import 'dart:io';
import 'package:al_farouq_factory/model/invoice_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart' show rootBundle;

class InvoicePdfService {
  // قائمة لتخزين مسارات ملفات PDF اللي اتعملت
  static List<String> generatedFiles = [];

  // إنشاء PDF
  static Future<void> generate(Invoice invoice) async {
    final pdf = pw.Document();

    // تحميل خط Cairo
    final fontData = await rootBundle.load("assets/fonts/static/Cairo-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'مصنع الفاروق',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      font: ttf,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'رقم الفاتورة: ${invoice.invoiceNumber}',
                      style: pw.TextStyle(font: ttf),
                    ),
                    pw.Text(
                      'التاريخ: ${invoice.date.day}/${invoice.date.month}/${invoice.date.year}',
                      style: pw.TextStyle(font: ttf),
                    ),
                  ],
                ),
                pw.Text('اسم العميل: ${invoice.clientName}', style: pw.TextStyle(font: ttf)),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('ا.فاروق الفقي: 01114263680', style: pw.TextStyle(font: ttf)),
                      pw.Text('ا.فاروق الفقي: 01032283755', style: pw.TextStyle(font: ttf)),
                      pw.Text('ا.طارق الفقي: 01146062114', style: pw.TextStyle(font: ttf)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.Table.fromTextArray(
                  headers: ['الصنف', 'الكمية', 'السعر', 'الإجمالي'],
                  data: invoice.items.map((e) {
                    return [
                      e.itemName,
                      e.quantity.toString(),
                      e.price.toStringAsFixed(2),
                      (e.price * e.quantity).toStringAsFixed(2),
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
                  cellStyle: pw.TextStyle(font: ttf),
                  cellAlignment: pw.Alignment.center,
                  cellAlignments: {
                    0: pw.Alignment.centerRight,
                    1: pw.Alignment.center,
                    2: pw.Alignment.center,
                    3: pw.Alignment.center,
                  },
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                  },
                ),
                pw.Divider(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'الإجمالي الكلي: ${invoice.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: ttf),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // حفظ الملف
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    // تخزين المسار في القائمة
    generatedFiles.add(filePath);

    await OpenFile.open(filePath);
  }

  // ======== حذف PDF ========
  static Future<void> deletePdf(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        generatedFiles.remove(path); // إزالة من القائمة
      }
    } catch (e) {
      print("خطأ عند حذف PDF: $e");
    }
  }

  // حذف كل ملفات PDF اللي اتولدت
  static Future<void> deleteAllPdf() async {
    for (String path in List.from(generatedFiles)) {
      await deletePdf(path);
    }
    generatedFiles.clear();
  }
}
