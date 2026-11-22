// Database access for the transactions API.
// mysql2 + a connection pool: broken connections are replaced automatically,
// so the app survives a database failover (legacy problem #3).
const mysql = require('mysql2/promise');

// Settings come from environment variables (used on AWS, filled from Secrets Manager).
// If they are not set, fall back to DbConfig.js (the legacy setup).
function loadConfig() {
  if (process.env.DB_HOST) {
    return {
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT || 3306),
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME || 'webappdb',
    };
  }
  const c = require('./DbConfig');
  return { host: c.DB_HOST, port: 3306, user: c.DB_USER, password: c.DB_PWD, database: c.DB_DATABASE };
}

const pool = mysql.createPool({
  ...loadConfig(),
  connectionLimit: 5,
  waitForConnections: true,
  enableKeepAlive: true,
  decimalNumbers: true,
});

const RETRYABLE = new Set(['PROTOCOL_CONNECTION_LOST', 'ECONNREFUSED', 'ECONNRESET', 'ETIMEDOUT', 'EPIPE']);

// Run a query. On a connection error (for example during a failover), try up to 3 times.
async function query(sql, params = []) {
  for (let attempt = 1; ; attempt++) {
    try {
      const [rows] = await pool.query(sql, params);
      return rows;
    } catch (err) {
      if (!RETRYABLE.has(err.code) || attempt >= 3) throw err;
      console.warn(`Database error ${err.code}, retrying (attempt ${attempt} of 3) in 2 seconds`);
      await new Promise((resolve) => setTimeout(resolve, 2000));
    }
  }
}

// Every query uses ? placeholders: user input is always data, never SQL.
async function addTransaction(amount, desc) {
  await query('INSERT INTO transactions (amount, description) VALUES (?, ?)', [amount, desc]);
}

async function getAllTransactions() {
  return query('SELECT id, amount, description FROM transactions');
}

async function findTransactionById(id) {
  return query('SELECT id, amount, description FROM transactions WHERE id = ?', [id]);
}

async function deleteAllTransactions() {
  await query('DELETE FROM transactions');
}

async function deleteTransactionById(id) {
  await query('DELETE FROM transactions WHERE id = ?', [id]);
}

module.exports = { addTransaction, getAllTransactions, findTransactionById, deleteAllTransactions, deleteTransactionById };
