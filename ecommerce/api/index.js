const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(express.json());
app.use(cors());

const port = process.env.PORT || 8080;
const dbConfig = {
    user: process.env.DB_USER || 'postgres',
    host: process.env.DB_HOST || 'db',
    database: process.env.DB_NAME || 'ecommerce_db',
    password: process.env.DB_PASSWORD || 'password',
    port: process.env.DB_PORT || 5432,
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
};

let pool;
let isConnected = false;

const connectWithRetry = () => {
    pool = new Pool(dbConfig);
    pool.query('SELECT 1 + 1 AS result', (err, res) => {
        if (err) {
            console.error('Database connection failed, retrying in 5 seconds...', err.message);
            setTimeout(connectWithRetry, 5000);
        } else {
            console.log('Database connected successfully');
            isConnected = true;
        }
    });
};

connectWithRetry();

// Health Check
app.get('/health', (req, res) => {
    res.json({
        status: isConnected ? 'ok' : 'db-down',
        timestamp: new Date().toISOString()
    });
});

// Products
app.get('/api/products', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM products ORDER BY id');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

app.get('/api/products/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query('SELECT * FROM products WHERE id = $1', [id]);
        if (result.rows.length === 0) return res.status(404).send('Product not found');
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// Cart
app.get('/api/cart/:sessionId', async (req, res) => {
    try {
        const { sessionId } = req.params;
        const result = await pool.query(
            `SELECT c.id, c.product_id, c.quantity, p.name, p.price, p.image_url 
             FROM cart_items c 
             JOIN products p ON c.product_id = p.id 
             WHERE c.session_id = $1`,
            [sessionId]
        );
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

app.post('/api/cart', async (req, res) => {
    try {
        const { sessionId, productId, quantity } = req.body;

        // Check if item exists in cart
        const existing = await pool.query(
            'SELECT * FROM cart_items WHERE session_id = $1 AND product_id = $2',
            [sessionId, productId]
        );

        if (existing.rows.length > 0) {
            // Update quantity
            const newQuantity = existing.rows[0].quantity + (quantity || 1);
            await pool.query(
                'UPDATE cart_items SET quantity = $1 WHERE id = $2',
                [newQuantity, existing.rows[0].id]
            );
        } else {
            // Insert
            await pool.query(
                'INSERT INTO cart_items (session_id, product_id, quantity) VALUES ($1, $2, $3)',
                [sessionId, productId, quantity || 1]
            );
        }
        res.json({ success: true });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

app.delete('/api/cart/:sessionId', async (req, res) => { // Clear cart
    try {
        const { sessionId } = req.params;
        await pool.query('DELETE FROM cart_items WHERE session_id = $1', [sessionId]);
        res.json({ success: true });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// Checkout
app.post('/api/checkout', async (req, res) => {
    try {
        const { sessionId, total } = req.body;

        // 1. Check Wallet Balance
        let wallet = await pool.query('SELECT * FROM wallets WHERE session_id = $1', [sessionId]);
        if (wallet.rows.length === 0) {
            // Create if not exists (though realistically should exist, but let's be safe)
            await pool.query('INSERT INTO wallets (session_id, balance) VALUES ($1, 0)', [sessionId]);
            wallet = { rows: [{ balance: 0 }] };
        }

        const currentBalance = parseFloat(wallet.rows[0].balance);
        if (currentBalance < total) {
            return res.status(400).json({
                success: false,
                message: 'Insufficient funds in wallet',
                code: 'INSUFFICIENT_FUNDS'
            });
        }

        // 2. Deduct from Wallet
        await pool.query('UPDATE wallets SET balance = balance - $1 WHERE session_id = $2', [total, sessionId]);
        await pool.query('INSERT INTO wallet_transactions (session_id, amount, type) VALUES ($1, $2, $3)',
            [sessionId, -total, 'purchase']);

        // 3. Create order
        const result = await pool.query(
            'INSERT INTO orders (session_id, total) VALUES ($1, $2) RETURNING id',
            [sessionId, total]
        );

        // 4. Clear cart
        await pool.query('DELETE FROM cart_items WHERE session_id = $1', [sessionId]);

        res.status(201).json({
            success: true,
            orderId: result.rows[0].id,
            message: 'Order placed successfully'
        });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// Update cart item quantity
app.put('/api/cart', async (req, res) => {
    try {
        const { sessionId, productId, quantity } = req.body;
        // Check if item exists
        const existing = await pool.query(
            'SELECT * FROM cart_items WHERE session_id = $1 AND product_id = $2',
            [sessionId, productId]
        );

        if (existing.rows.length === 0) return res.status(404).send('Item not found');

        if (quantity <= 0) {
            await pool.query('DELETE FROM cart_items WHERE id = $1', [existing.rows[0].id]);
        } else {
            await pool.query('UPDATE cart_items SET quantity = $1 WHERE id = $2', [quantity, existing.rows[0].id]);
        }
        res.json({ success: true });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// Remove single item from cart
app.delete('/api/cart/:sessionId/item/:productId', async (req, res) => {
    try {
        const { sessionId, productId } = req.params;
        await pool.query('DELETE FROM cart_items WHERE session_id = $1 AND product_id = $2', [sessionId, productId]);
        res.json({ success: true });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// Orders
app.get('/api/orders/:sessionId', async (req, res) => {
    try {
        const { sessionId } = req.params;
        const result = await pool.query('SELECT * FROM orders WHERE session_id = $1 ORDER BY created_at DESC', [sessionId]);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

app.post('/api/orders/:orderId/cancel', async (req, res) => {
    try {
        const { orderId } = req.params;
        // Check current status
        const check = await pool.query('SELECT * FROM orders WHERE id = $1', [orderId]);
        if (check.rows.length === 0) return res.status(404).send('Order not found');

        const order = check.rows[0];
        if (order.status !== 'placed') return res.status(400).send('Cannot cancel order unless status is placed');

        // Cancel and Refund
        await pool.query('UPDATE orders SET status = $1 WHERE id = $2', ['cancelled', orderId]);

        // Add refund to wallet
        await addToWallet(order.session_id, order.total, `Refund for cancelled order #${orderId}`, orderId);

        res.json({ success: true, message: 'Order cancelled and refunded to wallet' });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

app.post('/api/orders/:orderId/deliver', async (req, res) => {
    try {
        const { orderId } = req.params;
        await pool.query('UPDATE orders SET status = $1 WHERE id = $2', ['delivered', orderId]);
        res.json({ success: true, message: 'Order marked as delivered' });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

app.post('/api/orders/:orderId/return', async (req, res) => {
    try {
        const { orderId } = req.params;
        // Check current status
        const check = await pool.query('SELECT * FROM orders WHERE id = $1', [orderId]);
        if (check.rows.length === 0) return res.status(404).send('Order not found');

        const order = check.rows[0];
        // For demo, we allow return from 'placed' or 'delivered' or whatever, but logically 'delivered'.
        // Let's assume user can mark as 'delivered' too? Or just simulate time. 
        // For simplicity, let's allow returning 'placed' orders too (maybe acting as a cancel), 
        // or assume some background job delivers them. 
        // Let's add a quick way to 'simulate delivery' or just allow returning 'placed' for now.
        if (['cancelled', 'returned'].includes(order.status)) return res.status(400).send('Order already cancelled or returned');

        // Process Return
        await pool.query('UPDATE orders SET status = $1 WHERE id = $2', ['returned', orderId]);

        // Add refund to wallet
        await addToWallet(order.session_id, order.total, `Refund for returned order #${orderId}`, orderId);

        res.json({ success: true, message: 'Order returned and refunded to wallet' });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// Wallet
async function addToWallet(sessionId, amount, type, orderId = null) {
    // Ensure wallet exists
    let wallet = await pool.query('SELECT * FROM wallets WHERE session_id = $1', [sessionId]);
    if (wallet.rows.length === 0) {
        await pool.query('INSERT INTO wallets (session_id, balance) VALUES ($1, 0)', [sessionId]);
    }

    // Update balance
    await pool.query('UPDATE wallets SET balance = balance + $1 WHERE session_id = $2', [amount, sessionId]);

    // Log transaction
    await pool.query('INSERT INTO wallet_transactions (session_id, amount, type, order_id) VALUES ($1, $2, $3, $4)',
        [sessionId, amount, type, orderId]);
}

app.get('/api/wallet/:sessionId', async (req, res) => {
    try {
        const { sessionId } = req.params;
        let wallet = await pool.query('SELECT * FROM wallets WHERE session_id = $1', [sessionId]);
        if (wallet.rows.length === 0) {
            // Create empty wallet if new user
            await pool.query('INSERT INTO wallets (session_id, balance) VALUES ($1, 0)', [sessionId]);
            return res.json({ balance: 0.00 });
        }
        res.json(wallet.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

app.post('/api/wallet/add', async (req, res) => {
    try {
        const { sessionId, amount } = req.body;
        if (!amount || amount <= 0) return res.status(400).send('Invalid amount');

        await addToWallet(sessionId, amount, 'deposit');
        res.json({ success: true, message: 'Funds added to wallet' });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

app.listen(port, () => {
    console.log(`API running on port ${port}`);
});
