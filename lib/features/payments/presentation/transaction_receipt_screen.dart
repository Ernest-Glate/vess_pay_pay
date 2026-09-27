import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_container.dart';

class TransactionReceiptScreen extends ConsumerWidget {
  final TransactionModel transaction;

  const TransactionReceiptScreen({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Transaction Receipt',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildReceiptPreview(),
                      const SizedBox(height: 32),
                      _buildActionButtons(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptPreview() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.successGreen,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  transaction.status == 'completed' ? 'Transaction Successful' : 'Transaction ${transaction.status.toUpperCase()}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          const Divider(color: AppColors.borderGray),
          const SizedBox(height: 24),

          // Amount
          Center(
            child: Column(
              children: [
                Text(
                  CurrencyFormatters.formatAmount(transaction.amount, transaction.currency),
                  style: const TextStyle(
                    color: AppColors.royalGold,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  transaction.description ?? transaction.typeLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Divider(color: AppColors.borderGray),
          const SizedBox(height: 24),

          // Details
          _buildDetailRow('Transaction ID', transaction.id),
          const SizedBox(height: 16),
          _buildDetailRow('Reference', transaction.hubtelTransactionId ?? 'N/A'),
          const SizedBox(height: 16),
          _buildDetailRow('Type', _getTransactionTypeLabel(transaction.type)),
          const SizedBox(height: 16),
          _buildDetailRow('Date', _formatDate(transaction.createdAt)),
          const SizedBox(height: 16),
          _buildDetailRow('Time', _formatTime(transaction.createdAt)),
          const SizedBox(height: 16),
          _buildDetailRow('Status', transaction.status.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        AppButton(
          label: 'Download PDF',
          onPress: () => _downloadPdf(context),
          icon: Icons.download_rounded,
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Share Receipt',
          onPress: () => _shareReceipt(context),
          variant: AppButtonVariant.secondary,
          icon: Icons.share_rounded,
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Print Receipt',
          onPress: () => _printReceipt(context),
          variant: AppButtonVariant.secondary,
          icon: Icons.print_rounded,
        ),
      ],
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final pdf = await _generatePdf();
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'receipt_${transaction.id}.pdf',
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt downloaded successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading receipt: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _shareReceipt(BuildContext context) async {
    try {
      final pdf = await _generatePdf();
      final bytes = await pdf.save();
      
      // Save to temporary file and share
      await Printing.sharePdf(bytes: bytes, filename: 'receipt_${transaction.id}.pdf');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing receipt: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _printReceipt(BuildContext context) async {
    try {
      final pdf = await _generatePdf();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing receipt: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'VESSPAY',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Transaction Receipt',
                        style: const pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 40),
                pw.Divider(),
                pw.SizedBox(height: 24),

                // Amount
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        CurrencyFormatters.formatAmount(transaction.amount, transaction.currency),
                        style: pw.TextStyle(
                          fontSize: 36,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        transaction.description ?? transaction.typeLabel,
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 32),
                pw.Divider(),
                pw.SizedBox(height: 24),

                // Details Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    _buildPdfRow('Transaction ID', transaction.id),
                    _buildPdfRow('Reference', transaction.hubtelTransactionId ?? 'N/A'),
                    _buildPdfRow('Type', _getTransactionTypeLabel(transaction.type)),
                    _buildPdfRow('Date', _formatDate(transaction.createdAt)),
                    _buildPdfRow('Time', _formatTime(transaction.createdAt)),
                    _buildPdfRow('Status', transaction.status.toUpperCase()),
                  ],
                ),

                pw.Spacer(),

                // Footer
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Thank you for using VessPay',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Generated on ${_formatDate(DateTime.now())} at ${_formatTime(DateTime.now())}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  pw.TableRow _buildPdfRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(12),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(12),
          child: pw.Text(value),
        ),
      ],
    );
  }

  String _getTransactionTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'credit':
        return 'Money Received';
      case 'debit':
        return 'Money Sent';
      case 'exchange':
        return 'Currency Exchange';
      default:
        return type.toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
