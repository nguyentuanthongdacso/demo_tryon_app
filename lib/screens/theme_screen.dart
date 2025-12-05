import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_styles.dart';

/// Màn hình chọn giao diện / Theme
class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  AppThemeType? _selectedTheme;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      setState(() {
        _selectedTheme = themeProvider.currentTheme;
      });
    });
  }

  Future<void> _saveTheme() async {
    if (_selectedTheme == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      await themeProvider.setTheme(_selectedTheme!);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('theme_saved')),
            backgroundColor: AppStyles.primaryGreen,
            duration: AppStyles.snackBarDurationShort,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving theme: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppStyles.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _getThemeName(AppThemeType theme, AppLocalizations loc) {
    final themeData = ThemeProvider.themes[theme]!;
    return loc.translate(themeData.nameKey);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              themeProvider.mainBackground,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  title: Text(loc.translate('theme_title')),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: AppStyles.paddingAll24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          loc.translate('select_theme'),
                          style: AppStyles.titleLarge,
                        ),
                        SizedBox(height: AppStyles.spacingLG),
                        Container(
                          padding: AppStyles.paddingHorizontal16,
                          decoration: AppStyles.containerWithBorder,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<AppThemeType>(
                              value: _selectedTheme,
                              isExpanded: true,
                              hint: Text(loc.translate('select_theme')),
                              items: ThemeProvider.availableThemes.map((theme) {
                                return DropdownMenuItem<AppThemeType>(
                                  value: theme,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: AppStyles.iconSizeLG,
                                        height: AppStyles.iconSizeLG,
                                        margin: EdgeInsets.only(right: AppStyles.spacingMD),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          gradient: LinearGradient(
                                            colors: theme == AppThemeType.pinkPastel
                                                ? [Colors.pink.shade100, Colors.pink.shade200]
                                                : [Colors.blue.shade100, Colors.blue.shade200],
                                          ),
                                        ),
                                      ),
                                      Text(_getThemeName(theme, loc)),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedTheme = value;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: AppStyles.spacingXXXL),
                        if (_selectedTheme != null) ...[
                          Text(
                            loc.translate('theme_preview'),
                            style: AppStyles.titleMedium,
                          ),
                          SizedBox(height: AppStyles.spacingMD),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPreviewCard(
                                  loc.translate('main_background'),
                                  ThemeProvider.themes[_selectedTheme]!.mainBackground,
                                ),
                              ),
                              SizedBox(width: AppStyles.spacingMD),
                              Expanded(
                                child: _buildPreviewCard(
                                  loc.translate('bottom_nav_background'),
                                  ThemeProvider.themes[_selectedTheme]!.bottomNavBackground,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _selectedTheme != null && !_isSaving
                              ? _saveTheme
                              : null,
                          style: AppStyles.primaryButtonStyleLarge,
                          child: _isSaving
                              ? SizedBox(
                                  width: AppStyles.progressSizeMD,
                                  height: AppStyles.progressSizeMD,
                                  child: CircularProgressIndicator(
                                    color: AppStyles.textWhite,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  loc.translate('save'),
                                  style: AppStyles.buttonText,
                                ),
                        ),
                      ],
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

  Widget _buildPreviewCard(String label, String imagePath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.bodySmallWithColor(AppStyles.textGreyDark),
        ),
        SizedBox(height: AppStyles.spacingSM),
        Container(
          height: 120,
          decoration: AppStyles.imageContainerWithShadow.copyWith(
            border: Border.all(color: AppStyles.backgroundGreyMedium),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ),
      ],
    );
  }
}
