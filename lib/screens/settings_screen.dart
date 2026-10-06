import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/theme_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/notification_provider.dart';
import '../services/hive_service.dart';
import '../theme/app_colors.dart';

/// Settings: profile, family, appearance, categories, data.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<List<Map<String, String>>>? _familyFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshFamilyPeers();
    });
  }

  void _refreshFamilyPeers() {
    final exp = Provider.of<ExpenseProvider>(context, listen: false);
    if (exp.isCloudMode) {
      setState(() => _familyFuture = exp.fetchFamilyPeerProfiles());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Settings',
                    style: Theme.of(context).textTheme.headlineLarge),
              ),
            ),
            SliverToBoxAdapter(child: _buildProfileSection(context, isDark)),
            SliverToBoxAdapter(child: _buildFamilySection(context, isDark)),
            SliverToBoxAdapter(child: _buildAppearanceSection(context, isDark)),
            SliverToBoxAdapter(child: _buildCategoriesSection(context, isDark)),
            SliverToBoxAdapter(child: _buildDataSection(context, isDark)),
            SliverToBoxAdapter(child: _buildAboutSection(context, isDark)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, bool isDark) {
    final auth = Provider.of<AuthProvider>(context);
    final email = auth.userEmail ?? 'Offline mode';
    final name = auth.userName ?? 'User';

    return _sectionCard(
      isDark,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    debugPrint('[SettingsScreen] Signing out...');
                    // Clear in-memory provider state
                    Provider.of<ExpenseProvider>(context, listen: false)
                        .clearLocalData();
                    Provider.of<BudgetProvider>(context, listen: false)
                        .clearLocalData();
                    Provider.of<NotificationProvider>(context, listen: false)
                        .clearLocalData();
                    // Close user-scoped Hive boxes
                    final hiveService = Provider.of<HiveService>(context, listen: false);
                    await hiveService.closeUserBoxes();
                    // Sign out from Supabase
                    await auth.signOut();
                    debugPrint('[SettingsScreen] Sign out complete');
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Sign out',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFamilySection(BuildContext context, bool isDark) {
    final exp = Provider.of<ExpenseProvider>(context);
    if (!exp.isCloudMode) return const SizedBox.shrink();

    if (_familyFuture == null) {
      return _sectionCard(
        isDark,
        title: 'Family',
        children: const [
          Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ],
      );
    }

    return _sectionCard(
      isDark,
      title: 'Family',
      children: [
        FutureBuilder<List<Map<String, String>>>(
          future: _familyFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            final peers = snap.data ?? [];
            if (peers.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'No family members yet.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Send an invite', style: TextStyle(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/limit_settings').then((_) => _refreshFamilyPeers());
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
            
            final peer = peers.first;
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.income.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.income.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.income),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You are in shared family expenses with ${peer['name'] ?? peer['email']}',
                          style: const TextStyle(
                            color: AppColors.income,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.link_off_rounded, size: 18),
                      label: const Text('Unlink Family', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.expense,
                        side: const BorderSide(color: AppColors.expense),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        await exp.unlinkFamily();
                        _refreshFamilyPeers();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(BuildContext context, bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return _sectionCard(isDark, title: 'Appearance', children: [
      SwitchListTile(
        title: const Text('Dark Mode'),
        subtitle: const Text('Toggle dark theme'),
        value: themeProvider.isDarkMode,
        onChanged: (_) => themeProvider.toggleTheme(),
        activeTrackColor: AppColors.primary,
        secondary: Icon(
          themeProvider.isDarkMode
              ? Icons.dark_mode_rounded
              : Icons.light_mode_rounded,
          color: AppColors.primary,
        ),
      ),
    ]);
  }

  Widget _buildCategoriesSection(BuildContext context, bool isDark) {
    final provider = Provider.of<ExpenseProvider>(context);
    return _sectionCard(
      isDark,
      title: 'Categories',
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_rounded, color: AppColors.primary),
          ),
          title: const Text('Add category'),
          subtitle: const Text('Create a new expense category'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showAddCategorySheet(context, provider),
        ),
        const Divider(height: 1),
        ...provider.categories.map((cat) {
          return ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(cat.colorValue).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                color: Color(cat.colorValue),
                size: 20,
              ),
            ),
            title: Text(cat.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.expense, size: 22),
              tooltip: 'Delete category',
              onPressed: () => _confirmDeleteCategory(context, provider, cat),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _showAddCategorySheet(
      BuildContext context, ExpenseProvider provider) async {
    final nameCtrl = TextEditingController();
    int colorIndex = 0;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              return Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New category',
                        style: Theme.of(ctx).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Category name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: AppColors.categoryColors.length,
                        itemBuilder: (_, i) {
                          return GestureDetector(
                            onTap: () => setModal(() => colorIndex = i),
                            child: Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppColors.categoryColors[i],
                                shape: BoxShape.circle,
                                border: colorIndex == i
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          if (provider.categoryExists(name)) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                  content: Text('That name is already used')),
                            );
                            return;
                          }
                          await provider.addCategory(
                            name: name,
                            iconCodePoint: Icons.category_rounded.codePoint,
                            colorValue: AppColors
                                .categoryColors[colorIndex]
                                .toARGB32(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Add category',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDataSection(BuildContext context, bool isDark) {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    return _sectionCard(isDark, title: 'Data', children: [
      ListTile(
        leading: const Icon(Icons.cloud_upload_rounded, color: AppColors.primary),
        title: const Text('Sync to Cloud'),
        subtitle: const Text('Supabase when signed in'),
        enabled: false,
      ),
      ListTile(
        leading: const Icon(Icons.delete_forever_rounded, color: AppColors.expense),
        title: const Text('Clear All Data'),
        subtitle: const Text('Delete all expenses permanently'),
        onTap: () => _confirmClearData(context, provider),
      ),
    ]);
  }

  Widget _buildAboutSection(BuildContext context, bool isDark) {
    return _sectionCard(isDark, title: 'About', children: const [
      ListTile(
        leading: Icon(Icons.info_outline_rounded, color: AppColors.primary),
        title: Text('Expense Tracker AI'),
        subtitle: Text('v1.0.0 • Made with Flutter'),
      ),
    ]);
  }

  Widget _sectionCard(bool isDark, {String? title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }

  void _confirmDeleteCategory(
    BuildContext context,
    ExpenseProvider provider,
    ExpenseCategory cat,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category permanently?'),
        content: Text(
          'Remove "${cat.name}" from your account? It will disappear from category pickers. '
          'Existing transactions will keep this label as plain text.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final err = await provider.deleteCategory(cat);
              if (!context.mounted) return;
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err)),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context, ExpenseProvider provider) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
            'This will permanently delete all your expenses. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final ids = provider.expenses.map((e) => e.id).toList();
              for (final id in ids) {
                provider.deleteExpense(id);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Clear All',
                style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}
