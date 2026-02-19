const API_URL = 'http://localhost:8082/api';

// State
let currentStatus = 'New';
let currentDocId = null;

// Navigation
function showPage(pageId) {
    document.querySelectorAll('.page').forEach(el => el.classList.add('hidden'));
    document.getElementById(`${pageId}-page`).classList.remove('hidden');

    if (pageId === 'inbox') {
        loadDocuments();
    }
}

// Inbox Logic
async function loadDocuments() {
    const list = document.getElementById('document-list');
    list.innerHTML = '<div class="loading">Loading...</div>';

    try {
        const res = await fetch(`${API_URL}/documents?status=${currentStatus}`);
        const docs = await res.json();

        if (docs.length === 0) {
            list.innerHTML = `<p class="empty">No documents found with status "${currentStatus}"</p>`;
            return;
        }

        list.innerHTML = docs.map(doc => `
            <div class="doc-card" onclick="viewDocument(${doc.id})">
                <div>
                    <h3 style="margin: 0 0 0.5rem 0">${doc.title}</h3>
                    <p style="margin: 0; color: #64748b; font-size: 0.9rem">${doc.vendor} • $${doc.amount}</p>
                </div>
                <span class="status-badge ${doc.status}">${doc.status}</span>
            </div>
        `).join('');
    } catch (err) {
        console.error(err);
        list.innerHTML = '<p class="error">Failed to load documents</p>';
    }
}

function filterStatus(status) {
    currentStatus = status;
    document.querySelectorAll('.filter-btn').forEach(btn => btn.classList.remove('active'));
    document.querySelector(`button[data-status="${status}"]`).classList.add('active');
    loadDocuments();
}

// Upload Logic
async function handleUpload(e) {
    e.preventDefault();
    console.log('Upload initiated');

    const title = document.getElementById('upload-title').value;
    const vendor = document.getElementById('upload-vendor').value;
    const amount = document.getElementById('upload-amount').value;
    const date = document.getElementById('upload-date').value;

    if (!title || !vendor || !amount || !date) {
        return alert('Please fill in all fields.');
    }

    try {
        console.log(`Sending upload to ${API_URL}/documents`);
        const res = await fetch(`${API_URL}/documents`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                title,
                vendor,
                amount: parseFloat(amount) || 0,
                date
            })
        });

        if (res.ok) {
            alert('Document uploaded successfully');
            document.querySelector('#upload-page form').reset();
            showPage('inbox');
        } else {
            const txt = await res.text();
            console.error('Upload failed', res.status, txt);
            alert(`Upload failed: ${txt}`);
        }
    } catch (err) {
        console.error('Network error:', err);
        alert('Network Error: ' + err.message);
    }
}

// Detail Logic
async function viewDocument(id) {
    currentDocId = id;
    showPage('detail');

    try {
        const res = await fetch(`${API_URL}/documents/${id}`);
        const data = await res.json();

        // Populate Meta
        document.getElementById('detail-title').innerText = data.title;
        document.getElementById('detail-status').innerText = data.status;
        document.getElementById('detail-status').className = `status-badge ${data.status}`;
        document.getElementById('detail-vendor').innerText = data.vendor;
        document.getElementById('detail-amount').innerText = `$${parseFloat(data.amount).toFixed(2)}`;
        document.getElementById('detail-date').innerText = new Date(data.created_at).toLocaleDateString();

        // Populate Extracted
        if (data.extracted) {
            document.getElementById('extract-inv').innerText = data.extracted.invoice_number;
            document.getElementById('extract-conf').innerText = `${(data.extracted.confidence * 100).toFixed(0)}%`;
        }

        // Available Actions based on Status
        const actionsDiv = document.getElementById('workflow-actions');
        actionsDiv.innerHTML = '';

        if (data.status === 'New' || data.status === 'Processing' || data.status === 'NeedsReview') {
            actionsDiv.innerHTML += `
                <button onclick="performAction('approve')" class="action-btn approve-btn">Approve</button>
                <button onclick="performAction('reject')" class="action-btn reject-btn">Reject</button>
            `;
        } else if (data.status === 'Approved') {
            actionsDiv.innerHTML += `
                <button onclick="performAction('deliver')" class="action-btn deliver-btn">Deliver (Email/Fax)</button>
            `;
        }

        // Populate Audit
        const auditList = document.getElementById('audit-list');
        auditList.innerHTML = data.audit.map(log => `
            <li>
                <span class="audit-action">${log.action}</span>
                <span>${log.details}</span>
                <span class="audit-time">${new Date(log.created_at).toLocaleTimeString()}</span>
            </li>
        `).join('');

    } catch (err) { console.error(err); }
}

async function performAction(action) {
    if (!confirm(`Are you sure you want to ${action} this document?`)) return;

    try {
        const res = await fetch(`${API_URL}/documents/${currentDocId}/${action}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ actor: 'student-demo' })
        });

        if (res.ok) {
            // refresh
            viewDocument(currentDocId);
        } else {
            alert('Action failed');
        }
    } catch (err) { console.error(err); }
}

// Init
loadDocuments();
