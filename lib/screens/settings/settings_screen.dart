import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    final currenciesList = [
      {'name': 'US Dollar (\$)', 'symbol': '\$'},
      {'name': 'Euro (€)', 'symbol': '€'},
      {'name': 'British Pound (£)', 'symbol': '£'},
      {'name': 'Pakistani Rupee (Rs)', 'symbol': 'Rs'},
      {'name': 'Indian Rupee (₹)', 'symbol': '₹'},
    ];

    final languagesList = [
      {'name': 'English', 'code': 'en'},
      {'name': 'Spanish', 'code': 'es'},
      {'name': 'Urdu', 'code': 'ur'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Appearance Title
          const Text(
            'APPEARANCE & VISUALS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),
          
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode Display'),
                  subtitle: const Text('Render dark palettes for low light environments'),
                  value: settingsProvider.themeMode == ThemeMode.dark,
                  onChanged: (val) {
                    settingsProvider.toggleTheme(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Core Configurations
          const Text(
            'PREFERENCES',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                // Currency dropdown row
                ListTile(
                  title: const Text('Preferred Currency'),
                  subtitle: const Text('Default monetary units displayed'),
                  trailing: DropdownButton<String>(
                    value: settingsProvider.currency,
                    underline: const SizedBox(),
                    items: currenciesList.map((cur) {
                      return DropdownMenuItem<String>(
                        value: cur['symbol'],
                        child: Text(cur['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        settingsProvider.setCurrency(val);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),

                // Notifications Toggle
                SwitchListTile(
                  title: const Text('Daily / Budget Reminders'),
                  subtitle: const Text('Enable device notifications for expense logs and alerts'),
                  value: settingsProvider.notificationsEnabled,
                  onChanged: (val) {
                    settingsProvider.toggleNotifications(val);
                  },
                ),
                const Divider(height: 1),

                // Language Choice row
                ListTile(
                  title: const Text('App Language'),
                  subtitle: const Text('Support standard localizations (ready framework)'),
                  trailing: DropdownButton<String>(
                    value: settingsProvider.languageCode,
                    underline: const SizedBox(),
                    items: languagesList.map((lang) {
                      return DropdownMenuItem<String>(
                        value: lang['code'],
                        child: Text(lang['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        settingsProvider.setLanguage(val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          Center(
            child: Text(
              'Expense Tracker Pro • v1.0.0',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onBackground.withOpacity(0.4)),
            ),
          ),
        ],
      ),
    );
  }
}
