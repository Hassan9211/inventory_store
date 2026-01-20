import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cart_item.dart';

class PdfService {
  static Future<void> generateBillPdf(List<CartItem> cart) async {
    final pdf = pw.Document();

    int grandTotal = 0;
    for (var item in cart) {
      grandTotal += item.total;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Customer Bill",
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              // TABLE HEADER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Item"),
                  pw.Text("Price x Qty"),
                  pw.Text("Total"),
                ],
              ),
              pw.Divider(),

              // ITEMS
              ...cart.map(
                (item) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(item.fruit.name),
                    pw.Text("Rs ${item.fruit.price} x ${item.qty}"),
                    pw.Text("Rs ${item.total}"),
                  ],
                ),
              ),

              pw.Divider(),
              pw.SizedBox(height: 10),

              // GRAND TOTAL
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "TOTAL",
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "Rs $grandTotal",
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
