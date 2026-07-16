const Expense = require('../models/Expense');
const Income = require('../models/Income');
const fs = require('fs');
const path = require('path');

// Helper to delete a file safely
const deleteFile = (relativePath) => {
  if (!relativePath || relativePath.startsWith('http')) return;
  const filePath = path.join(__dirname, '../../', relativePath);
  if (fs.existsSync(filePath)) {
    try {
      fs.unlinkSync(filePath);
    } catch (err) {
      console.error(`Failed to delete file: ${filePath}`, err);
    }
  }
};

// @desc    Get all expenses with searching and filtering
// @route   GET /api/expenses
// @access  Private
const getExpenses = async (req, res, next) => {
  try {
    const { search, category, startDate, endDate, paymentMethod } = req.query;

    const query = { userId: req.user.id };

    // Search filter (matches title or notes)
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { notes: { $regex: search, $options: 'i' } },
      ];
    }

    // Category filter
    if (category) {
      query.category = category;
    }

    // Payment method filter
    if (paymentMethod) {
      query.paymentMethod = paymentMethod;
    }

    // Date range filter
    if (startDate || endDate) {
      query.date = {};
      if (startDate) {
        query.date.$gte = new Date(startDate);
      }
      if (endDate) {
        query.date.$lte = new Date(endDate);
      }
    }

    const expenses = await Expense.find(query).sort({ date: -1 });
    res.status(200).json({ success: true, count: expenses.length, data: expenses });
  } catch (error) {
    next(error);
  }
};

// @desc    Create expense
// @route   POST /api/expenses
// @access  Private
const createExpense = async (req, res, next) => {
  try {
    const { title, amount, category, paymentMethod, notes, date } = req.body;

    let receiptImage = '';
    if (req.file) {
      receiptImage = 'uploads/' + req.file.filename;
    }

    const expense = await Expense.create({
      userId: req.user.id,
      title,
      amount: Number(amount),
      category,
      paymentMethod: paymentMethod || 'Cash',
      notes: notes || '',
      date: date ? new Date(date) : new Date(),
      receiptImage,
    });

    res.status(201).json({ success: true, data: expense });
  } catch (error) {
    // If saving fails, delete the uploaded file if exists
    if (req.file) {
      deleteFile('uploads/' + req.file.filename);
    }
    next(error);
  }
};

// @desc    Update expense
// @route   PUT /api/expenses/:id
// @access  Private
const updateExpense = async (req, res, next) => {
  try {
    let expense = await Expense.findById(req.params.id);

    if (!expense) {
      if (req.file) deleteFile('uploads/' + req.file.filename);
      return res.status(404).json({ success: false, message: 'Expense not found' });
    }

    // Make sure user owns expense
    if (expense.userId.toString() !== req.user.id) {
      if (req.file) deleteFile('uploads/' + req.file.filename);
      return res.status(401).json({ success: false, message: 'Not authorized to edit this expense' });
    }

    const { title, amount, category, paymentMethod, notes, date, removeReceipt } = req.body;
    const updateData = {};
    if (title) updateData.title = title;
    if (amount !== undefined) updateData.amount = Number(amount);
    if (category) updateData.category = category;
    if (paymentMethod) updateData.paymentMethod = paymentMethod;
    if (notes !== undefined) updateData.notes = notes;
    if (date) updateData.date = new Date(date);

    // Handle receipt image replacement
    if (req.file) {
      // Delete old file
      if (expense.receiptImage) {
        deleteFile(expense.receiptImage);
      }
      updateData.receiptImage = 'uploads/' + req.file.filename;
    } else if (removeReceipt === 'true' || removeReceipt === true) {
      if (expense.receiptImage) {
        deleteFile(expense.receiptImage);
      }
      updateData.receiptImage = '';
    }

    expense = await Expense.findByIdAndUpdate(req.params.id, updateData, {
      new: true,
      runValidators: true,
    });

    res.status(200).json({ success: true, data: expense });
  } catch (error) {
    if (req.file) deleteFile('uploads/' + req.file.filename);
    next(error);
  }
};

// @desc    Delete expense
// @route   DELETE /api/expenses/:id
// @access  Private
const deleteExpense = async (req, res, next) => {
  try {
    const expense = await Expense.findById(req.params.id);

    if (!expense) {
      return res.status(404).json({ success: false, message: 'Expense not found' });
    }

    // Make sure user owns expense
    if (expense.userId.toString() !== req.user.id) {
      return res.status(401).json({ success: false, message: 'Not authorized to delete this expense' });
    }

    // Delete receipt image file if exists
    if (expense.receiptImage) {
      deleteFile(expense.receiptImage);
    }

    await expense.deleteOne();

    res.status(200).json({ success: true, data: {} });
  } catch (error) {
    next(error);
  }
};

