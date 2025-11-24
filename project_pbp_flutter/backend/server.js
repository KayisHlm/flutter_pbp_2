const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();
const bcrypt = require('bcryptjs');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// In-memory database
let users = []; // Debtors/users for hutang system
let hutangs = [];
let authUsers = []; // Authentication users

// Simple session management - store logged in user IDs
let activeSessions = new Set();

// Authentication middleware (simple user ID based)
const requireAuth = (req, res, next) => {
  const userId = req.headers['x-user-id'];
  
  if (!userId || !activeSessions.has(userId)) {
    return res.status(401).json({
      success: false,
      message: 'Authentication required. Please login first.'
    });
  }
  
  const user = authUsers.find(u => u.id === userId);
  if (!user) {
    return res.status(401).json({
      success: false,
      message: 'User not found'
    });
  }
  
  req.user = user;
  next();
};

// Auth Routes
app.post('/api/auth/register', async (req, res) => {
  try {
    const { username, email, password, name } = req.body;
    
    if (!username || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Username, email, and password are required'
      });
    }

    // Check if user already exists
    const existingUser = authUsers.find(u => u.email === email || u.username === username);
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'User already exists with this email or username'
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = {
      id: uuidv4(),
      username,
      email,
      password: hashedPassword,
      name: name || username,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    authUsers.push(newUser);
    
    // Don't return password
    const { password: _, ...userWithoutPassword } = newUser;
    
    res.status(201).json({
      success: true,
      data: userWithoutPassword,
      message: 'User registered successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error registering user',
      error: error.message
    });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    if (!username || !password) {
      return res.status(400).json({
        success: false,
        message: 'Username and password are required'
      });
    }

    // Find user by username or email
    const user = authUsers.find(u => u.username === username || u.email === username);
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Add to active sessions
    activeSessions.add(user.id);
    
    // Don't return password
    const { password: _, ...userWithoutPassword } = user;
    
    res.json({
      success: true,
      data: {
        user: userWithoutPassword,
        userId: user.id // Return user ID for subsequent requests
      },
      message: 'Login successful'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error logging in',
      error: error.message
    });
  }
});

app.post('/api/auth/logout', requireAuth, (req, res) => {
  try {
    // Remove from active sessions
    activeSessions.delete(req.user.id);
    
    res.json({
      success: true,
      message: 'Logout successful'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error logging out',
      error: error.message
    });
  }
});

app.get('/api/auth/me', requireAuth, (req, res) => {
  try {
    const { password: _, ...userWithoutPassword } = req.user;
    res.json({
      success: true,
      data: userWithoutPassword,
      message: 'User profile retrieved successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error retrieving user profile',
      error: error.message
    });
  }
});

// Users API (now require authentication)
app.get('/api/users', requireAuth, function(req, res) {
  try {
    const usersWithHutangSummary = users.map(user => {
      const userHutangs = hutangs.filter(hutang => hutang.debtorId === user.id && hutang.status !== 'paid');
      const totalHutang = userHutangs.reduce((sum, hutang) => sum + hutang.remainingAmount, 0);
      const jumlahHutang = userHutangs.length;
      
      return {
        ...user,
        totalHutang,
        jumlahHutang
      };
    });
    
    res.json({
      success: true,
      data: usersWithHutangSummary,
      message: 'Users retrieved successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error retrieving users',
      error: error.message
    });
  }
});

