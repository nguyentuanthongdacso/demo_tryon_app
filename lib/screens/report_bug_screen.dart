import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../utils/app_styles.dart';
import 'package:provider/provider.dart';

class ReportBugScreen extends StatefulWidget {
  const ReportBugScreen({super.key});

  @override
  State<ReportBugScreen> createState() => _ReportBugScreenState();
}

class _ReportBugScreenState extends State<ReportBugScreen> {
  String? _selectedBugType;
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _bugTypes = [
    'login_logout_bug',
    'search_bug',
    'token_bug',
    'tryon_bug',
    'image_bug',
    'other_bug',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitReport() {
    final loc = AppLocalizations.of(context);

    if (_selectedBugType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('please_select_bug_type')),
          backgroundColor: AppStyles.primaryOrange,
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('please_enter_description')),
          backgroundColor: AppStyles.primaryOrange,
        ),
      );
      return;
    }

    // Hiển thị dialog cảm ơn
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.borderRadiusXL,
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppStyles.iconGreen, size: AppStyles.iconSizeXL),
            SizedBox(width: AppStyles.spacingSM),
            Expanded(
              child: Text(
                loc.translate('thank_you'),
                style: AppStyles.dialogTitle,
              ),
            ),
          ],
        ),
        content: Text(
          loc.translate('report_bug_thanks'),
          style: AppStyles.dialogContent,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(loc.translate('ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(loc.translate('report_bug')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(themeProvider.mainBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppStyles.paddingAll16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: AppStyles.paddingAll16,
                  decoration: AppStyles.cardDecoration,
                  child: Row(
                    children: [
                      Icon(Icons.bug_report, size: AppStyles.iconSizeXXXL, color: AppStyles.iconRed),
                      SizedBox(width: AppStyles.spacingMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.translate('report_bug'),
                              style: AppStyles.titleLarge,
                            ),
                            SizedBox(height: AppStyles.spacingXS),
                            Text(
                              loc.translate('report_bug_subtitle'),
                              style: AppStyles.subtitleText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppStyles.spacingXL),

                // Bug type dropdown
                Container(
                  padding: AppStyles.paddingAll16,
                  decoration: AppStyles.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('bug_type'),
                        style: AppStyles.titleMedium,
                      ),
                      SizedBox(height: AppStyles.spacingMD),
                      DropdownButtonFormField<String>(
                        value: _selectedBugType,
                        hint: Text(loc.translate('select_bug_type')),
                        isExpanded: true,
                        decoration: AppStyles.dropdownFormFieldDecoration,
                        items: _bugTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(loc.translate(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBugType = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppStyles.spacingLG),

                // Bug description
                Container(
                  padding: AppStyles.paddingAll16,
                  decoration: AppStyles.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('bug_description'),
                        style: AppStyles.titleMedium,
                      ),
                      SizedBox(height: AppStyles.spacingMD),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: AppStyles.multilineTextFieldDecoration(
                          hintText: loc.translate('bug_description_hint'),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppStyles.spacingXXL),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitReport,
                    style: AppStyles.dangerButtonStyle,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send, color: AppStyles.textWhite),
                        SizedBox(width: AppStyles.spacingSM),
                        Text(
                          loc.translate('submit_report'),
                          style: AppStyles.buttonText,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
