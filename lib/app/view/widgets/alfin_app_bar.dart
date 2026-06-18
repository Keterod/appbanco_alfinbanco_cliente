import 'package:flutter/material.dart';

import '../../ui/theme/app_colors.dart';

class AlfinAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AlfinAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      backgroundColor: Colors.transparent,
      title: Text(title),
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.purpleSupport, AppColors.secondary],
          ),
        ),
      ),
    );
  }
}
