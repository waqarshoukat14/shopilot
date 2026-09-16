import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../models/invoice.dart';
import '../../core/utils/currency_helper.dart';

class InvoicePdfService {
  Future<pw.Document> generatePdf(Invoice invoice, {String? businessName}) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(invoice, businessName),
          pw.SizedBox(height: 20),
          _buildCustomerInfo(invoice),
          pw.SizedBox(height: 20),
          _buildItemsTable(invoice),
          pw.SizedBox(height: 20),
          _buildTotals(invoice),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );
    return pdf;
  }

  pw.Widget _buildHeader(Invoice invoice, String? businessName) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(businessName ?? 'Shopilot', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('INVOICE', style: pw.TextStyle(fontSize: 18, color: PdfColors.blue700)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Invoice #: ${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 14)),
            pw.Text('Date: ${_formatDate(invoice.createdAt)}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Status: ${invoice.status.name.toUpperCase()}', style: pw.TextStyle(
              fontSize: 12,
              color: invoice.status == InvoiceStatus.paid ? PdfColors.green700 : PdfColors.orange700,
            )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCustomerInfo(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 4),
          pw.Text(invoice.customerName, style: pw.TextStyle(fontSize: 14)),
          pw.Text('Customer ID: ${invoice.customerId}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(Invoice invoice) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _tableCell('Item', isHeader: true),
            _tableCell('Qty', isHeader: true),
            _tableCell('Price', isHeader: true),
            _tableCell('Total', isHeader: true),
          ],
        ),
        ...invoice.items.map((item) => pw.TableRow(
          children: [
            _tableCell(item.productName),
            _tableCell('${item.quantity}'),
            _tableCell(formatPrice(item.unitPrice, 'PKR')),
            _tableCell(formatPrice(item.subtotal, 'PKR')),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildTotals(Invoice invoice) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _totalRow('Subtotal', invoice.subtotal),
          if (invoice.discount > 0) _totalRow('Discount', -invoice.discount),
          if (invoice.tax > 0) _totalRow('Tax', invoice.tax),
          pw.Divider(),
          _totalRow('Total', invoice.total, isBold: true),
          _totalRow('Paid', invoice.paidAmount),
          if (invoice.dueAmount > 0) _totalRow('Due', invoice.dueAmount),
          pw.SizedBox(height: 8),
          pw.Text('Payment Method: ${invoice.paymentMethod.name.toUpperCase().replaceAll('_', ' ')}',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text('Thank you for your business!', style: pw.TextStyle(
          fontSize: 14, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic,
        )),
        pw.SizedBox(height: 4),
        pw.Text('Generated by Shopilot', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
      ],
    );
  }

  pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _totalRow(String label, double amount, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.SizedBox(width: 40),
          pw.Text(formatPrice(amount, 'PKR'), style: pw.TextStyle(
            fontSize: 12, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          )),
        ],
      ),
    );
  }

  Future<void> sharePdf(Invoice invoice, {String? businessName}) async {
    final pdf = await generatePdf(invoice, businessName: businessName);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], subject: 'Invoice #${invoice.invoiceNumber}');
  }

  Future<void> previewPdf(Invoice invoice, {String? businessName}) async {
    final pdf = await generatePdf(invoice, businessName: businessName);
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
