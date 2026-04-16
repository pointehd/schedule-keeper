import 'package:flutter/material.dart';

class PageSliverAppBar extends StatelessWidget {
  const PageSliverAppBar({super.key, this.title, this.onRefresh});

  final String? title;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      elevation: 0,
      title: title != null ? Text(title!) : null,
      centerTitle: true,
      actions: [
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: onRefresh,
          )
        else
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: '알림',
            onPressed: () {},
          ),
      ],
    );
  }
}
