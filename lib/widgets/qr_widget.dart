import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrWidget extends StatelessWidget {
  final String certId;

  const QrWidget({super.key, required this.certId});

  @override
  Widget build(BuildContext context) {
    final qrCodeUrl = 'https://certificate-5e995.web.app/verify?certId=$certId';

    return Column(
      children: [
        QrImageView(
          data: qrCodeUrl,
          version: QrVersions.auto,
          size: 200.0,
          backgroundColor: Colors.white,
        ),
        const SizedBox(height: 10),
        Text(
          'Scan to verify certificate',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/verify', arguments: {'certId': certId});
          },
          child: const Text('Open Verification Link'),
        ),
      ],
    );
  }
}