// @desc    Get dashboard metrics (Totals, summary cards, recent transactions)
// @route   GET /api/expenses/dashboard
// @access  Private
const getDashboardMetrics = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const now = new Date();
    
    // Current month range
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);

    // 1. Run queries in parallel
    const [
      allExpenses,
      allIncomes,
      monthlyExpenses,
      monthlyIncomes,
      recentExpenses,
      recentIncomes,
    ] = await Promise.all([
      Expense.find({ userId }),
      Income.find({ userId }),
      Expense.find({ userId, date: { $gte: startOfMonth, $lte: endOfMonth } }),
      Income.find({ userId, date: { $gte: startOfMonth, $lte: endOfMonth } }),
      Expense.find({ userId }).sort({ date: -1 }).limit(5),
      Income.find({ userId }).sort({ date: -1 }).limit(5),
    ]);

    // Totals calculations
    const totalIncome = allIncomes.reduce((sum, item) => sum + item.amount, 0);
    const totalExpense = allExpenses.reduce((sum, item) => sum + item.amount, 0);
    const totalBalance = totalIncome - totalExpense;

    const currentMonthIncome = monthlyIncomes.reduce((sum, item) => sum + item.amount, 0);
    const currentMonthExpense = monthlyExpenses.reduce((sum, item) => sum + item.amount, 0);
    const currentMonthSavings = Math.max(0, currentMonthIncome - currentMonthExpense);

    // Combine recent activities and sort by date descending
    const recentActivities = [
      ...recentExpenses.map(e => ({
        id: e._id,
        title: e.title,
        amount: e.amount,
        type: 'expense',
        category: e.category,
        date: e.date,
      })),
      ...recentIncomes.map(i => ({
        id: i._id,
        title: i.title,
        amount: i.amount,
        type: 'income',
        category: 'Income',
        date: i.date,
      })),
    ]
      .sort((a, b) => b.date - a.date)
      .slice(0, 5);

    // Category Summary (for the current month)
    const categoryTotals = {};
    monthlyExpenses.forEach(exp => {
      categoryTotals[exp.category] = (categoryTotals[exp.category] || 0) + exp.amount;
    });

    const categorySummary = Object.keys(categoryTotals).map(cat => ({
      category: cat,
      amount: categoryTotals[cat],
      percentage: currentMonthExpense > 0 ? Math.round((categoryTotals[cat] / currentMonthExpense) * 100) : 0,
    })).sort((a, b) => b.amount - a.amount);

    res.status(200).json({
      success: true,
      data: {
        totalBalance,
        totalIncome,
        totalExpense,
        currentMonthIncome,
        currentMonthExpense,
        currentMonthSavings,
        recentTransactions: recentActivities,
        categorySummary,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get reports data (Daily, Weekly, Monthly, Yearly summaries & category splits)
// @route   GET /api/expenses/reports
// @access  Private
const getReportsData = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { period } = req.query; // 'daily' | 'weekly' | 'monthly' | 'yearly'
    
    const now = new Date();
    let startDate;

    if (period === 'daily') {
      // Last 7 days
      startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 7);
    } else if (period === 'weekly') {
      // Last 4 weeks
      startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 28);
    } else if (period === 'yearly') {
      // Last 5 years
      startDate = new Date(now.getFullYear() - 5, 0, 1);
    } else {
      // 'monthly' (Default): Last 12 months
      startDate = new Date(now.getFullYear(), now.getMonth() - 11, 1);
    }

    const [expenses, incomes] = await Promise.all([
      Expense.find({ userId, date: { $gte: startDate } }).sort({ date: 1 }),
      Income.find({ userId, date: { $gte: startDate } }).sort({ date: 1 }),
    ]);

    // Calculate Category Summary for the period
    const categoryTotals = {};
    let totalExpenseAmount = 0;
    expenses.forEach(exp => {
      categoryTotals[exp.category] = (categoryTotals[exp.category] || 0) + exp.amount;
      totalExpenseAmount += exp.amount;
    });

    const categoryWiseSplit = Object.keys(categoryTotals).map(cat => ({
      category: cat,
      amount: categoryTotals[cat],
      percentage: totalExpenseAmount > 0 ? Math.round((categoryTotals[cat] / totalExpenseAmount) * 100) : 0,
    })).sort((a, b) => b.amount - a.amount);

    // Grouping by interval for Income vs Expense graph points
    const chartData = {};

    expenses.forEach(e => {
      const label = getPeriodLabel(e.date, period);
      if (!chartData[label]) chartData[label] = { label, income: 0, expense: 0 };
      chartData[label].expense += e.amount;
    });

    incomes.forEach(i => {
      const label = getPeriodLabel(i.date, period);
      if (!chartData[label]) chartData[label] = { label, income: 0, expense: 0 };
      chartData[label].income += i.amount;
    });

    // Format chart data back to a sorted list
    const chartPoints = Object.values(chartData).sort((a, b) => {
      if (period === 'monthly') {
        return new Date(a.label + '-01') - new Date(b.label + '-01');
      }
      return a.label.localeCompare(b.label);
    });

    res.status(200).json({
      success: true,
      data: {
        totalExpense: totalExpenseAmount,
        totalIncome: incomes.reduce((sum, item) => sum + item.amount, 0),
        categoryWiseExpenses: categoryWiseSplit,
        chartData: chartPoints,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Helper for grouping label formatting
function getPeriodLabel(dateObj, period) {
  const d = new Date(dateObj);
  if (period === 'daily') {
    // Return MM-DD
    return `${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  } else if (period === 'weekly') {
    // Return "Wk X - YYYY"
    const oneJan = new Date(d.getFullYear(), 0, 1);
    const numberOfDays = Math.floor((d - oneJan) / (24 * 60 * 60 * 1000));
    const weekNum = Math.ceil((d.getDay() + 1 + numberOfDays) / 7);
    return `Wk ${weekNum}`;
  } else if (period === 'yearly') {
    // Return YYYY
    return `${d.getFullYear()}`;
  } else {
    // Default 'monthly': Return YYYY-MM
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
  }
}

module.exports = {
  getExpenses,
  createExpense,
  updateExpense,
  deleteExpense,
  getDashboardMetrics,
  getReportsData,
};