app.get('/api/users/:id', requireAuth, function(req, res) {
  try {
    const user = users.find(u => u.id === req.params.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const userHutangs = hutangs.filter(hutang => hutang.debtorId === user.id);
    const totalHutang = userHutangs
      .filter(hutang => hutang.status !== 'paid')
      .reduce((sum, hutang) => sum + hutang.remainingAmount, 0);
    const jumlahHutang = userHutangs.filter(hutang => hutang.status !== 'paid').length;
    
    res.json({
      success: true,
      data: {
        ...user,
        totalHutang,
        jumlahHutang,
        hutangs: userHutangs
      },
      message: 'User retrieved successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error retrieving user',
      error: error.message
    });
  }
});

app.post('/api/users', requireAuth, function(req, res) {
  try {
    const { name, phone, address, photoUrl } = req.body;
    
    if (!name) {
      return res.status(400).json({
        success: false,
        message: 'Name is required'
      });
    }

    const newUser = {
      id: uuidv4(),
      name,
      phone: phone || null,
      address: address || null,
      photoUrl: photoUrl || null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    users.push(newUser);
    
    res.status(201).json({
      success: true,
      data: newUser,
      message: 'User created successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error creating user',
      error: error.message
    });
  }
});

// Hutangs API (now require authentication)
app.get('/api/hutangs', requireAuth, function(req, res) {
  try {
    const hutangsWithDebtor = hutangs.map(hutang => {
      const debtor = users.find(user => user.id === hutang.debtorId);
      return {
        ...hutang,
        debtor: debtor || null
      };
    });
    
    res.json({
      success: true,
      data: hutangsWithDebtor,
      message: 'Hutangs retrieved successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error retrieving hutangs',
      error: error.message
    });
  }
});

app.get('/api/hutangs/:id', requireAuth, function(req, res) {
  try {
    const hutang = hutangs.find(h => h.id === req.params.id);
    if (!hutang) {
      return res.status(404).json({
        success: false,
        message: 'Hutang not found'
      });
    }

    const debtor = users.find(user => user.id === hutang.debtorId);
    
    res.json({
      success: true,
      data: {
        ...hutang,
        debtor: debtor || null
      },
      message: 'Hutang retrieved successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error retrieving hutang',
      error: error.message
    });
  }
});

app.post('/api/hutangs', requireAuth, function(req, res) {
  try {
    const { description, amount, dueDate, debtorId, notes } = req.body;
    
    if (!description || !amount || !dueDate || !debtorId) {
      return res.status(400).json({
        success: false,
        message: 'Description, amount, dueDate, and debtorId are required'
      });
    }

    const debtor = users.find(user => user.id === debtorId);
    if (!debtor) {
      return res.status(404).json({
        success: false,
        message: 'Debtor not found'
      });
    }

    const newHutang = {
      id: uuidv4(),
      description,
      amount: parseFloat(amount),
      remainingAmount: parseFloat(amount),
      dueDate: new Date(dueDate).toISOString(),
      createdDate: new Date().toISOString(),
      status: 'pending',
      debtorId,
      notes: notes || null,
      payments: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    hutangs.push(newHutang);
    
    res.status(201).json({
      success: true,
      data: {
        ...newHutang,
        debtor
      },
      message: 'Hutang created successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error creating hutang',
      error: error.message
    });
  }
});

app.put('/api/hutangs/:id', requireAuth, function(req, res) {
  try {
    const hutangIndex = hutangs.findIndex(h => h.id === req.params.id);
    if (hutangIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'Hutang not found'
      });
    }

    const updatedHutang = {
      ...hutangs[hutangIndex],
      ...req.body,
      updatedAt: new Date().toISOString()
    };

    hutangs[hutangIndex] = updatedHutang;
    
    res.json({
      success: true,
      data: updatedHutang,
      message: 'Hutang updated successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating hutang',
      error: error.message
    });
  }
});

// Payment API (now require authentication)
app.post('/api/hutangs/:id/payments', requireAuth, function(req, res) {
  try {
    const hutangIndex = hutangs.findIndex(h => h.id === req.params.id);
    if (hutangIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'Hutang not found'
      });
    }

    const { amount, notes } = req.body;
    if (!amount || parseFloat(amount) <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Amount is required and must be greater than 0'
      });
    }

    const paymentAmount = parseFloat(amount);
    const hutang = hutangs[hutangIndex];
    
    if (hutang.remainingAmount < paymentAmount) {
      return res.status(400).json({
        success: false,
        message: 'Payment amount exceeds remaining amount'
      });
    }

    const newPayment = {
      id: uuidv4(),
      amount: paymentAmount,
      paymentDate: new Date().toISOString(),
      notes: notes || null
    };

    const updatedPayments = [...hutang.payments, newPayment];
    const newRemainingAmount = hutang.remainingAmount - paymentAmount;
    const newStatus = newRemainingAmount === 0 ? 'paid' : hutang.status;

    const updatedHutang = {
      ...hutang,
      payments: updatedPayments,
      remainingAmount: newRemainingAmount,
      status: newStatus,
      updatedAt: new Date().toISOString()
    };

    hutangs[hutangIndex] = updatedHutang;
    
    res.status(201).json({
      success: true,
      data: updatedHutang,
      message: 'Payment added successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error adding payment',
      error: error.message
    });
  }
});

// Summary API (now require authentication)
app.get('/api/summary', requireAuth, function(req, res) {
  try {
    const totalHutang = hutangs
      .filter(hutang => hutang.status !== 'paid')
      .reduce((sum, hutang) => sum + hutang.remainingAmount, 0);
    
    const jumlahPenghutang = new Set(hutangs.map(hutang => hutang.debtorId)).size;
    const jumlahHutang = hutangs.filter(hutang => hutang.status !== 'paid').length;
    const hutangLunas = hutangs.filter(hutang => hutang.status === 'paid').length;
    const hutangJatuhTempo = hutangs.filter(hutang => {
      return hutang.status === 'overdue' || 
             (hutang.status === 'pending' && new Date(hutang.dueDate) < new Date());
    }).length;
    
    res.json({
      success: true,
      data: {
        totalHutang,
        jumlahPenghutang,
        jumlahHutang,
        hutangLunas,
        hutangJatuhTempo
      },
      message: 'Summary retrieved successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error retrieving summary',
      error: error.message
    });
  }
});

// Health check (public)
app.get('/api/health', function(req, res) {
  res.json({
    success: true,
    message: 'API is running',
    timestamp: new Date().toISOString(),
    authenticatedEndpoints: 'All endpoints except /api/health and /api/auth/* require authentication'
  });
});

// Error handling middleware
app.use(function(err, req, res, next) {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Something went wrong!',
    error: err.message
  });
});

// 404 handler
app.use(function(req, res) {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

app.listen(PORT, function() {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/api/health`);
  console.log(`Authentication: Use /api/auth/login to get userId, then include X-User-Id header in requests`);
});

module.exports = app;