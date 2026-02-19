-- Create tables
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    image_url VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS cart_items (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER DEFAULT 1,
    session_id VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255),
    total DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'placed'
);

CREATE TABLE IF NOT EXISTS wallets (
    session_id VARCHAR(255) PRIMARY KEY,
    balance DECIMAL(10, 2) DEFAULT 0.00
);

CREATE TABLE IF NOT EXISTS wallet_transactions (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255),
    amount DECIMAL(10, 2),
    type VARCHAR(50),
    order_id INTEGER REFERENCES orders(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed data
INSERT INTO products (name, description, price, image_url) VALUES
('Quantum Keyboard', 'Mechanical keyboard with quantum switches for instant actuation.', 199.99, 'https://images.unsplash.com/photo-1595225476474-87563907a212?w=500&q=80'),
('Neural Headset', 'AI-powered noise cancellation that adapts to your brainwaves.', 299.99, 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500&q=80'),
('Holographic Monitor', '32-inch 8K display with true 3D holographic projection.', 899.99, 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=500&q=80'),
('ErgoChair Limitless', 'Self-adjusting ergonomic chair with levitation technology.', 499.99, 'https://images.unsplash.com/photo-1580480055273-228ff5388ef8?w=500&q=80'),
('SynthWave Mouse', 'Retro-futuristic wireless mouse with programmable LED grid.', 79.99, 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=500&q=80');
