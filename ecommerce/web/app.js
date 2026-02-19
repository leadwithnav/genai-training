const API_URL = '/api';

// Simple session management
let sessionId = localStorage.getItem('sessionId');
if (!sessionId) {
    sessionId = 'sess_' + Math.random().toString(36).substr(2, 9);
    localStorage.setItem('sessionId', sessionId);
}

// State
let cart = [];

// DOM Elements
const pages = {
    home: document.getElementById('home-page'),
    cart: document.getElementById('cart-page'),
    orders: document.getElementById('orders-page'),
    wallet: document.getElementById('wallet-page'),
    success: document.getElementById('success-page')
};
const productList = document.getElementById('product-list');
const cartCount = document.getElementById('cart-count');
const cartItems = document.getElementById('cart-items');
const cartTotal = document.getElementById('cart-total');

// Navigation
function showPage(pageName) {
    Object.values(pages).forEach(page => page.classList.add('hidden'));

    // Reset specific pages
    if (pageName === 'home') {
        loadProducts();
    } else if (pageName === 'cart') {
        loadCart();
    } else if (pageName === 'orders') {
        loadOrders();
    } else if (pageName === 'wallet') {
        loadWallet();
    }

    pages[pageName].classList.remove('hidden');
}

// Logic
async function loadProducts() {
    try {
        productList.innerHTML = '<div class="loader">Loading...</div>';
        const res = await fetch(`${API_URL}/products`);
        if (!res.ok) throw new Error('Failed to fetch products');
        const products = await res.json();

        productList.innerHTML = products.map(product => `
            <div class="card">
                <img src="${product.image_url}" alt="${product.name}">
                <div class="card-content">
                    <h3>${product.name}</h3>
                    <p>${product.description}</p>
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <span style="font-weight: 700;">$${product.price}</span>
                        <button class="btn-primary" onclick="addToCart(${product.id})">Add to Cart</button>
                    </div>
                </div>
            </div>
        `).join('');
    } catch (err) {
        productList.innerHTML = `<p class="error">Error loading products: ${err.message}</p>`;
    }
}

async function addToCart(productId) {
    try {
        const res = await fetch(`${API_URL}/cart`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ sessionId, productId, quantity: 1 })
        });
        if (res.ok) {
            alert('Item added to cart!');
            updateCartCount();
        }
    } catch (err) {
        alert('Failed to add item');
    }
}

async function updateCartCount() {
    try {
        const res = await fetch(`${API_URL}/cart/${sessionId}`);
        if (!res.ok) return;
        const cart = await res.json();
        const count = cart.reduce((sum, item) => sum + item.quantity, 0);
        cartCount.textContent = count;
    } catch (err) { console.error(err); }
}

async function loadCart() {
    try {
        cartItems.innerHTML = '<div class="loader">Loading cart...</div>';
        const res = await fetch(`${API_URL}/cart/${sessionId}`);
        if (!res.ok) throw new Error('Failed to load cart');
        cart = await res.json();

        if (cart.length === 0) {
            cartItems.innerHTML = '<p>Your cart is empty.</p>';
            cartTotal.textContent = '0.00';
            updateCartCount(); // Ensure count is synced
            return;
        }

        const total = cart.reduce((sum, item) => sum + (parseFloat(item.price) * item.quantity), 0);
        cartTotal.textContent = total.toFixed(2);

        // Update count
        const count = cart.reduce((count, item) => count + item.quantity, 0);
        cartCount.textContent = count;

        cartItems.innerHTML = cart.map(item => `
            <div class="card" style="display: flex; flex-direction: row; margin-bottom: 1rem; align-items: center;">
                <img src="${item.image_url}" style="width: 100px; height: 100px; object-fit: cover;" alt="${item.name}">
                <div class="card-content" style="flex: 1;">
                    <h3>${item.name}</h3>
                    <div class="qty-control">
                        <button class="btn-qty" onclick="updateQuantity(${item.product_id}, ${item.quantity - 1})">-</button>
                        <span>${item.quantity}</span>
                        <button class="btn-qty" onclick="updateQuantity(${item.product_id}, ${item.quantity + 1})">+</button>
                    </div>
                </div>
                <div style="padding: 1rem; text-align: right;">
                    <span style="font-weight: 700; display: block; margin-bottom: 0.5rem;">$${(item.quantity * item.price).toFixed(2)}</span>
                    <button class="btn-remove" onclick="removeFromCart(${item.product_id})">Remove</button>
                </div>
            </div>
        `).join('');

    } catch (err) {
        cartItems.innerHTML = `<p class="error">Error loading cart: ${err.message}</p>`;
    }
}

async function updateQuantity(productId, newQty) {
    if (newQty < 1) return removeFromCart(productId);
    try {
        const res = await fetch(`${API_URL}/cart`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ sessionId, productId, quantity: newQty })
        });
        if (res.ok) {
            loadCart();
            updateCartCount();
        }
    } catch (err) { console.error(err); }
}

async function removeFromCart(productId) {
    if (!confirm('Remove this item?')) return;
    try {
        const res = await fetch(`${API_URL}/cart/${sessionId}/item/${productId}`, { method: 'DELETE' });
        if (res.ok) {
            loadCart();
            updateCartCount();
        }
    } catch (err) { console.error(err); }
}

