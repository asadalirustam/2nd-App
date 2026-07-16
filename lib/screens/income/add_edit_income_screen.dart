import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/transaction_provider.dart';
import '../../config/theme.dart';


class AddEditIncomeScreen extends StatefulWidget {
  final String? incomeId;
  final String? prefilledTitle;
  final double? prefilledAmount;
  final DateTime? prefilledDate;

  const AddEditIncomeScreen({
    super.key,
    this.incomeId,
    this.prefilledTitle,
    this.prefilledAmount,
    this.prefilledDate,
  });

  @override
  State<AddEditIncomeScreen> createState() => _AddEditIncomeScreenState();
}

class _AddEditIncomeScreenState extends State<AddEditIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  final _notesController = TextEditingController();
  
  late DateTime _selectedDate;

  bool get isEditMode => widget.incomeId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.prefilledTitle ?? '');
    _amountController = TextEditingController(text: widget.prefilledAmount != null ? widget.prefilledAmount.toString() : '');
    _selectedDate = widget.prefilledDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final transProvider = Provider.of<TransactionProvider>(context, listen: false);
    final amt = double.parse(_amountController.text.trim());

    try {
      if (isEditMode) {
        await transProvider.editIncome(
          id: widget.incomeId!,
          title: _titleController.text.trim(),
          amount: amt,
          notes: _notesController.text.trim(),
          date: _selectedDate,
        );
      } else {
        await transProvider.addIncome(
          title: _titleController.text.trim(),
          amount: amt,
          notes: _notesController.text.trim(),
          date: _selectedDate,
        );
      }

      Fluttertoast.showToast(
        msg: isEditMode ? "Income updated!" : "Income added!",
        backgroundColor: Colors.green,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to save: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  void _onDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Delete this income record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Provider.of<TransactionProvider>(context, listen: false)
                    .deleteIncome(widget.incomeId!);
                if (!context.mounted) return;
                Navigator.pop(context);
              } catch (e) {
                Fluttertoast.showToast(msg: e.toString());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Income' : 'Add Income'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _onDelete,
            ),
        ],
      ),
      body: transProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: 'Income amount',
                        prefixIcon: Icon(Icons.monetization_on_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Enter a valid positive number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Source (e.g. Salary, Freelance)',
                        prefixIcon: Icon(Icons.text_fields_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a source';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Date Selection
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: theme.inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    color: theme.colorScheme.onBackground.withOpacity(0.5)),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            Icon(Icons.edit_calendar_outlined, color: theme.colorScheme.success),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Additional notes...',
                        prefixIcon: Icon(Icons.notes_rounded),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Save Button
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.success,
                      ),
                      child: Text(isEditMode ? 'Update Record' : 'Save Record'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
