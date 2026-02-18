import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/design_system/design_system.dart';
import '../providers/providers.dart';
import '../providers/repository_providers.dart';
import '../services/auth/google_auth_service.dart';
import '../services/ytmusic_sync_service.dart';
import '../services/album_color_extractor.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import '../../core/providers/theme_provider.dart';
import 'ytmusic_login_screen.dart';
import 'audio_settings_screen.dart';
import 'download_settings_screen.dart';
import 'backup_restore_screen.dart';

/// Provider for sync service
final ytMusicSyncServiceProvider = Provider<YTMusicSyncService>((ref) {
  final innerTube = ref.watch(innerTubeServiceProvider);
  return YTMusicSyncService(innerTube);
});

/// YT Music account & settings screen — redesigned with dynamic theming
class YTMusicSettingsScreen extends ConsumerStatefulWidget {
  const YTMusicSettingsScreen({super.key});

  @override
  ConsumerState<YTMusicSettingsScreen> createState() =>
      _YTMusicSettingsScreenState();
}

class _YTMusicSettingsScreenState extends ConsumerState<YTMusicSettingsScreen> {
  bool _isSyncing = false;
  SyncResult? _lastSyncResult;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────

  ColorScheme get _colors => Theme.of(context).colorScheme;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // Dynamic colors from album art
  AlbumColors get _albumColors => ref.watch(albumColorsProvider);
  bool get _hasAlbumColors => !_albumColors.isDefault;

  /// Background color - plain white in light mode, album colors in dark mode
  Color get _backgroundColor {
    if (_hasAlbumColors && _isDark) {
      return _albumColors.backgroundSecondary;
    }
    return _isDark ? MineColors.darkBackground : MineColors.background;
  }

  /// Accent color (dynamic or theme default)
  Color get _accentColor =>
      _hasAlbumColors ? _albumColors.accent : _colors.primary;

  Color get _cardColor => _isDark
      ? Colors.white.withValues(alpha: 0.05)
      : Colors.white.withValues(alpha: 0.85);
  Color get _textPrimary =>
      _isDark ? MineColors.darkTextPrimary : MineColors.textPrimary;
  Color get _textSecondary =>
      _isDark ? MineColors.darkTextSecondary : MineColors.textSecondary;
  Color get _textTertiary =>
      _isDark ? MineColors.darkTextTertiary : MineColors.textTertiary;

  /// Deep-link searchable items from nested screens (Audio, Downloads, Backup)
  List<_SearchableItem> get _deepSearchItems => [
    // Audio Settings
    _SearchableItem(
      tags: [
        'streaming',
        'quality',
        'audio',
        'bitrate',
        'kbps',
        'auto',
        'low',
        'medium',
        'high',
        'max',
      ],
      title: 'Streaming Quality',
      subtitle: 'Adjust audio bitrate for streaming',
      icon: Iconsax.volume_high,
      screen: const AudioSettingsScreen(),
    ),
    _SearchableItem(
      tags: ['crossfade', 'transition', 'blend', 'gapless', 'playback'],
      title: 'Crossfade Transition',
      subtitle: 'Blend tracks smoothly into each other',
      icon: Iconsax.blend,
      screen: const AudioSettingsScreen(),
    ),
    _SearchableItem(
      tags: ['streaming', 'cache', 'buffer', 'preload', 'wifi'],
      title: 'Streaming Cache',
      subtitle: 'Pre-cache next tracks, Wi-Fi only option',
      icon: Iconsax.cpu,
      screen: const AudioSettingsScreen(),
    ),
    // Download Settings
    _SearchableItem(
      tags: ['download', 'quality', 'offline', 'bitrate'],
      title: 'Download Quality',
      subtitle: 'Quality for offline downloads',
      icon: Iconsax.document_download,
      screen: const DownloadSettingsScreen(),
    ),
    _SearchableItem(
      tags: ['download', 'location', 'path', 'folder', 'storage', 'directory'],
      title: 'Download Location',
      subtitle: 'Where downloaded music is stored',
      icon: Iconsax.folder_2,
      screen: const DownloadSettingsScreen(),
    ),
    _SearchableItem(
      tags: ['data', 'usage', 'network', 'bandwidth', 'mobile'],
      title: 'Data Usage Info',
      subtitle: 'Estimated storage per song',
      icon: Iconsax.chart_1,
      screen: const DownloadSettingsScreen(),
    ),
    // Backup & Restore
    _SearchableItem(
      tags: ['backup', 'export', 'save', 'file'],
      title: 'Create Backup',
      subtitle: 'Export your library and settings',
      icon: Iconsax.export_1,
      screen: const BackupRestoreScreen(),
    ),
    _SearchableItem(
      tags: ['restore', 'import', 'load', 'file'],
      title: 'Restore Backup',
      subtitle: 'Import a previous backup file',
      icon: Iconsax.import_1,
      screen: const BackupRestoreScreen(),
    ),
  ];

