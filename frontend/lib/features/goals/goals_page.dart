import 'package:flutter/material.dart';
import '../../shared/widgets/page_sliver_app_bar.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const PageSliverAppBar(),
        SliverFillRemaining(
          child: Center(
            child: Text('목표', style: Theme.of(context).textTheme.headlineMedium),
          ),
        ),
      ],
    );
  }
}