async function checkout() {
    if (cart.length === 0) return alert('Cart is empty!');

    // Get total
    const total = parseFloat(cartTotal.textContent);

    // Get Wallet Balance
    let balance = 0;
    try {
        const res = await fetch(`${API_URL}/wallet/${sessionId}`);
        const data = await res.json();
        balance = parseFloat(data.balance);
    } catch (err) {
        return alert('Could not fetch wallet balance');
    }

    const remaining = balance - total;

    // Update Modal UI
    document.getElementById('modal-balance').textContent = `$${balance.toFixed(2)}`;
    document.getElementById('modal-total').textContent = `-$${total.toFixed(2)}`;
    document.getElementById('modal-remaining').textContent = `$${remaining.toFixed(2)}`;

    const confirmBtn = document.getElementById('btn-confirm-pay');
    const addFundsBtn = document.getElementById('btn-add-funds');
    const remainingEl = document.getElementById('modal-remaining');

    if (remaining < 0) {
        remainingEl.style.color = 'red';
        confirmBtn.classList.add('hidden');
        addFundsBtn.classList.remove('hidden');
    } else {
        remainingEl.style.color = 'inherit';
        confirmBtn.classList.remove('hidden');
        addFundsBtn.classList.add('hidden');
    }

    // Show Modal
    const modal = document.getElementById('checkout-modal');
    modal.classList.remove('hidden');
}

function closeModal() {
    document.getElementById('checkout-modal').classList.add('hidden');
}

function goToWallet() {
    closeModal();
    showPage('wallet');
}

async function confirmCheckout() {
    try {
        const total = parseFloat(cartTotal.textContent);
        const res = await fetch(`${API_URL}/checkout`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ sessionId, total })
        });

        if (res.ok) {
            const data = await res.json();
            closeModal();
            document.getElementById('order-id').innerText = '#' + data.orderId;
            showPage('success');
            // Clear local state
            cart = [];
            cartCount.textContent = '0';
        } else {
            const errorData = await res.json();
            alert('Checkout failed: ' + (errorData.message || 'Unknown error'));
        }
    } catch (err) {
        console.error(err);
        alert('Checkout error');
    }
}

async function loadOrders() {
    try {
        const orderList = document.getElementById('orders-list');
        orderList.innerHTML = '<div class="loader">Loading...</div>';

        const res = await fetch(`${API_URL}/orders/${sessionId}`);
        if (!res.ok) throw new Error('Failed to fetch orders');
        const orders = await res.json();

        if (orders.length === 0) {
            orderList.innerHTML = '<p>No orders found.</p>';
            return;
        }

        orderList.innerHTML = orders.map(order => `
            <div class="card order-card">
              <div class="order-header">
                <h3>Order #${order.id}</h3>
                <span class="status ${order.status}">${order.status.toUpperCase()}</span>
              </div>
              <p>Total: $${parseFloat(order.total).toFixed(2)}</p>
              <p>Date: ${new Date(order.created_at).toLocaleDateString()}</p>
              <div class="actions">
                ${order.status === 'placed' ? `
                    <button onclick="cancelOrder(${order.id})" class="btn-cancel">Cancel Order</button>
                    <button onclick="markDelivered(${order.id})" class="btn-primary" style="margin-left:8px; background-color:#10b981">Simulate Delivery</button>
                ` : ''}
                ${order.status === 'delivered' ? `<button onclick="returnOrder(${order.id})" class="btn-return">Return / Refund</button>` : ''}
              </div>
            </div>
        `).join('');
    } catch (err) {
        document.getElementById('orders-list').innerHTML = `<p class="error">${err.message}</p>`;
    }
}

async function cancelOrder(id) {
    if (!confirm('Are you sure you want to cancel this order?')) return;
    try {
        const res = await fetch(`${API_URL}/orders/${id}/cancel`, { method: 'POST' });
        const data = await res.json();
        if (res.ok) {
            alert(data.message);
            loadOrders();
        } else {
            alert(data);
        }
    } catch (err) { alert('Error cancelling order'); }
}

async function markDelivered(id) {
    try {
        const res = await fetch(`${API_URL}/orders/${id}/deliver`, { method: 'POST' });
        const data = await res.json();
        if (res.ok) {
            alert(data.message);
            loadOrders();
        } else {
            alert(data);
        }
    } catch (err) { alert('Error delivering order'); }
}

async function returnOrder(id) {
    if (!confirm('Return this order for a refund?')) return;
    try {
        const res = await fetch(`${API_URL}/orders/${id}/return`, { method: 'POST' });
        const data = await res.json();
        if (res.ok) {
            alert(data.message);
            loadOrders();
        } else {
            alert(data);
        }
    } catch (err) { alert('Error returning order'); }
}

async function loadWallet() {
    try {
        const res = await fetch(`${API_URL}/wallet/${sessionId}`);
        const data = await res.json();
        document.getElementById('wallet-balance').innerText = parseFloat(data.balance).toFixed(2);
    } catch (err) { console.error(err); }
}

async function addFunds() {
    const amount = document.getElementById('add-amount').value;
    if (!amount || amount <= 0) return alert('Enter a valid amount');

    try {
        const res = await fetch(`${API_URL}/wallet/add`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ sessionId, amount: parseFloat(amount) })
        });
        if (res.ok) {
            alert('Funds added!');
            loadWallet();
            document.getElementById('add-amount').value = '';
        } else {
            alert('Failed to add funds');
        }
    } catch (err) { alert('Error adding funds'); }
}

// Initial Load
loadProducts();
updateCartCount();
