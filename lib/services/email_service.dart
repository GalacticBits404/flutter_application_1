import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class EmailService {
  static const String _functionUrl = 'https://us-central1-certificate-5e995.cloudfunctions.net/sendCertificateEmail';

  Future<bool> sendCertificateEmail({
    required String certId,
    required String recipientName,
    required String recipientEmail,
    required String pdfUrl,
    required String qrCodeUrl,
    String? base64File,
    String? fileName,
    String? fileType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'certId': certId,
          'recipientName': recipientName,
          'recipientEmail': recipientEmail,
          'pdfUrl': pdfUrl,
          'qrCodeUrl': qrCodeUrl,
          'base64File': base64File,
          'fileName': fileName,
          'fileType': fileType,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        developer.log('Email send problem: ${response.body}', name: 'EmailService');
        return false;
      }
    } catch (e) {
      developer.log('Error sending email: $e', name: 'EmailService');
      return false;
    }
  }
}