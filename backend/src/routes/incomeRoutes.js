const express = require('express');
const router = express.Router();
const {
  getIncomes,
  createIncome,
  updateIncome,
  deleteIncome,
} = require('../controllers/incomeController');
const { protect } = require('../middleware/authMiddleware');
const { validateIncome } = require('../middleware/validationMiddleware');

router.use(protect);

router.get('/', getIncomes);
router.post('/', validateIncome, createIncome);
router.put('/:id', updateIncome);
router.delete('/:id', deleteIncome);

module.exports = router;
