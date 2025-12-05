import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/banner_ad_widget.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../utils/app_styles.dart';

class SuggestIdeaScreen extends StatelessWidget {
  const SuggestIdeaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('style_suggestion')),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              Provider.of<ThemeProvider>(context).mainBackground,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Banner Ad ở đầu màn hình
                const BannerAdWidget(),
                // Main content
                Expanded(
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).translate('coming_soon'),
                      style: AppStyles.titleLarge,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
