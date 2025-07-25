import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VerifyCertificateScreen extends StatefulWidget {
  const VerifyCertificateScreen({super.key});

  @override
  State<VerifyCertificateScreen> createState() => _VerifyCertificateScreenState();
}

class _VerifyCertificateScreenState extends State<VerifyCertificateScreen> {
  final TextEditingController _searchController = TextEditingController();
  DocumentSnapshot? certificateData;

  Future<void> verifyCertificate() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('certificates')
        .where('email', isEqualTo: query)
        .get();

    if (!mounted) return;

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        certificateData = snapshot.docs.first;
      });
    } else {
      setState(() {
        certificateData = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificate not found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Certificate')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(labelText: 'Enter Email or ID'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: verifyCertificate,
              child: const Text('Verify'),
            ),
            const SizedBox(height: 20),
            if (certificateData != null) ...[
              Text('Name: ${certificateData!['name']}'),
              Text('Email: ${certificateData!['email']}'),
              SelectableText('URL: ${certificateData!['url']}'),
              SelectableText('QR URL: ${certificateData!['qrCodeUrl']}'),
            ]
          ],
        ),
      ),
    );
  }
}
