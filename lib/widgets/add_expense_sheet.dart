import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/expense_provider.dart';
import '../theme/app_colors.dart';
import 'category_chip.dart';

/// Modern bottom sheet for adding new expenses or income.
class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isIncome = false;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _showNewCategory = false;
  final _newCatNameController = TextEditingController();
  int _selectedColorIndex = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _newCatNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<ExpenseProvider>(context);
    final categories = provider.categories;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Add Transaction',
                  style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // Income/Expense Toggle
                _buildTypeToggle(isDark),
                const SizedBox(height: 20),

                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.edit_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter a title' : null,
                ),
                const SizedBox(height: 14),

                // Amount field
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount (৳)',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('৳',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 44),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter amount';
                    if (double.tryParse(v) == null) return 'Invalid amount';
                    if (double.parse(v) <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Category selector
                Text('Category', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                )),
                const SizedBox(height: 10),
                _buildCategorySelector(categories, isDark),
                const SizedBox(height: 16),

                // Date picker
                _buildDatePicker(isDark),
                const SizedBox(height: 14),

                // Note field
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    prefixIcon: Icon(Icons.note_rounded),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 28),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => _submit(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isIncome ? AppColors.income : AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 4,
                      shadowColor: (_isIncome ? AppColors.income : AppColors.primary)
                          .withValues(alpha: 0.4),
                    ),
                    child: Text(
                      _isIncome ? 'Add Income' : 'Add Expense',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _toggleButton('Expense', !_isIncome, AppColors.expense, () {
            setState(() => _isIncome = false);
          })),
          Expanded(child: _toggleButton('Income', _isIncome, AppColors.income, () {
            setState(() => _isIncome = true);
          })),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool active, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: active ? Colors.white : color,
          )),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(List<ExpenseCategory> categories, bool isDark) {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CategoryChip(
                  label: cat.name,
                  icon: IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: Color(cat.colorValue),
                  isSelected: _selectedCategory == cat.name,
                  onTap: () => setState(() => _selectedCategory = cat.name),
                ),
              )),
              // Add new category button
              GestureDetector(
                onTap: () => setState(() => _showNewCategory = !_showNewCategory),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('New', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_showNewCategory) ...[
          const SizedBox(height: 12),
          _buildNewCategoryForm(isDark),
        ],
      ],
    );
  }

  Widget _buildNewCategoryForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          TextField(
            controller: _newCatNameController,
            decoration: const InputDecoration(
              hintText: 'Category name',
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: AppColors.categoryColors.length,
              itemBuilder: (ctx, i) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = i),
                  child: Container(
                    width: 32, height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.categoryColors[i],
                      shape: BoxShape.circle,
                      border: _selectedColorIndex == i
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: _selectedColorIndex == i
                          ? [BoxShadow(
                              color: AppColors.categoryColors[i].withValues(alpha: 0.5),
                              blurRadius: 8,
                            )]
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addNewCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Add Category'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(bool isDark) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 20),
            const SizedBox(width: 12),
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_drop_down_rounded,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ],
        ),
      ),
    );
  }

  void _addNewCategory() {
    final name = _newCatNameController.text.trim();
    if (name.isEmpty) return;

    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    if (provider.categoryExists(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category already exists')),
      );
      return;
    }

    provider.addCategory(
      name: name,
      iconCodePoint: Icons.category_rounded.codePoint,
      colorValue: AppColors.categoryColors[_selectedColorIndex].toARGB32(),
    );

    setState(() {
      _selectedCategory = name;
      _showNewCategory = false;
      _newCatNameController.clear();
    });
  }

  void _submit(ExpenseProvider provider) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    provider.addExpense(
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text),
      category: _selectedCategory!,
      date: _selectedDate,
      isIncome: _isIncome,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    Navigator.pop(context);
  }
}
