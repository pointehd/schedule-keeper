import 'package:flutter/material.dart';
import '../../shared/widgets/page_sliver_app_bar.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const PageSliverAppBar(),
        SliverFillRemaining(
          child: Center(
            child: Text('마이페이지', style: Theme.of(context).textTheme.headlineMedium),
          ),
        ),
      ],
    );
  }
}
