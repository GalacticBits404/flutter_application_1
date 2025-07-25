import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Required for TimeoutException
import 'dart:developer' as developer;

class PublicVerifyScreen extends StatelessWidget {
  final String certId;

  const PublicVerifyScreen({super.key, required this.certId});

  @override
  Widget build(BuildContext context) {
    developer.log('Verifying certId: $certId', name: 'PublicVerifyScreen');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Certificate'),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade700,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade700, Colors.indigo.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('certificates')
              .doc(certId)
              .get()
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  developer.log('Firestore query timed out for certId: $certId', name: 'PublicVerifyScreen');
                  throw TimeoutException('Firestore query timed out');
                },
              ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('An error occurred while fetching the certificate.'));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              developer.log(
                'No certificate found for certId: $certId, hasData: ${snapshot.hasData}, exists: ${snapshot.data?.exists ?? false}',
                name: 'PublicVerifyScreen',
              );
              return const Center(child: Text('Certificate not found'));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final fileName = data['fileName'] as String? ?? 'unknown';
            final fileType = data['fileType'] as String? ?? 'unknown';
            final startDate = (data['startDate'] as Timestamp?)?.toDate();
            final endDate = (data['endDate'] as Timestamp?)?.toDate();

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Certificate Verification',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade900,
                              ),
                        ),
                        const SizedBox(height: 20),
                        Text('Recipient: ${data['name']}', style: const TextStyle(fontSize: 20)),
                        Text('Email: ${data['email']}', style: const TextStyle(fontSize: 16)),
                        Text('Organization: ${data['organization']}', style: const TextStyle(fontSize: 16)),
                        Text('Internship: ${data['internshipTitle']}', style: const TextStyle(fontSize: 16)),
                        if (startDate != null)
                          Text(
                            'Start Date: ${DateFormat('yyyy-MM-dd').format(startDate)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        if (endDate != null)
                          Text(
                            'End Date: ${DateFormat('yyyy-MM-dd').format(endDate)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        Text('Certificate ID: ${data['certificateId']}', style: const TextStyle(fontSize: 16)),
                        Text('File: $fileName ($fileType)', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.visibility),
                          label: const Text('View Certificate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('View Certificate'),
                                content: Text('Certificate: $fileName\nType: $fileType\n(Base64 data available in Firestore)'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
