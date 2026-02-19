-- Database Schema for Upland Workflow
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'New', -- New, Processing, NeedsReview, Approved, Delivered
    vendor VARCHAR(255),
    amount DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE extracted_fields (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES documents(id) ON DELETE CASCADE,
    invoice_number VARCHAR(100),
    vendor VARCHAR(255),
    amount DECIMAL(10, 2),
    invoice_date DATE,
    confidence FLOAT
);

CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES documents(id) ON DELETE CASCADE,
    actor VARCHAR(100) DEFAULT 'student',
    action VARCHAR(50) NOT NULL, -- UPLOAD, APPROVE, REJECT, REQUEST_INFO, DELIVER
    details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed Data
INSERT INTO documents (title, status, vendor, amount) VALUES
('Invoice-001.pdf', 'New', 'Acme Corp', 1500.00),
('Invoice-002.pdf', 'Processing', 'Globex', 2500.50),
('Contract-A.docx', 'NeedsReview', 'Soylent Corp', 0.00),
('Receipt-X.png', 'Approved', 'Umbrella Inc', 300.00),
('Invoice-003.pdf', 'Delivered', 'Stark Ind', 9999.99),
('Invoice-004.pdf', 'New', 'Wayne Ent', 500.00),
('Invoice-005.pdf', 'NeedsReview', 'Cyberdyne', 4500.00),
('Invoice-006.pdf', 'Approved', 'Massive Dynamic', 120.00);

-- Extracted Fields (Mock)
INSERT INTO extracted_fields (document_id, invoice_number, vendor, amount, invoice_date, confidence) VALUES
(1, 'INV-001', 'Acme Corp', 1500.00, '2023-10-01', 0.95),
(2, 'INV-002', 'Globex', 2500.50, '2023-10-05', 0.88),
(3, 'CNT-A', 'Soylent Corp', 0.00, '2023-09-15', 0.60),
(4, 'RCPT-X', 'Umbrella Inc', 300.00, '2023-10-10', 0.99),
(5, 'INV-003', 'Stark Ind', 9999.99, '2023-10-12', 0.92),
(6, 'INV-004', 'Wayne Ent', 500.00, '2023-10-20', 0.75),
(7, 'INV-005', 'Cyberdyne', 4500.00, '2023-10-22', 0.85),
(8, 'INV-006', 'Massive Dynamic', 120.00, '2023-10-25', 0.90);

-- Audit Logs
INSERT INTO audit_log (document_id, action, details) VALUES
(1, 'UPLOAD', 'Document uploaded via web portal'),
(2, 'UPLOAD', 'Document uploaded'),
(2, 'EXTRACT', 'AI extraction completed'),
(3, 'UPLOAD', 'Document uploaded'),
(3, 'EXTRACT', 'AI extraction completed'),
(3, 'REQUEST_INFO', 'Missing signature page'),
(4, 'UPLOAD', 'Document uploaded'),
(4, 'APPROVE', 'Approved by Manager'),
(5, 'UPLOAD', 'Document uploaded'),
(5, 'APPROVE', 'Approved by Manager'),
(5, 'DELIVER', 'Sent via Secure Email Gateway');
