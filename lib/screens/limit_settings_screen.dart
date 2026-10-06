import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_colors.dart';
import '../core/constants.dart';
import '../widgets/budget/limit_tile.dart';

/// Settings screen for configuring spending limits.
class LimitSettingsScreen extends StatefulWidget {
  const LimitSettingsScreen({super.key});

  @override
  State<LimitSettingsScreen> createState() => _LimitSettingsScreenState();
}

class _LimitSettingsScreenState extends State<LimitSettingsScreen> {
  bool _familyMode = false;
  final TextEditingController _familyEmailCtrl = TextEditingController();
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
  void dispose() {
    _familyEmailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Spending Limits')),
      body: Consumer2<BudgetProvider, ExpenseProvider>(
        builder: (context, budgetP, expenseP, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Mode toggle
              _buildModeToggle(isDark),
              const SizedBox(height: 20),

              if (!_familyMode)
                _buildLimits(budgetP, expenseP, isDark, budgetP.personalLimits)
              else
                _buildFamilyContent(budgetP, expenseP, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLimits(BudgetProvider budgetP, ExpenseProvider expenseP, bool isDark, List<dynamic> limits) {
    final overallLimits = limits.where((l) => l.category == null).toList();
    final catLimits = limits.where((l) => l.category != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall limits section
        _sectionHeader('Overall Limits', isDark),
        const SizedBox(height: 8),
        ...overallLimits.map((l) => Dismissible(
          key: ValueKey(l.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDismiss(l.typeName),
          onDismissed: (_) => budgetP.deleteLimit(l.id),
          background: _dismissBackground(),
          child: LimitTile(
            title: l.typeName,
            type: l.type,
            amount: l.amount,
            isEnabled: l.isEnabled,
            isFamily: l.isFamily,
            onAmountChanged: (v) => budgetP.updateLimitAmount(l.id, v),
            onToggle: (v) => budgetP.setLimitEnabled(l.id, v),
            onDelete: () => budgetP.deleteLimit(l.id),
          ),
        )),
        _buildAddLimitButton('Add Overall Limit', null, budgetP),
        const SizedBox(height: 24),

        // Category limits section
        _sectionHeader('Category Limits', isDark),
        const SizedBox(height: 8),
        ...catLimits.map((l) {
          final catColor = Color(expenseP.getCategoryColor(l.category!));
          final catIcon = IconData(expenseP.getCategoryIcon(l.category!), fontFamily: 'MaterialIcons');
          return Dismissible(
            key: ValueKey(l.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _confirmDismiss(l.category!),
            onDismissed: (_) => budgetP.deleteLimit(l.id),
            background: _dismissBackground(),
            child: LimitTile(
              title: l.category!,
              type: l.type,
              amount: l.amount,
              isEnabled: l.isEnabled,
              isFamily: l.isFamily,
              color: catColor,
              icon: catIcon,
              onAmountChanged: (v) => budgetP.updateLimitAmount(l.id, v),
              onToggle: (v) => budgetP.setLimitEnabled(l.id, v),
              onDelete: () => budgetP.deleteLimit(l.id),
            ),
          );
        }),
        _buildAddCategoryLimitButton(budgetP, expenseP),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildFamilyContent(BudgetProvider budgetP, ExpenseProvider expenseP, bool isDark) {
    if (_familyFuture == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }
    return FutureBuilder<List<Map<String, String>>>(
      future: _familyFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
           return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        }
        final peers = snap.data ?? [];
        if (peers.isEmpty) {
           return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Center(
                   child: Padding(
                     padding: const EdgeInsets.only(bottom: 16),
                     child: Text('No family member yet.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                   ),
                 ),
                 _buildFamilyInvite(context, isDark),
              ]
           );
        }
        
        final peer = peers.first;
        return Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              _buildFamilyStatusBox(peer, context, expenseP, isDark),
              const SizedBox(height: 20),
              _buildLimits(budgetP, expenseP, isDark, budgetP.familyLimits),
           ]
        );
      }
    );
  }

  Widget _buildFamilyStatusBox(Map<String, String> peer, BuildContext context, ExpenseProvider expenseP, bool isDark) {
     return Container(
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
                         style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.w600, fontSize: 14),
                      )
                   )
                ]
             ),
             const SizedBox(height: 12),
             SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                   icon: const Icon(Icons.link_off_rounded, size: 18),
                   label: const Text('Unlink Family', style: TextStyle(fontWeight: FontWeight.w600)),
                   style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.expense,
                      side: const BorderSide(color: AppColors.expense),
                   ),
                   onPressed: () async {
                      await expenseP.unlinkFamily();
                      _refreshFamilyPeers();
                   }
                )
             )
          ]
       )
     );
  }

  Widget _dismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppColors.expense.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_rounded, color: AppColors.expense),
    );
  }

  Future<bool> _confirmDismiss(String limitName) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Limit'),
        content: Text('Remove the limit for "$limitName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildModeToggle(bool isDark) {
    const labels = ['Personal', 'Family'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: List.generate(2, (i) {
          final active = (_familyMode ? 1 : 0) == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _familyMode = i == 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFamilyInvite(BuildContext context, bool isDark) {
    return Consumer<NotificationProvider>(
      builder: (context, notifP, _) {
        final pending = notifP.pendingFamilyInviteEmails;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.group_add_rounded, color: AppColors.secondary, size: 22),
                const SizedBox(width: 10),
                Text('Invite family member', style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: _familyEmailCtrl,
                decoration: const InputDecoration(
                  hintText: 'Enter member email',
                  prefixIcon: Icon(Icons.email_outlined, size: 20)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _sendInvite(context, _familyEmailCtrl.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Send invite', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              if (pending.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Pending on this device', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: pending.map((e) => InputChip(
                    label: Text(e, style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close_rounded, size: 16),
                    onDeleted: () => notifP.removePendingFamilyInvite(e),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendInvite(BuildContext context, String email) async {
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')));
      return;
    }

    final notifP = Provider.of<NotificationProvider>(context, listen: false);

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking user...'), duration: Duration(seconds: 1)));

    final result = await notifP.sendFamilyInvite(email);

    if (!context.mounted) return;

    if (result == 'sent') {
      _familyEmailCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Approval request sent to $email ✅'),
        backgroundColor: AppColors.income));
    } else if (result == 'not_found') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('❌ This email has no account yet'),
        backgroundColor: AppColors.expense));
    } else if (result == 'self_invite') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('❌ You cannot invite yourself'),
        backgroundColor: AppColors.expense));
    } else if (result == 'already_sent') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You already have a pending invite to this email on this device.'),
        backgroundColor: AppColors.warning));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error sending invite'),
        backgroundColor: AppColors.expense));
    }
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Text(title, style: TextStyle(
      fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5,
      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary));
  }

  Widget _buildAddLimitButton(String label, String? category, BudgetProvider budgetP) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: OutlinedButton.icon(
        onPressed: () => _showAddLimitDialog(category, budgetP),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
    );
  }

  Widget _buildAddCategoryLimitButton(BudgetProvider budgetP, ExpenseProvider expenseP) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: OutlinedButton.icon(
        onPressed: () => _showCategoryLimitDialog(budgetP, expenseP),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add Category Limit'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
    );
  }

  void _showAddLimitDialog(String? category, BudgetProvider budgetP) {
    int selectedType = LimitType.monthly;
    final amtCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(category != null ? 'Add $category Limit' : 'Add Overall Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _periodToggle(selectedType, (v) => setDialogState(() => selectedType = v)),
            const SizedBox(height: 16),
            TextField(
              controller: amtCtrl,
              decoration: const InputDecoration(labelText: 'Amount (৳)', prefixText: '৳ '),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text);
              if (amt != null && amt > 0) {
                Navigator.pop(ctx);
                budgetP.addLimit(
                  type: selectedType, amount: amt,
                  category: category, isFamily: _familyMode);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    ));
  }

  void _showCategoryLimitDialog(BudgetProvider budgetP, ExpenseProvider expenseP) {
    String? selectedCat;
    int selectedType = LimitType.monthly;
    final amtCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Add Category Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedCat,
              decoration: const InputDecoration(labelText: 'Category'),
              items: expenseP.categories.map((c) => DropdownMenuItem(
                value: c.name, child: Text(c.name))).toList(),
              onChanged: (v) => setDialogState(() => selectedCat = v),
            ),
            const SizedBox(height: 12),
            _periodToggle(selectedType, (v) => setDialogState(() => selectedType = v)),
            const SizedBox(height: 12),
            TextField(
              controller: amtCtrl,
              decoration: const InputDecoration(labelText: 'Amount (৳)', prefixText: '৳ '),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text);
              if (amt != null && amt > 0 && selectedCat != null) {
                Navigator.pop(ctx);
                budgetP.addLimit(
                  type: selectedType, amount: amt,
                  category: selectedCat, isFamily: _familyMode);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    ));
  }

  /// Custom compact period toggle that never wraps text.
  Widget _periodToggle(int selected, ValueChanged<int> onChanged) {
    const labels = ['Daily', 'Weekly', 'Monthly'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isActive
                      ? [BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )]
                      : null,
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
