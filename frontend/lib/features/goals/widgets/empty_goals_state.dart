import 'package:flutter/material.dart';

class EmptyGoalsState extends StatelessWidget {
  const EmptyGoalsState({super.key, required this.onAddTap});

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              '아직 목표가 없어요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 계획을 추가하고\n자기계발을 시작해보세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: onAddTap,
              child: const Text('계획 추가하러 가기'),
            ),
          ],
        ),
      ),
    );
  }
}
