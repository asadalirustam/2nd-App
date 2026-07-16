const validateSignup = (req, res, next) => {
  const { name, email, password } = req.body;
  if (!name || !name.trim()) {
    return res.status(400).json({ success: false, message: 'Name is required' });
  }
  if (!email || !email.trim()) {
    return res.status(400).json({ success: false, message: 'Email is required' });
  }
  const emailRegex = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({ success: false, message: 'Please add a valid email' });
  }
  if (!password || password.length < 6) {
    return res.status(400).json({ success: false, message: 'Password must be at least 6 characters' });
  }
  next();
};

const validateLogin = (req, res, next) => {
  const { email, password } = req.body;
  if (!email || !email.trim()) {
    return res.status(400).json({ success: false, message: 'Email is required' });
  }
  if (!password) {
    return res.status(400).json({ success: false, message: 'Password is required' });
  }
  next();
};

const validateExpense = (req, res, next) => {
  const { title, amount, category, date } = req.body;
  if (!title || !title.trim()) {
    return res.status(400).json({ success: false, message: 'Title is required' });
  }
  if (amount === undefined || amount === null || isNaN(amount) || amount <= 0) {
    return res.status(400).json({ success: false, message: 'Amount must be a positive number' });
  }
  if (!category || !category.trim()) {
    return res.status(400).json({ success: false, message: 'Category is required' });
  }
  const validCategories = [
    'Food',
    'Shopping',
    'Bills',
    'Travel',
    'Education',
    'Entertainment',
    'Health',
    'Others',
  ];
  if (!validCategories.includes(category)) {
    return res.status(400).json({ success: false, message: `Category must be one of: ${validCategories.join(', ')}` });
  }
  if (!date) {
    return res.status(400).json({ success: false, message: 'Date is required' });
  }
  next();
};

const validateIncome = (req, res, next) => {
  const { title, amount, date } = req.body;
  if (!title || !title.trim()) {
    return res.status(400).json({ success: false, message: 'Title is required' });
  }
  if (amount === undefined || amount === null || isNaN(amount) || amount <= 0) {
    return res.status(400).json({ success: false, message: 'Amount must be a positive number' });
  }
  if (!date) {
    return res.status(400).json({ success: false, message: 'Date is required' });
  }
  next();
};

module.exports = {
  validateSignup,
  validateLogin,
  validateExpense,
  validateIncome,
};
