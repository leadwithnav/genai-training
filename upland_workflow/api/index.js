const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(express.json());
app.use(cors());

const port = process.env.PORT || 8080;
const pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    host: process.env.DB_HOST || 'db',
    database: process.env.DB_NAME || 'upland_workflow',
    password: process.env.DB_PASSWORD || 'password',
    port: process.env.DB_PORT || 5432,
});

// Health Check
app.get('/health', async (req, res) => {
    try {
        await pool.query('SELECT 1');
        res.json({ status: 'ok', db: 'connected' });
    } catch (err) {
        res.status(500).json({ status: 'error', db: err.message });
    }
});

// List Documents
app.get('/api/documents', async (req, res) => {
    try {
        const { status } = req.query;
        let query = 'SELECT * FROM documents';
        let params = [];
        if (status) {
            query += ' WHERE status = $1';
            params.push(status);
        }
        query += ' ORDER BY created_at DESC';
        const result = await pool.query(query, params);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// Create Document (Upload)
app.post('/api/documents', async (req, res) => {
    try {
        const { title, vendor, amount, date } = req.body;
        // 1. Create Document
        const docResult = await pool.query(
            'INSERT INTO documents (title, status, vendor, amount) VALUES ($1, $2, $3, $4) RETURNING id',
            [title, 'New', vendor, amount]
        );
        const docId = docResult.rows[0].id;

        // 2. Mock Extraction (Auto-generate)
        const confidence = (Math.random() * (0.99 - 0.70) + 0.70).toFixed(2);
        await pool.query(
            'INSERT INTO extracted_fields (document_id, invoice_number, vendor, amount, invoice_date, confidence) VALUES ($1, $2, $3, $4, $5, $6)',
            [docId, `INV-${Date.now()}`, vendor, amount, date || new Date(), confidence]
        );

        // 3. Audit Log
        await pool.query(
            'INSERT INTO audit_log (document_id, action, details) VALUES ($1, $2, $3)',
            [docId, 'UPLOAD', 'Document uploaded successfully']
        );

        res.status(201).json({ success: true, id: docId });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// Get Document Details
app.get('/api/documents/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const doc = await pool.query('SELECT * FROM documents WHERE id = $1', [id]);
        if (doc.rows.length === 0) return res.status(404).send('Document not found');

        const extracted = await pool.query('SELECT * FROM extracted_fields WHERE document_id = $1', [id]);
        const audit = await pool.query('SELECT * FROM audit_log WHERE document_id = $1 ORDER BY created_at DESC', [id]);

        res.json({
            ...doc.rows[0],
            extracted: extracted.rows[0] || {},
            audit: audit.rows
        });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// Default Audit Log Endpoint (Optional, based on requirement)
app.get('/api/audit', async (req, res) => {
    try {
        const { docId } = req.query;
        if (!docId) return res.status(400).send('docId required');
        const result = await pool.query('SELECT * FROM audit_log WHERE document_id = $1 ORDER BY created_at DESC', [docId]);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// Approve
app.post('/api/documents/:id/approve', async (req, res) => {
    try {
        const { id } = req.params;
        const { actor } = req.body;

        await pool.query("UPDATE documents SET status = 'Approved' WHERE id = $1", [id]);
        await pool.query(
            'INSERT INTO audit_log (document_id, actor, action, details) VALUES ($1, $2, $3, $4)',
            [id, actor || 'student', 'APPROVE', 'Document approved']
        );
        res.json({ success: true });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// Reject
app.post('/api/documents/:id/reject', async (req, res) => {
    try {
        const { id } = req.params;
        const { actor } = req.body;

        await pool.query("UPDATE documents SET status = 'NeedsReview' WHERE id = $1", [id]);
        await pool.query(
            'INSERT INTO audit_log (document_id, actor, action, details) VALUES ($1, $2, $3, $4)',
            [id, actor || 'student', 'REJECT', 'Document rejected, returned to review']
        );
        res.json({ success: true });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// Deliver
app.post('/api/documents/:id/deliver', async (req, res) => {
    try {
        const { id } = req.params;
        const { actor } = req.body;

        await pool.query("UPDATE documents SET status = 'Delivered' WHERE id = $1", [id]);
        await pool.query(
            'INSERT INTO audit_log (document_id, actor, action, details) VALUES ($1, $2, $3, $4)',
            [id, actor || 'student', 'DELIVER', 'Delivered via mock Email/Fax gateway']
        );
        res.json({ success: true });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});


app.listen(port, () => {
    console.log(`Upland Workflow API running on port ${port}`);
});
