import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// 设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _autoSync = true;
  bool _offlineMode = false;
  String _language = '中文';
  String _defaultView = '列表';
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 账户信息
          _buildSectionHeader('账户'),
          _buildAccountCard(),
          
          // 外观设置
          _buildSectionHeader('外观'),
          _buildSwitchTile(
            '深色模式',
            '切换深色/浅色主题',
            Icons.dark_mode,
            _isDarkMode,
            (value) => setState(() => _isDarkMode = value),
          ),
          _buildSelectTile(
            '语言',
            _language,
            Icons.language,
            () => _showLanguagePicker(),
          ),
          _buildSelectTile(
            '默认视图',
            _defaultView,
            Icons.view_list,
            () => _showViewPicker(),
          ),
          
          // 通知设置
          _buildSectionHeader('通知'),
          _buildSwitchTile(
            '启用通知',
            '接收任务提醒和更新',
            Icons.notifications,
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
          ),
          _buildSwitchTile(
            '声音',
            '提醒时播放提示音',
            Icons.volume_up,
            _soundEnabled,
            (value) => setState(() => _soundEnabled = value),
          ),
          _buildSwitchTile(
            '振动',
            '提醒时振动',
            Icons.vibration,
            _vibrationEnabled,
            (value) => setState(() => _vibrationEnabled = value),
          ),
          _buildTimePickerTile(
            '每日提醒时间',
            _reminderTime.format(context),
            Icons.access_time,
            () => _showTimePicker(),
          ),
          
          // 数据与同步
          _buildSectionHeader('数据与同步'),
          _buildSwitchTile(
            '自动同步',
            '自动同步到云端',
            Icons.sync,
            _autoSync,
            (value) => setState(() => _autoSync = value),
          ),
          _buildSwitchTile(
            '离线模式',
            '仅使用本地数据',
            Icons.offline_bolt,
            _offlineMode,
            (value) => setState(() => _offlineMode = value),
          ),
          _buildActionTile(
            '立即同步',
            Icons.cloud_upload,
            () => _syncNow(),
          ),
          _buildActionTile(
            '导出数据',
            Icons.download,
            () => _exportData(),
          ),
          _buildActionTile(
            '导入数据',
            Icons.upload,
            () => _importData(),
          ),
          
          // 关于
          _buildSectionHeader('关于'),
          _buildInfoTile('版本', '1.0.0'),
          _buildInfoTile('构建', '20240227'),
          _buildActionTile(
            '检查更新',
            Icons.system_update,
            () => _checkUpdate(),
          ),
          _buildActionTile(
            '反馈与帮助',
            Icons.help_outline,
            () => _showHelp(),
          ),
          _buildActionTile(
            '隐私政策',
            Icons.privacy_tip,
            () => _showPrivacyPolicy(),
          ),
          
          const SizedBox(height: 32),
          
          // 登出按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () => _logout(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red[700],
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('退出登录'),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 辅助构建方法
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.secondaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'U',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '用户',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'user@example.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _editProfile(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildSelectTile(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
            color: Colors.grey,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildTimePickerTile(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: TextButton(
        onPressed: onTap,
        child: Text(value),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primaryColor,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  void _editProfile() {}
  void _logout() {}
  void _showLanguagePicker() {}
  void _showViewPicker() {}
  void _showTimePicker() {}
  void _syncNow() {}
  void _exportData() {}
  void _importData() {}
  void _checkUpdate() {}
  void _showHelp() {}
  void _showPrivacyPolicy() {}
  void _share() {}
}

// 导入缺失的依赖
import 'package:share_plus/share_plus.dart';