const Income = require('../models/Income');

// @desc    Get all incomes for user
// @route   GET /api/income
// @access  Private
const getIncomes = async (req, res, next) => {
  try {
    const incomes = await Income.find({ userId: req.user.id }).sort({ date: -1 });
    res.status(200).json({ success: true, count: incomes.length, data: incomes });
  } catch (error) {
    next(error);
  }
};

// @desc    Create income
// @route   POST /api/income
// @access  Private
const createIncome = async (req, res, next) => {
  try {
    const { title, amount, notes, date } = req.body;

    const income = await Income.create({
      userId: req.user.id,
      title,
      amount,
      notes,
      date: date ? new Date(date) : new Date(),
    });

    res.status(201).json({ success: true, data: income });
  } catch (error) {
    next(error);
  }
};

// @desc    Update income
// @route   PUT /api/income/:id
// @access  Private
const updateIncome = async (req, res, next) => {
  try {
    let income = await Income.findById(req.params.id);

    if (!income) {
      return res.status(404).json({ success: false, message: 'Income record not found' });
    }

    // Make sure user owns income record
    if (income.userId.toString() !== req.user.id) {
      return res.status(401).json({ success: false, message: 'Not authorized to edit this income' });
    }

    const { title, amount, notes, date } = req.body;
    const updateData = {};
    if (title) updateData.title = title;
    if (amount !== undefined) updateData.amount = amount;
    if (notes !== undefined) updateData.notes = notes;
    if (date) updateData.date = new Date(date);

    income = await Income.findByIdAndUpdate(req.params.id, updateData, {
      new: true,
      runValidators: true,
    });

    res.status(200).json({ success: true, data: income });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete income
// @route   DELETE /api/income/:id
// @access  Private
const deleteIncome = async (req, res, next) => {
  try {
    const income = await Income.findById(req.params.id);

    if (!income) {
      return res.status(404).json({ success: false, message: 'Income record not found' });
    }

    // Make sure user owns income record
    if (income.userId.toString() !== req.user.id) {
      return res.status(401).json({ success: false, message: 'Not authorized to delete this income' });
    }

    await income.deleteOne();

    res.status(200).json({ success: true, data: {} });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getIncomes,
  createIncome,
  updateIncome,
  deleteIncome,
};
