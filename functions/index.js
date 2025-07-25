const functions = require('firebase-functions');
const nodemailer = require('nodemailer');
const QRCode = require('qrcode');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'your-email@gmail.com', // Replace with your Gmail
    pass: 'your-app-password', // Replace with your Gmail App Password
  },
});

exports.sendCertificateEmail = functions.https.onRequest(async (req, res) => {
  const { certId, recipientName, recipientEmail, qrCodeUrl, base64File, fileName, fileType } = req.body;

  try {
    const qrCodeDataUrl = await QRCode.toDataURL(qrCodeUrl);

    const mailOptions = {
      from: 'your-email@gmail.com',
      to: recipientEmail,
      subject: `Your Internship Certificate (${certId})`,
      html: `
        <h1>Congratulations, ${recipientName}!</h1>
        <p>Your internship certificate has been issued.</p>
        <p><strong>Certificate ID:</strong> ${certId}</p>
        <p><strong>Program:</strong> Your Internship Program</p>
        <p>Scan the QR code below to verify your certificate:</p>
        <img src="${qrCodeDataUrl}" alt="QR Code" />
        <p>Or use this link: <a href="${qrCodeUrl}">${qrCodeUrl}</a></p>
      `,
      attachments: base64File && fileName ? [{
        filename: fileName,
        content: base64File.split(',')[1] || base64File, // Remove data URI prefix if present
        encoding: 'base64',
        contentType: fileType === 'pdf' ? 'application/pdf' : `image/${fileType}`,
      }] : [],
    };

    await transporter.sendMail(mailOptions);
    res.status(200).send('Email sent successfully');
  } catch (error) {
    console.error('Error sending email:', error);
    res.status(500).send('emial not send');
  }
});