  // ── build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(ytMusicAuthStateProvider);

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: authState.isLoading
          ? Center(child: CircularProgressIndicator(color: _accentColor))
          : CustomScrollView(
              slivers: [
                // ── Collapsing App Bar ───────────────────────────────
                SliverAppBar.large(
                  expandedHeight: 120,
                  backgroundColor: _backgroundColor,
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Iconsax.arrow_left, color: _textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(color: _backgroundColor),
                    title: Text(
                      'Settings',
                      style: TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    titlePadding: const EdgeInsetsDirectional.only(
                      start: 56,
                      bottom: 16,
                    ),
                  ),
                ),

                // ── Search bar ───────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(child: _buildSearchBar()),
                ),

                // ── Body ─────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.list(
                    children: [
                      const SizedBox(height: 12),
                      if (authState.isLoggedIn)
                        ..._filteredSections(_loggedInSections(authState))
                      else
                        ..._filteredSections(_loggedOutSections()),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ── Search ─────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: _isDark
            ? Colors.white.withValues(alpha: 0.06)
            : _colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isDark
              ? MineColors.darkBorder
              : MineColors.border.withValues(alpha: 0.4),
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (value) =>
            setState(() => _searchQuery = value.toLowerCase()),
        style: TextStyle(fontSize: 14, color: _textPrimary),
        decoration: InputDecoration(
          hintText: 'Search settings…',
          hintStyle: TextStyle(fontSize: 14, color: _textTertiary),
          prefixIcon: Icon(
            Iconsax.search_normal,
            size: 18,
            color: _textTertiary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: _textTertiary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  /// Filter sections based on search query
  /// Each entry is a (tag, widget) pair; tags are keywords for filtering
  List<Widget> _filteredSections(List<_TaggedSection> tagged) {
    if (_searchQuery.isEmpty) {
      final widgets = <Widget>[];
      for (final t in tagged) {
        widgets.add(t.widget);
        widgets.add(const SizedBox(height: 20));
      }
      if (widgets.isNotEmpty) widgets.removeLast();
      return widgets;
    }

    // Search through main sections
    final matchedSections = tagged
        .where((t) => t.tags.any((tag) => tag.contains(_searchQuery)))
        .toList();

    // Search through deep-link items (Audio, Downloads, Backup settings)
    final matchedItems = _deepSearchItems
        .where((item) => item.tags.any((tag) => tag.contains(_searchQuery)))
        .toList();

    if (matchedSections.isEmpty && matchedItems.isEmpty) {
      return [
        const SizedBox(height: 40),
        Center(
          child: Column(
            children: [
              Icon(Iconsax.search_normal, size: 40, color: _textTertiary),
              const SizedBox(height: 12),
              Text(
                'No matching settings',
                style: TextStyle(color: _textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ];
    }

    final widgets = <Widget>[];

    // Add matched deep-link items first (more specific results)
    if (matchedItems.isNotEmpty) {
      widgets.add(_buildSearchResultsCard(matchedItems));
      if (matchedSections.isNotEmpty) widgets.add(const SizedBox(height: 20));
    }

    // Add matched main sections
    for (final t in matchedSections) {
      widgets.add(t.widget);
      widgets.add(const SizedBox(height: 20));
    }
    if (widgets.isNotEmpty && widgets.last is SizedBox) widgets.removeLast();
    return widgets;
  }

  /// Build a card showing search results from nested screens
  Widget _buildSearchResultsCard(List<_SearchableItem> items) {
    return _sectionCard(
      children: [
        _sectionHeader('Found in Settings', Iconsax.search_status),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _settingsTile(
                icon: item.icon,
                iconBg: _accentColor.withValues(alpha: 0.8),
                title: item.title,
                subtitle: item.subtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item.screen),
                ),
              ),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  color: _isDark ? MineColors.darkDivider : MineColors.divider,
                ),
            ],
          );
        }),
      ],
    );
  }

  // ── Section lists ──────────────────────────────────────────────────

  List<_TaggedSection> _loggedOutSections() => [
    _TaggedSection([
      'profile',
      'google',
      'account',
      'sign in',
    ], _buildGoogleAccountSection()),
    _TaggedSection([
      'youtube',
      'yt music',
      'connect',
      'login',
    ], _buildYTMusicConnectCard()),
    _TaggedSection([
      'appearance',
      'theme',
      'dark',
      'light',
      'mode',
    ], _buildAppearanceSection()),
    _TaggedSection([
      'audio',
      'streaming',
      'quality',
      'crossfade',
      'cache',
    ], _buildQuickActions()),
    _TaggedSection([
      'app',
      'info',
      'ota',
      'patch',
      'version',
      'update',
    ], _buildOtaDebugSection()),
  ];

  List<_TaggedSection> _loggedInSections(YTMusicAuthState authState) => [
    _TaggedSection([
      'profile',
      'google',
      'account',
      'sign in',
      'youtube',
      'yt music',
      'connected',
    ], _buildGoogleAccountSection(ytMusicAuth: authState)),
    _TaggedSection([
      'appearance',
      'theme',
      'dark',
      'light',
      'mode',
    ], _buildAppearanceSection()),
    _TaggedSection([
      'audio',
      'streaming',
      'quality',
      'crossfade',
      'download',
      'backup',
      'restore',
    ], _buildQuickActions()),
    _TaggedSection(['sync', 'refresh', 'library'], _buildSyncSection()),
    _TaggedSection([
      'library',
      'liked',
      'albums',
      'playlists',
      'artists',
    ], _buildLibraryStats()),
    _TaggedSection([
      'cache',
      'storage',
      'cleanup',
      'clear',
    ], _buildCacheSection()),
    _TaggedSection([
      'analytics',
      'hits',
      'misses',
      'network',
      'stats',
    ], _buildAnalyticsSection()),
    _TaggedSection([
      'app',
      'info',
      'ota',
      'patch',
      'version',
      'update',
    ], _buildOtaDebugSection()),
    _TaggedSection(['logout', 'disconnect', 'sign out'], _buildLogoutButton()),
  ];

  // ── Reusable card container ────────────────────────────────────────

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDark
              ? MineColors.darkBorder
              : (_hasAlbumColors
                    ? _accentColor.withValues(alpha: 0.15)
                    : MineColors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _accentColor),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ── YT Music Connect (logged-out) ─────────────────────────────────

  Widget _buildYTMusicConnectCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accentColor.withValues(alpha: 0.6),
            _accentColor.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accentColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.music, size: 32, color: _accentColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Connect YouTube Music',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sync your liked songs, playlists, and more',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _textSecondary),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _login,
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('Connect YT Music'),
            style: FilledButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: _colors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Appearance (Theme mode only — colors are dynamic from album art) ─

  Widget _buildAppearanceSection() {
    final currentThemeMode = ref.watch(themeModeProvider);

    return _sectionCard(
      children: [
        _sectionHeader('Appearance', Iconsax.brush_1),
        const SizedBox(height: 16),

        // Theme mode selector
        Text(
          'Theme',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: MineThemeMode.values.map((mode) {
            final selected = mode == currentThemeMode;
            final label = mode == MineThemeMode.system
                ? 'Auto'
                : mode == MineThemeMode.light
                ? 'Light'
                : 'Dark';
            final icon = mode == MineThemeMode.system
                ? Iconsax.autobrightness
                : mode == MineThemeMode.light
                ? Iconsax.sun_1
                : Iconsax.moon;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: mode != MineThemeMode.dark ? 8 : 0,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected
                        ? _accentColor.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? _accentColor.withValues(alpha: 0.4)
                          : (_isDark
                                ? MineColors.darkBorder
                                : MineColors.border),
                    ),
                  ),
                  child: InkWell(
                    onTap: () =>
                        ref.read(themeModeProvider.notifier).setThemeMode(mode),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Icon(
                            icon,
                            size: 20,
                            color: selected ? _accentColor : _textTertiary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: selected ? _accentColor : _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 14),

        // Dynamic color note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Iconsax.colorfilter, size: 18, color: _accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Colors adapt dynamically from the album art of the current track.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Quick Actions (Audio, Downloads, Backup) ──────────────────────

  Widget _buildQuickActions() {
    return _sectionCard(
      children: [
        _sectionHeader('Quick Actions', Iconsax.setting_2),
        const SizedBox(height: 12),
        _settingsTile(
          icon: Iconsax.music,
          iconBg: _accentColor,
          title: 'Audio',
          subtitle: 'Streaming quality, crossfade & playback',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AudioSettingsScreen()),
          ),
        ),
        Divider(
          height: 1,
          color: _isDark ? MineColors.darkDivider : MineColors.divider,
        ),
        _settingsTile(
          icon: Iconsax.document_download,
          iconBg: _colors.tertiary,
          title: 'Downloads',
          subtitle: 'Download quality, location & storage',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DownloadSettingsScreen()),
          ),
        ),
        Divider(
          height: 1,
          color: _isDark ? MineColors.darkDivider : MineColors.divider,
        ),
        _settingsTile(
          icon: Iconsax.document_upload,
          iconBg: _colors.secondary,
          title: 'Backup & Restore',
          subtitle: 'Export or import your library',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
          ),
        ),
      ],
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconBg, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: _textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: _textSecondary),
      ),
      trailing: Icon(Iconsax.arrow_right_3, size: 18, color: _textTertiary),
      onTap: onTap,
    );
  }

  // ── Google Account ─────────────────────────────────────────────────

  Widget _buildGoogleAccountSection({YTMusicAuthState? ytMusicAuth}) {
    final googleAuthState = ref.watch(googleAuthStateProvider);

    return _sectionCard(
      children: [
        _sectionHeader('Your Profile', Iconsax.user),
        const SizedBox(height: 16),
        if (googleAuthState.isLoading)
          Center(
            child: CircularProgressIndicator(
              color: _accentColor,
              strokeWidth: 2,
            ),
          )
        else if (googleAuthState.isSignedIn && googleAuthState.user != null)
          _buildGoogleSignedInRow(googleAuthState.user!)
        else
          _buildGoogleSignInButton(),
        // YT Music connected status (only show when logged in)
        if (ytMusicAuth != null && ytMusicAuth.isLoggedIn) ...[
          const SizedBox(height: 16),
          _buildYTMusicConnectedRow(ytMusicAuth),
        ],
      ],
    );
  }

  Widget _buildYTMusicConnectedRow(YTMusicAuthState authState) {
    final connectedColor = _isDark
        ? _accentColor
        : HSLColor.fromColor(_accentColor).withLightness(0.3).toColor();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isDark
            ? _accentColor.withValues(alpha: 0.08)
            : _accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accentColor, _accentColor.withValues(alpha: 0.7)],
              ),
              shape: BoxShape.circle,
            ),
            child: authState.account?.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      authState.account!.avatarUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(Iconsax.music, color: _colors.onPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YouTube Music',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  authState.account?.name ?? 'Connected',
                  style: TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Connected',
              style: TextStyle(
                color: connectedColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignedInRow(GoogleUserProfile user) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: user.photoUrl == null
                ? LinearGradient(
                    colors: [_accentColor, _accentColor.withValues(alpha: 0.6)],
                  )
                : null,
          ),
          child: ClipOval(
            child: user.photoUrl != null
                ? CachedNetworkImage(
                    imageUrl: user.photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Center(
                      child: Text(
                        user.initials,
                        style: TextStyle(
                          color: _colors.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Center(
                      child: Text(
                        user.initials,
                        style: TextStyle(
                          color: _colors.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      user.initials,
                      style: TextStyle(
                        color: _colors.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName ?? 'Google User',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              if (user.email != null)
                Text(
                  user.email!,
                  style: TextStyle(fontSize: 13, color: _textSecondary),
                ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Jams & profile',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () async {
            await ref.read(googleAuthStateProvider.notifier).signOut();
          },
          icon: Icon(Iconsax.logout, color: _textTertiary, size: 20),
          tooltip: 'Sign out',
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return Column(
      children: [
        Text(
          'Sign in with Google to get your profile picture and enable Jams',
          style: TextStyle(fontSize: 13, color: _textSecondary),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await ref.read(googleAuthStateProvider.notifier).signIn();
            },
            icon: Image.network(
              'https://www.google.com/favicon.ico',
              width: 18,
              height: 18,
              errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 18),
            ),
            label: const Text('Sign in with Google'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _textPrimary,
              side: BorderSide(
                color: _isDark ? MineColors.darkBorder : MineColors.border,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Sync Section ───────────────────────────────────────────────────

  Widget _buildSyncSection() {
    final syncService = ref.watch(ytMusicSyncServiceProvider);

    return _sectionCard(
      children: [
        _sectionHeader('Sync', Iconsax.refresh),
        const SizedBox(height: 12),
        if (syncService.lastSync != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Iconsax.clock, size: 14, color: _textTertiary),
                const SizedBox(width: 6),
                Text(
                  'Last synced: ${_formatDate(syncService.lastSync!)}',
                  style: TextStyle(color: _textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        if (_lastSyncResult != null && _lastSyncResult!.success)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: _accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Synced ${_lastSyncResult!.itemsSynced} items',
                      style: TextStyle(
                        color: _accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isSyncing ? null : _sync,
            icon: _isSyncing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _colors.onPrimary,
                    ),
                  )
                : const Icon(Iconsax.refresh, size: 18),
            label: Text(_isSyncing ? 'Syncing…' : 'Sync Now'),
            style: FilledButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: _colors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Cache Management ───────────────────────────────────────────────

  Widget _buildCacheSection() {
    final cacheManager = ref.watch(cacheManagementProvider);

    return _sectionCard(
      children: [
        _sectionHeader('Cache', Iconsax.cpu),
        const SizedBox(height: 12),
        FutureBuilder(
          future: cacheManager.getCacheStats(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final stats = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats.totalItemCount} cached items',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _cacheChip('Streams', stats.streamUrlsCount),
                        _cacheChip('Home', stats.homePageCount),
                        _cacheChip('Lyrics', stats.lyricsCount),
                        _cacheChip('Albums', stats.albumsCount),
                        _cacheChip('Artists', stats.artistsCount),
                        _cacheChip('Playlists', stats.playlistsCount),
                        _cacheChip('Colors', stats.colorsCount),
                        _cacheChip('Searches', stats.cachedSearchesCount),
                      ],
                    ),
                    if (stats.expiredEntriesCount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${stats.expiredEntriesCount} expired',
                        style: TextStyle(color: _textTertiary, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _accentColor,
                ),
              ),
            );
          },
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await cacheManager.cleanupExpiredCache();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Cache cleanup complete'),
                        backgroundColor: _colors.inverseSurface,
                      ),
                    );
                    setState(() {});
                  }
                },
                icon: Icon(Iconsax.refresh, size: 16, color: _accentColor),
                label: Text('Clean Up', style: TextStyle(color: _accentColor)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _accentColor.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear Cache'),
                      content: const Text(
                        'This will clear all cached music data. Continue?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(
                            'Clear',
                            style: TextStyle(color: _colors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await cacheManager.clearAllCache();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Cache cleared'),
                          backgroundColor: _colors.inverseSurface,
                        ),
                      );
                      setState(() {});
                    }
                  }
                },
                icon: Icon(Iconsax.trash, size: 16, color: _colors.error),
                label: Text(
                  'Clear All',
                  style: TextStyle(color: _colors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _colors.error.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cacheChip(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(
          fontSize: 12,
          color: _accentColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Cache Analytics ────────────────────────────────────────────────

  Widget _buildAnalyticsSection() {
    final analytics = ref.watch(cacheAnalyticsProvider);

    return _sectionCard(
      children: [
        _sectionHeader('Analytics', Iconsax.chart_2),
        const SizedBox(height: 14),
        // Hit rate progress indicator
        _buildHitRateIndicator(analytics.hitRate),
        const SizedBox(height: 16),
        Row(
          children: [
            _analyticsPill('Hits', analytics.cacheHits, _accentColor),
            const SizedBox(width: 8),
            _analyticsPill('Misses', analytics.cacheMisses, _colors.error),
            const SizedBox(width: 8),
            _analyticsPill('Network', analytics.networkCalls, _colors.tertiary),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () {
              analytics.reset();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Analytics reset'),
                  backgroundColor: _colors.inverseSurface,
                ),
              );
            },
            icon: Icon(Iconsax.refresh, size: 16, color: _textSecondary),
            label: Text(
              'Reset Stats',
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHitRateIndicator(double hitRate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cache Hit Rate',
              style: TextStyle(fontSize: 13, color: _textSecondary),
            ),
            Text(
              '${hitRate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: hitRate / 100,
            minHeight: 6,
            backgroundColor: _accentColor.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
          ),
        ),
      ],
    );
  }

  Widget _analyticsPill(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: _textSecondary)),
          ],
        ),
      ),
    );
  }

  // ── Library Stats ──────────────────────────────────────────────────

  Widget _buildLibraryStats() {
    final likedSongs = ref.watch(ytMusicLikedSongsProvider);
    final savedAlbums = ref.watch(ytMusicSavedAlbumsProvider);
    final savedPlaylists = ref.watch(ytMusicSavedPlaylistsProvider);
    final subscribedArtists = ref.watch(ytMusicSubscribedArtistsProvider);

    return _sectionCard(
      children: [
        _sectionHeader('Library', Iconsax.music_library_2),
        const SizedBox(height: 16),
        Row(
          children: [
            _libraryStat(
              Iconsax.heart5,
              'Liked',
              likedSongs.when(
                data: (s) => '${s.length}',
                loading: () => '…',
                error: (_, __) => '-',
              ),
            ),
            _libraryStat(
              Iconsax.music_square,
              'Albums',
              savedAlbums.when(
                data: (a) => '${a.length}',
                loading: () => '…',
                error: (_, __) => '-',
              ),
            ),
            _libraryStat(
              Iconsax.music_playlist,
              'Playlists',
              savedPlaylists.when(
                data: (p) => '${p.length}',
                loading: () => '…',
                error: (_, __) => '-',
              ),
            ),
            _libraryStat(
              Iconsax.user,
              'Artists',
              subscribedArtists.when(
                data: (a) => '${a.length}',
                loading: () => '…',
                error: (_, __) => '-',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _libraryStat(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: _accentColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: _textSecondary)),
        ],
      ),
    );
  }

  // ── OTA Debug ──────────────────────────────────────────────────────

  Widget _buildOtaDebugSection() {
    final updater = ShorebirdUpdater();

    return _sectionCard(
      children: [
        _sectionHeader('App Info', Iconsax.info_circle),
        const SizedBox(height: 12),
        _debugRow('Release build', kReleaseMode ? 'yes' : 'no'),
        _debugRow('Updater', updater.isAvailable ? 'available' : 'unavailable'),
        FutureBuilder<Patch?>(
          future: updater.readCurrentPatch(),
          builder: (context, snapshot) {
            final label = snapshot.connectionState == ConnectionState.waiting
                ? 'loading…'
                : snapshot.hasError
                ? 'error'
                : snapshot.data == null
                ? 'none'
                : '#${snapshot.data!.number}';
            return _debugRow('Current patch', label);
          },
        ),
        FutureBuilder<Patch?>(
          future: updater.readNextPatch(),
          builder: (context, snapshot) {
            final label = snapshot.connectionState == ConnectionState.waiting
                ? 'loading…'
                : snapshot.hasError
                ? 'error'
                : snapshot.data == null
                ? 'none'
                : '#${snapshot.data!.number}';
            return _debugRow('Next patch', label);
          },
        ),
      ],
    );
  }

  Widget _debugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: _textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Logout ─────────────────────────────────────────────────────────

  Widget _buildLogoutButton() {
    // Use a more visible error color for light mode
    final errorColor = _isDark ? _colors.error : const Color(0xFFC62828);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: Icon(Iconsax.logout, color: errorColor, size: 18),
        label: const Text('Disconnect YouTube Music'),
        style: OutlinedButton.styleFrom(
          foregroundColor: errorColor,
          side: BorderSide(color: errorColor.withValues(alpha: 0.5)),
          backgroundColor: errorColor.withValues(alpha: 0.08),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────

  Future<void> _login() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const YTMusicLoginScreen()),
    );

    if (result == true) {
      ref.invalidate(ytMusicLikedSongsProvider);
      ref.invalidate(ytMusicSavedAlbumsProvider);
      ref.invalidate(ytMusicSavedPlaylistsProvider);
      ref.invalidate(ytMusicSubscribedArtistsProvider);
    }
  }

  Future<void> _sync() async {
    setState(() => _isSyncing = true);

    final syncService = ref.read(ytMusicSyncServiceProvider);
    final result = await syncService.syncAll();

    setState(() {
      _isSyncing = false;
      _lastSyncResult = result;
    });

    if (result.success) {
      ref.invalidate(ytMusicLikedSongsProvider);
      ref.invalidate(ytMusicSavedAlbumsProvider);
      ref.invalidate(ytMusicSavedPlaylistsProvider);
      ref.invalidate(ytMusicSubscribedArtistsProvider);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: ${result.error}'),
          backgroundColor: _colors.error,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect YouTube Music?'),
        content: const Text(
          'This will remove your YouTube Music account from the app. Your library data will be cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _colors.error),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(ytMusicAuthStateProvider.notifier).logout();
      await ref.read(ytMusicSyncServiceProvider).clearCache();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

/// A section with search tags paired with its widget for filtering.
class _TaggedSection {
  final List<String> tags;
  final Widget widget;
  const _TaggedSection(this.tags, this.widget);
}

/// A deep-link searchable item that navigates to a specific screen.
class _SearchableItem {
  final List<String> tags;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;
  const _SearchableItem({
    required this.tags,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.screen,
  });
}
