// ignore_for_file: file_names

import 'package:agq_app/content/app_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:agq_app/screens/utils/resources.dart';

class PDFScreen extends StatelessWidget {
  final String path;

  const PDFScreen(this.path, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.defaultBlueGray700,
        title: Text(
          AppContent.text(
              'text.screens.profile.utils.PDFPreview.pdf_preview_2bddce'),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Titillium Web',
          ),
        ),
      ),
      body: PDFView(
        filePath: path,
      ),
    );
  }
}
