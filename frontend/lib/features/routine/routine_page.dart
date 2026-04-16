import 'package:flutter/material.dart';
import '../../shared/widgets/page_sliver_app_bar.dart';

class RoutinePage extends StatelessWidget {
  const RoutinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const PageSliverAppBar(),
        SliverFillRemaining(
          child: Center(
            child: Text('루틴', style: Theme.of(context).textTheme.headlineMedium),
          ),
        ),
      ],
    );
  }
}
