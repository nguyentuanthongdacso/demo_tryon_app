import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart';
import '../l10n/app_localizations.dart';

class SuggestIdeaScreen extends StatelessWidget {
  const SuggestIdeaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Banner Ad ở đầu màn hình
        const BannerAdWidget(),
        // Main content
        Expanded(
          child: Center(
            child: Text(AppLocalizations.of(context).translate('coming_soon')),
          ),
        ),
      ],
    );
  }
}
