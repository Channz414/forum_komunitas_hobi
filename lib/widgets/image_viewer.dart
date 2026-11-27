import 'package:flutter/material.dart';

/// Layar gambar penuh, bisa di-zoom dan digeser. GIF tetap beranimasi.
void showImageViewer(BuildContext context, String url) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: InteractiveViewer(maxScale: 5, child: Image.network(url)),
        ),
      ),
    ),
  );
}
