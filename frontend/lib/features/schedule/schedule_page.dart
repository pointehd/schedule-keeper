import 'package:flutter/material.dart';
import '../../shared/widgets/page_sliver_app_bar.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const PageSliverAppBar(),
        SliverFillRemaining(
          child: Center(
            child: Text('일정추가', style: Theme.of(context).textTheme.headlineMedium),
          ),
        ),
      ],
    );
  }
}
