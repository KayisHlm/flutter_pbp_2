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
let users = []; // Deprecated: explicit debtor store removed
let hutangs = [];
let authUsers = []; // Authentication users

// Simple session management - store logged in user IDs
let activeSessions = new Set();

// Utilities
const calcHutangFields = (hutang) => {
  const paid = (hutang.payments || []).reduce((s, p) => s + Number(p.amount || 0), 0);
  const amount = Number(hutang.amount || 0);
  const remainingAmount = amount - paid;
  const isOverdue = remainingAmount > 0 && new Date(hutang.dueDate) < new Date();
  const status = remainingAmount === 0 ? 'paid' : (isOverdue ? 'overdue' : (hutang.status || 'pending'));
  return { paid, remainingAmount, isOverdue, status };
};

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
    let { username, email, password, name } = req.body;
    username = (username || '').trim();
    email = (email || '').trim().toLowerCase();
    password = (password || '').toString();
    name = (name || username).toString();

    if (!username || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Username, email, and password are required'
      });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid email format'
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters'
      });
    }

    const existingUser = authUsers.find(u =>
      (u.email || '').toLowerCase() === email || (u.username || '').toLowerCase() === username.toLowerCase()
    );
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'User already exists with this email or username'
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const now = new Date().toISOString();

    const newUser = {
      id: uuidv4(),
      username,
      email,
      password: hashedPassword,
      name,
      createdAt: now,
      updatedAt: now
    };

    authUsers.push(newUser);
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
    let { username, password } = req.body;
    username = (username || '').trim().toLowerCase();
    password = (password || '').toString();

    if (!username || !password) {
      return res.status(400).json({
        success: false,
        message: 'Username and password are required'
      });
    }

    const user = authUsers.find(u =>
      (u.username || '').toLowerCase() === username || (u.email || '').toLowerCase() === username
    );
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    activeSessions.add(user.id);
    const { password: _, ...userWithoutPassword } = user;
    res.json({
      success: true,
      data: {
        user: userWithoutPassword,
        userId: user.id
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
    const usersWithHutangSummary = authUsers.map(au => {
      const userHutangs = hutangs.filter(h => h.debtorEmail === au.email && h.status !== 'paid');
      const totalOutstanding = userHutangs.reduce((sum, h) => {
        const { remainingAmount } = calcHutangFields(h);
        return sum + remainingAmount;
      }, 0);
      const jumlahHutang = userHutangs.length;

      return {
        id: au.id,
        name: au.name || au.username,
        email: au.email,
        phone: null,
        address: null,
        photoUrl: null,
        totalHutang: totalOutstanding,
        jumlahHutang,
        createdAt: au.createdAt,
        updatedAt: au.updatedAt,
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
    const au = authUsers.find(u => u.id === req.params.id);
    if (!au) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const userHutangs = hutangs
      .filter(hutang => hutang.debtorEmail === au.email)
      .map(h => ({
        ...h,
        debtor: {
          id: au.id,
          name: au.name || au.username,
          email: au.email,
          phone: null,
          address: null,
          photoUrl: null,
          createdAt: au.createdAt,
          updatedAt: au.updatedAt,
        },
      }));

    const totalHutang = userHutangs
      .filter(hutang => hutang.status !== 'paid')
      .reduce((sum, hutang) => {
        const { remainingAmount } = calcHutangFields(hutang);
        return sum + remainingAmount;
      }, 0);
    const jumlahHutang = userHutangs.filter(hutang => hutang.status !== 'paid').length;
    
    res.json({
      success: true,
      data: {
        id: au.id,
        name: au.name || au.username,
        email: au.email,
        phone: null,
        address: null,
        photoUrl: null,
        totalHutang,
        jumlahHutang,
        hutangs: userHutangs,
        createdAt: au.createdAt,
        updatedAt: au.updatedAt,
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

// Creation of explicit debtor users removed; use registered accounts (authUsers)
app.post('/api/users', requireAuth, function(req, res) {
  res.status(405).json({
    success: false,
    message: 'Creating debtor users is disabled. Use registered account emails when adding hutang.'
  });
});

// Hutangs API (now require authentication)
app.get('/api/hutangs', requireAuth, function(req, res) {
  try {
    const hutangsWithDebtor = hutangs.map(hutang => {
      const au = authUsers.find(u => u.email === hutang.debtorEmail);
      const { remainingAmount, isOverdue, status } = calcHutangFields(hutang);
      const debtor = au
        ? {
            id: au.id,
            name: au.name || au.username,
            email: au.email,
            phone: null,
            address: null,
            photoUrl: null,
            createdAt: au.createdAt,
            updatedAt: au.updatedAt,
          }
        : {
            id: 'unknown',
            name: (hutang.debtorEmail || 'Unknown'),
            email: hutang.debtorEmail || null,
            phone: null,
            address: null,
            photoUrl: null,
            createdAt: null,
            updatedAt: null,
          };
      return {
        ...hutang,
        remainingAmount,
        status,
        debtor
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
    const au = authUsers.find(u => u.email === hutang.debtorEmail);
    const { remainingAmount, isOverdue, status } = calcHutangFields(hutang);
    const debtor = au
      ? {
          id: au.id,
          name: au.name || au.username,
          email: au.email,
          phone: null,
          address: null,
          photoUrl: null,
          createdAt: au.createdAt,
          updatedAt: au.updatedAt,
        }
      : {
          id: 'unknown',
          name: (hutang.debtorEmail || 'Unknown'),
          email: hutang.debtorEmail || null,
          phone: null,
          address: null,
          photoUrl: null,
          createdAt: null,
          updatedAt: null,
        };
    
    res.json({
      success: true,
      data: {
        ...hutang,
        remainingAmount,
        status,
        debtor: debtor
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
    const { description, amount, dueDate, debtorEmail, notes } = req.body;
    
    if (!description || !amount || !dueDate || !debtorEmail) {
      return res.status(400).json({
        success: false,
        message: 'Description, amount, dueDate, and debtorEmail are required'
      });
    }

    const au = authUsers.find(u => u.email === debtorEmail);
    if (!au) {
      return res.status(404).json({
        success: false,
        message: 'Debtor email not found. Register first.'
      });
    }

    const newHutang = {
      id: uuidv4(),
      description,
      amount: Number(amount),
      dueDate: new Date(dueDate).toISOString(),
      createdDate: new Date().toISOString(),
      status: 'pending',
      debtorEmail,
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
        debtor: {
          id: au.id,
          name: au.name || au.username,
          email: au.email,
          phone: null,
          address: null,
          photoUrl: null,
          createdAt: au.createdAt,
          updatedAt: au.updatedAt,
        }
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

    const updatePayload = { ...req.body };
    if (updatePayload.amount !== undefined) {
      updatePayload.amount = Number(updatePayload.amount);
    }
    if (updatePayload.dueDate !== undefined) {
      updatePayload.dueDate = new Date(updatePayload.dueDate).toISOString();
    }
    const updatedHutang = {
      ...hutangs[hutangIndex],
      ...updatePayload,
      updatedAt: new Date().toISOString()
    };
    const calc = calcHutangFields(updatedHutang);
    updatedHutang.remainingAmount = calc.remainingAmount;
    updatedHutang.status = calc.status;

    hutangs[hutangIndex] = updatedHutang;
    
    const au = authUsers.find(u => u.email === updatedHutang.debtorEmail);
    const debtor = au
      ? {
          id: au.id,
          name: au.name || au.username,
          email: au.email,
          phone: null,
          address: null,
          photoUrl: null,
          createdAt: au.createdAt,
          updatedAt: au.updatedAt,
        }
      : null;

    res.json({
      success: true,
      data: {
        ...updatedHutang,
        debtor: debtor || null,
      },
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

app.delete('/api/hutangs/:id', requireAuth, function(req, res) {
  try {
    const idx = hutangs.findIndex(h => h.id === req.params.id);
    if (idx === -1) {
      return res.status(404).json({
        success: false,
        message: 'Hutang not found'
      });
    }
    const deleted = hutangs[idx];
    hutangs.splice(idx, 1);
    res.json({
      success: true,
      data: deleted,
      message: 'Hutang deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting hutang',
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
    
    const paidSoFar = (hutang.payments || []).reduce((s, p) => s + Number(p.amount || 0), 0);
    const remainingBefore = Number(hutang.amount || 0) - paidSoFar;
    if (remainingBefore < paymentAmount) {
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

    const updatedPayments = [...(hutang.payments || []), newPayment];
    const newPaid = paidSoFar + paymentAmount;
    const newRemainingAmount = Number(hutang.amount || 0) - newPaid;
    const isOverdue = newRemainingAmount > 0 && new Date(hutang.dueDate) < new Date();
    const newStatus = newRemainingAmount === 0 ? 'paid' : (isOverdue ? 'overdue' : (hutang.status || 'pending'));

    const updatedHutang = {
      ...hutang,
      payments: updatedPayments,
      remainingAmount: newRemainingAmount,
      status: newStatus,
      updatedAt: new Date().toISOString()
    };

    hutangs[hutangIndex] = updatedHutang;
    
    const au = authUsers.find(u => u.email === updatedHutang.debtorEmail);
    const debtor = au
      ? {
          id: au.id,
          name: au.name || au.username,
          email: au.email,
          phone: null,
          address: null,
          photoUrl: null,
          createdAt: au.createdAt,
          updatedAt: au.updatedAt,
        }
      : null;

    res.status(201).json({
      success: true,
      data: {
        ...updatedHutang,
        debtor: debtor || null,
      },
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
      .reduce((sum, hutang) => {
        const { remainingAmount } = calcHutangFields(hutang);
        return sum + remainingAmount;
      }, 0);
    
    const jumlahPenghutang = new Set(hutangs.map(hutang => hutang.debtorEmail)).size;
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

app.listen(PORT, '0.0.0.0', function() {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/api/health`);
  console.log(`Authentication: Use /api/auth/login to get userId, then include X-User-Id header in requests`);
});

module.exports = app;
