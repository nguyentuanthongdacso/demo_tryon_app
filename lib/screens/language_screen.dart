import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  Locale? _selected;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LanguageProvider>(context);
    _selected ??= provider.currentLocale;

    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('language_screen_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: RadioGroup<String>(
                groupValue: _selected?.languageCode,
                onChanged: (val) {
                  if (val != null) {
                    final option = LanguageProvider.supportedLanguages.firstWhere(
                      (o) => o.locale.languageCode == val,
                    );
                    setState(() {
                      _selected = option.locale;
                    });
                  }
                },
                child: ListView.builder(
                  itemCount: LanguageProvider.supportedLanguages.length,
                  itemBuilder: (context, index) {
                    final option = LanguageProvider.supportedLanguages[index];
                    final selected = _selected?.languageCode == option.locale.languageCode;
                    return RadioListTile<String>(
                      value: option.locale.languageCode,
                      title: Text('${option.name} (${option.nativeName})'),
                      selected: selected,
                    );
                  },
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_selected != null) {
                  await provider.setLanguage(_selected!);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(AppLocalizations.of(context).translate('save_language')),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
