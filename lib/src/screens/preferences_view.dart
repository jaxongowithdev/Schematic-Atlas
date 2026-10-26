import 'package:flutter/material.dart';
import '../database/storage_manager.dart';
import '../models/config_model.dart';

class PreferencesView extends StatefulWidget {
  final VoidCallback onSettingsChanged;

  const PreferencesView({
    super.key,
    required this.onSettingsChanged,
  });

  @override
  State<PreferencesView> createState() => _PreferencesViewState();
}

class _PreferencesViewState extends State<PreferencesView> {
  final _storage = StorageManager.instance;
  ConfigModel? _config;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _storage.getConfig();
    setState(() {
      _config = config;
      _isLoading = false;
    });
  }

  Future<void> _updateConfig(ConfigModel config) async {
    await _storage.updateConfig(config);
    setState(() {
      _config = config;
    });
    widget.onSettingsChanged();
  }

  Future<void> _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Data'),
        content: const Text(
          'This will reset all your progress, favorites, and quiz results. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.resetData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data reset successfully')),
        );
      }
      widget.onSettingsChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _config == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(_getThemeLabel(_config!.theme)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(),
          ),

          const Divider(height: 32),

          // Data Section
          _buildSectionHeader('Data'),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.orange),
            title: const Text('Reset Data'),
            subtitle: const Text('Clear all progress and favorites'),
            onTap: _resetData,
          ),

          const Divider(height: 32),

          // About Section
          _buildSectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy Policy'),
            subtitle: Text('100% offline, no data collection'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  String _getThemeLabel(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System';
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: _config!.theme,
              onChanged: (value) {
                Navigator.pop(context);
                _updateConfig(_config!.copyWith(theme: value));
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: _config!.theme,
              onChanged: (value) {
                Navigator.pop(context);
                _updateConfig(_config!.copyWith(theme: value));
              },
            ),
            RadioListTile<String>(
              title: const Text('System'),
              value: 'system',
              groupValue: _config!.theme,
              onChanged: (value) {
                Navigator.pop(context);
                _updateConfig(_config!.copyWith(theme: value));
              },
            ),
          ],
        ),
      ),
    );
  }
}
