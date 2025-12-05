import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart';
import '../l10n/app_localizations.dart';

class SuggestIdeaScreen extends StatelessWidget {
  const SuggestIdeaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('style_suggestion')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
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
        ),
      ),
    );
  }
}
