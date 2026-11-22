const transactionService = require('./TransactionService');
const express = require('express');
const cors = require('cors');

const app = express();
const port = 4000;

app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(cors());

// Every route catches its own errors: a database problem returns 500 instead of crashing the app.
function fail(res, message, err) {
  console.error(message, err);
  res.status(500).json({ message });
}

// Health check (used by the load balancer later)
app.get('/health', (req, res) => {
  res.json('This is the health check');
});

// Add a transaction
app.post('/transaction', async (req, res) => {
  try {
    await transactionService.addTransaction(req.body.amount, req.body.desc);
    res.json({ message: 'added transaction successfully' });
  } catch (err) {
    fail(res, 'something went wrong', err);
  }
});

// Get all transactions
app.get('/transaction', async (req, res) => {
  try {
    const rows = await transactionService.getAllTransactions();
    res.json({ result: rows });
  } catch (err) {
    fail(res, 'could not get all transactions', err);
  }
});

// Delete all transactions
app.delete('/transaction', async (req, res) => {
  try {
    await transactionService.deleteAllTransactions();
    res.json({ message: 'delete function execution finished.' });
  } catch (err) {
    fail(res, 'deleting all transactions may have failed', err);
  }
});

// Delete one transaction (id in the body or in ?id=)
app.delete('/transaction/id', async (req, res) => {
  const id = req.query.id ?? req.body.id;
  try {
    await transactionService.deleteTransactionById(id);
    res.json({ message: `transaction with id ${id} deleted` });
  } catch (err) {
    fail(res, 'error deleting transaction', err);
  }
});

// Get one transaction (id in the body or in ?id=)
app.get('/transaction/id', async (req, res) => {
  const id = req.query.id ?? req.body.id;
  try {
    const rows = await transactionService.findTransactionById(id);
    if (rows.length === 0) return res.status(404).json({ message: `no transaction with id ${id}` });
    res.json(rows[0]);
  } catch (err) {
    fail(res, 'error retrieving transaction', err);
  }
});

app.listen(port, () => {
  console.log(`Transactions API listening on port ${port}`);
});
