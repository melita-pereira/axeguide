import 'package:flutter/material.dart';

class ScrollableScaffold extends StatelessWidget {
  final String? title;
  final Widget child;
  final AppBar? appBar;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const ScrollableScaffold({
    super.key,
    this.title,
    required this.child,
    this.appBar,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar?? (title != null ? AppBar(title: Text(title!)) : null),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: padding,
                child: IntrinsicHeight(
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}