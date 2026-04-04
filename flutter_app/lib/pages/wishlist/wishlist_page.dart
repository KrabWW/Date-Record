import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// 愿望清单页面 (占位)
class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('愿望清单'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 64,
              color: AppTheme.lovePink,
            ),
            const SizedBox(height: 24),
            const Text('愿望清单页面占位 - 待实现'),
          ],
        ),
      ),
    );
  }
}
