const express = require('express');
const router = express.Router();
const {
  getExpenses,
  createExpense,
  updateExpense,
  deleteExpense,
  getDashboardMetrics,
  getReportsData,
} = require('../controllers/expenseController');
const { protect } = require('../middleware/authMiddleware');
const { validateExpense } = require('../middleware/validationMiddleware');
const upload = require('../utils/fileUpload');

router.use(protect);

// Specific subroutes first (to prevent conflict with :id param)
router.get('/dashboard', getDashboardMetrics);
router.get('/reports', getReportsData);

// Basic CRUD
router.get('/', getExpenses);
router.post('/', upload.single('receiptImage'), validateExpense, createExpense);
router.put('/:id', upload.single('receiptImage'), updateExpense);
router.delete('/:id', deleteExpense);

module.exports = router;
