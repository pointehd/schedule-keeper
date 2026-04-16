import 'package:flutter/material.dart';

class PageSliverAppBar extends StatelessWidget {
  const PageSliverAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: '알림',
          onPressed: () {},
        ),
      ],
    );
  }
}
