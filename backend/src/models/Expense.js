const mongoose = require('mongoose');

const ExpenseSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  title: {
    type: String,
    required: [true, 'Please add an expense title'],
    trim: true,
  },
  amount: {
    type: Number,
    required: [true, 'Please add an expense amount'],
  },
  category: {
    type: String,
    required: [true, 'Please select a category'],
    enum: [
      'Food',
      'Shopping',
      'Bills',
      'Travel',
      'Education',
      'Entertainment',
      'Health',
      'Others',
    ],
  },
  paymentMethod: {
    type: String,
    required: [true, 'Please select a payment method'],
    enum: ['Cash', 'Card', 'Bank Transfer', 'Other'],
    default: 'Cash',
  },
  notes: {
    type: String,
    default: '',
    trim: true,
  },
  receiptImage: {
    type: String,
    default: '',
  },
  date: {
    type: Date,
    required: [true, 'Please add a date'],
    default: Date.now,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Expense', ExpenseSchema);
