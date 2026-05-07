import 'dart:io';

import 'package:flutter/material.dart';

class PhotoViewerScreen extends StatelessWidget {
  final String path;
  const PhotoViewerScreen({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1.0,
          maxScale: 5.0,
          child: Image.file(File(path)),
        ),
      ),
    );
  }
}
