import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'dart:typed_data';
import 'dart:developer' as developer;

class CertificateListScreen extends StatefulWidget {
  const CertificateListScreen({super.key});

  @override
  State<CertificateListScreen> createState() => _CertificateListScreenState();
}

class _CertificateListScreenState extends State<CertificateListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _deleteCertificate(String certId) async {
    try {
      await FirebaseFirestore.instance.collection('certificates').doc(certId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificate deleted successfully')),
      );
    } catch (e) {
      developer.log('Delete error: $e', name: 'CertificateList');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Problem in deleting the certificate: $e')),
      );
    }
  }

  Future<Uint8List> _generateQrImage(String data) async {
    try {
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: true,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      );

      final image = await painter.toImageData(200);
      return image!.buffer.asUint8List();
    } catch (e) {
      developer.log('QR image generation error: $e', name: 'CertificateList');
      rethrow;
    }
  }

  Future<void> _viewCertificate(Map<String, dynamic> data, String certId) async {
    final name = data['name'] as String? ?? 'Unknown';
    final organization = data['organization'] as String? ?? 'Unknown';
    final internshipTitle = data['internshipTitle'] as String? ?? 'Unknown';
    final startDate = (data['startDate'] as Timestamp?)?.toDate();
    final endDate = (data['endDate'] as Timestamp?)?.toDate();
    final qrCodeUrl = data['qrCodeUrl'] as String? ?? 'https://certificate-5e995.web.app/verify?certId=$certId';

    try {
      final qrImageBytes = await _generateQrImage(qrCodeUrl);

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Internship Certificate',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Recipient: $name'),
                pw.Text('Organization: $organization'),
                pw.Text('Internship: $internshipTitle'),
                if (startDate != null)
                  pw.Text('Start Date: ${DateFormat('yyyy-MM-dd').format(startDate)}'),
                if (endDate != null)
                  pw.Text('End Date: ${DateFormat('yyyy-MM-dd').format(endDate)}'),
                pw.Text('Certificate ID: $certId'),
                pw.SizedBox(height: 20),
                pw.Image(pw.MemoryImage(qrImageBytes), width: 100, height: 100),
                pw.Text('Scan to verify: $qrCodeUrl'),
              ],
            ),
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Certificate not able to generate: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificate List'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade700, Colors.indigo.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search by Name or Email',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('certificates').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No certificates found'));
                  }
                  final certificates = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] as String?)?.toLowerCase() ?? '';
                    final email = (data['email'] as String?)?.toLowerCase() ?? '';
                    return name.contains(_searchQuery) || email.contains(_searchQuery);
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: certificates.length,
                    itemBuilder: (context, index) {
                      final doc = certificates[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final certId = doc.id;
                      final name = data['name'] as String? ?? 'Unknown';
                      final email = data['email'] as String? ?? 'Unknown';
                      final organization = data['organization'] as String? ?? 'Unknown';
                      final internshipTitle = data['internshipTitle'] as String? ?? 'Unknown';
                      final startDate = (data['startDate'] as Timestamp?)?.toDate();
                      final endDate = (data['endDate'] as Timestamp?)?.toDate();

                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: $email', style: const TextStyle(fontSize: 14)),
                              Text('Organization: $organization', style: const TextStyle(fontSize: 14)),
                              Text('Internship: $internshipTitle', style: const TextStyle(fontSize: 14)),
                              if (startDate != null)
                                Text(
                                  'Start: ${DateFormat('yyyy-MM-dd').format(startDate)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              if (endDate != null)
                                Text(
                                  'End: ${DateFormat('yyyy-MM-dd').format(endDate)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility, color: Colors.indigo),
                                onPressed: () => _viewCertificate(data, certId),
                                tooltip: 'View Certificate',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Certificate'),
                                      content: Text('Are you sure you want to delete $name\'s certificate?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteCertificate(certId);
                                          },
                                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                tooltip: 'Delete Certificate',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
