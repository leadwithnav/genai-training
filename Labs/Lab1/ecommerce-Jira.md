# E-Commerce Platform — Jira Epics & Stories

**Project:** GenAI E-Commerce Store (Upland Training)
**Project Key:** EC
**Created:** 2026-02-18
**Author:** Training Team

---

## Project Overview

A containerized e-commerce web application built for the "GenAI for Software Testers" training program. The system allows users to browse Upland Software products, manage a shopping cart, process orders via a wallet-based payment system, and manage order lifecycle (cancel, return, refund).

---

## Assumptions

1. The application is a **demo/training system** — not a production e-commerce platform.
2. **No real payment gateway** is integrated; a wallet system simulates funds.
3. **No real user authentication** — session IDs are used to identify users.
4. **No real file uploads** — product images are sourced from Unsplash URLs.
5. Products represent **Upland Software solutions** (AccuRoute, FileBound, etc.) for thematic alignment.
6. The system runs locally via **Docker Compose** on student laptops.
7. Database is **PostgreSQL** pre-seeded with products and initial data.
8. All prices are in **USD**.
9. Cart and wallet data persist per session ID (browser session).
10. The application is accessible at `http://localhost:3000` (UI) and `http://localhost:8081` (API).

---

## Constraints

- Must run with a single `docker compose up -d` command.
- Must work on Windows with Docker Desktop.
- UI must be simple HTML/JS (no complex frontend framework).
- API must be Node.js + Express.
- Database must be PostgreSQL.

---

## Epics

| Epic ID | Epic Name | Description |
|---------|-----------|-------------|
| EC-E1 | Product Catalog | Display and manage the product listing |
| EC-E2 | Shopping Cart | Add, update, and remove items from cart |
| EC-E3 | Wallet & Payments | Manage user wallet balance and checkout |
| EC-E4 | Order Management | Place, view, cancel, and return orders |
| EC-E5 | Infrastructure & DevOps | Containerization, DB setup, and deployment |
| EC-E6 | UI/UX & Navigation | Overall app layout, navigation, and styling |

---

## EC-E1: Product Catalog

**Goal:** Allow users to browse Upland Software products with descriptions and pricing.

**Acceptance Criteria:**
- Products are displayed in a responsive grid layout.
- Each product card shows: name, description, price, and image.
- Products are loaded from the database via API.
- Page loads within 2 seconds under normal conditions.

---

### EC-101 — Display Product Listing

**Type:** Story
**Priority:** High
**Story Points:** 3

**As a** user,
**I want to** see a list of available products on the home page,
**So that** I can browse what's available to purchase.

**Acceptance Criteria:**
- [ ] Products are displayed in a card grid (min 2 columns on desktop).
- [ ] Each card shows: product name, description, price (formatted as `$X.XX`), and image.
- [ ] Cards have a hover animation (lift effect).
- [ ] An "Add to Cart" button is visible on each card.
- [ ] If no products exist, a friendly empty state message is shown.

**API Dependency:** `GET /api/products`

---

### EC-102 — Load Products from Database

**Type:** Story
**Priority:** High
**Story Points:** 2

**As a** developer,
**I want to** serve product data from the PostgreSQL database via the API,
**So that** the frontend can display real product information.

**Acceptance Criteria:**
- [ ] `GET /api/products` returns all products as JSON.
- [ ] Response includes: `id`, `name`, `description`, `price`, `image_url`.
- [ ] Database is pre-seeded with at least 8 Upland Software products.
- [ ] API returns HTTP 200 on success.
- [ ] API returns HTTP 500 with error message on DB failure.

**DB Table:** `products`

---

### EC-103 — Seed Upland Software Products

**Type:** Story
**Priority:** High
**Story Points:** 1

**As a** trainer,
**I want to** have Upland Software products pre-loaded in the database,
**So that** students see relevant, themed content during training.

**Acceptance Criteria:**
- [ ] At least 8 Upland products seeded: AccuRoute, Adestra, BA Insight, Cimpl, Eclipse PPM, FileBound, InGenius, Kapost.
- [ ] Each product has a name, description, price, and image URL.
- [ ] Seed runs automatically on first `docker compose up`.
- [ ] Re-running seed does not create duplicates.

---

## EC-E2: Shopping Cart

**Goal:** Allow users to manage items in their cart before checkout.

**Acceptance Criteria:**
- Users can add products to cart.
- Users can increase/decrease item quantity.
- Users can remove items from cart.
- Cart count is shown in the navigation header.
- Cart persists within the same browser session.

---

### EC-201 — Add Item to Cart

**Type:** Story
**Priority:** High
**Story Points:** 3

**As a** user,
**I want to** add a product to my cart,
**So that** I can purchase it later.

**Acceptance Criteria:**
- [ ] Clicking "Add to Cart" on a product card adds it to the cart.
- [ ] If the item already exists in the cart, its quantity is incremented by 1.
- [ ] Cart count in the header updates immediately after adding.
- [ ] A success indicator (alert or toast) confirms the item was added.
- [ ] The cart persists the item when navigating to other pages.

**API Dependency:** `POST /api/cart`
**Request Body:** `{ sessionId, productId, quantity }`

---

### EC-202 — View Cart Contents

**Type:** Story
**Priority:** High
**Story Points:** 3

**As a** user,
**I want to** view all items in my cart,
**So that** I can review my selections before checkout.

**Acceptance Criteria:**
- [ ] Cart page shows all items with: product image, name, quantity, unit price, and line total.
- [ ] Cart shows the overall total at the bottom.
- [ ] If cart is empty, a message "Your cart is empty" is shown.
- [ ] Cart count in header reflects the total number of items (sum of quantities).

**API Dependency:** `GET /api/cart/:sessionId`

---

### EC-203 — Update Item Quantity in Cart

**Type:** Story
**Priority:** High
**Story Points:** 3

**As a** user,
**I want to** increase or decrease the quantity of an item in my cart,
**So that** I can adjust my order without removing and re-adding items.

**Acceptance Criteria:**
- [ ] Each cart item has a `+` button to increase quantity by 1.
- [ ] Each cart item has a `-` button to decrease quantity by 1.
- [ ] Decreasing quantity to 0 triggers item removal (with confirmation).
- [ ] Cart total updates immediately after quantity change.
- [ ] Cart count in header updates immediately.

**API Dependency:** `PUT /api/cart`
**Request Body:** `{ sessionId, productId, quantity }`

---

### EC-204 — Remove Item from Cart

**Type:** Story
**Priority:** High
**Story Points:** 2

**As a** user,
**I want to** remove an item from my cart,
**So that** I can change my mind about a purchase.

**Acceptance Criteria:**
- [ ] Each cart item has a "Remove" button.
- [ ] Clicking "Remove" shows a confirmation prompt.
- [ ] On confirmation, the item is removed from the cart.
- [ ] Cart total and header count update immediately.
- [ ] If the last item is removed, the empty cart message is shown.

**API Dependency:** `DELETE /api/cart/:sessionId/item/:productId`

---

### EC-205 — Display Cart Count in Header

**Type:** Story
**Priority:** Medium
**Story Points:** 1

**As a** user,
**I want to** see the number of items in my cart in the navigation bar,
**So that** I always know how many items I have without opening the cart.

**Acceptance Criteria:**
- [ ] Cart count is shown next to the "Cart" link in the header.
- [ ] Count reflects the total quantity of all items (not unique items).
- [ ] Count updates dynamically when items are added, removed, or quantity changes.
- [ ] Count shows `0` when cart is empty.
- [ ] Count is fetched on page load.

---

## EC-E3: Wallet & Payments

**Goal:** Allow users to manage a virtual wallet and use it to pay for orders.

**Acceptance Criteria:**
- Users can view their wallet balance.
- Users can add funds to their wallet.
- Checkout deducts the order total from the wallet.
- Insufficient funds prevents checkout and prompts user to add money.
- All wallet transactions are logged.

---

### EC-301 — View Wallet Balance

**Type:** Story
**Priority:** High
**Story Points:** 2

**As a** user,
**I want to** see my current wallet balance,
**So that** I know how much money I have available to spend.

**Acceptance Criteria:**
- [ ] Wallet page displays current balance formatted as `$X.XX`.
- [ ] Balance is fetched from the API on page load.
- [ ] Transaction history is shown (amount, type, date).
- [ ] If no wallet exists for the session, balance shows `$0.00`.

**API Dependency:** `GET /api/wallet/:sessionId`

---

### EC-302 — Add Funds to Wallet

**Type:** Story
**Priority:** High
**Story Points:** 2

**As a** user,
**I want to** add money to my wallet,
**So that** I can make purchases in the store.

**Acceptance Criteria:**
- [ ] Wallet page has an input field for amount and an "Add Funds" button.
- [ ] Clicking "Add Funds" with a valid amount updates the balance.
- [ ] Balance updates immediately on the page after adding funds.
- [ ] Transaction is recorded in `wallet_transactions` table.
- [ ] Negative or zero amounts are rejected with a validation message.
- [ ] Maximum single top-up is $10,000.

**API Dependency:** `POST /api/wallet/add`
**Request Body:** `{ sessionId, amount }`

---

### EC-303 — Checkout with Wallet Confirmation Modal

**Type:** Story
**Priority:** High
**Story Points:** 5

**As a** user,
**I want to** see a confirmation modal before paying,
**So that** I can review the deduction from my wallet before committing.

**Acceptance Criteria:**
- [ ] Clicking "Checkout" opens a modal (not a new page).
- [ ] Modal shows: Current Balance, Order Total (as deduction), Remaining Balance.
- [ ] If balance is sufficient: "Confirm Payment" button is shown.
- [ ] If balance is insufficient: "Add Funds" button is shown instead.
- [ ] "Cancel" button closes the modal without any action.
- [ ] Confirming payment deducts the amount and creates the order.
- [ ] On success, user is redirected to an order success page.

**API Dependency:** `POST /api/checkout`
**Request Body:** `{ sessionId, total }`

---

### EC-304 — Handle Insufficient Funds

**Type:** Story
**Priority:** High
**Story Points:** 2

**As a** user,
**I want to** be informed when I don't have enough funds,
**So that** I can add money before attempting checkout again.

**Acceptance Criteria:**
- [ ] If wallet balance < order total, the "Confirm Payment" button is hidden.
- [ ] An "Add Funds" button is shown in the modal.
- [ ] Remaining balance is displayed in red to indicate a deficit.
- [ ] Clicking "Add Funds" navigates to the Wallet page.
- [ ] API returns `{ code: "INSUFFICIENT_FUNDS" }` with HTTP 400.

---

### EC-305 — Log Wallet Transactions

**Type:** Story
**Priority:** Medium
**Story Points:** 2

**As a** developer,
**I want to** record all wallet transactions,
**So that** there is an audit trail of all financial activity.

**Acceptance Criteria:**
- [ ] Every `add funds` action creates a record in `wallet_transactions`.
- [ ] Every `purchase` creates a negative transaction record.
- [ ] Every `refund` (cancel/return) creates a positive transaction record.
- [ ] Each record includes: `session_id`, `amount`, `type`, `timestamp`.

---

## EC-E4: Order Management

**Goal:** Allow users to view, cancel, and return their orders with appropriate refunds.

**Acceptance Criteria:**
- Users can view their order history.
- Users can cancel a "placed" order and receive a refund.
- Users can return a "delivered" order and receive a refund.
- Order status transitions are clearly shown.

---

### EC-401 — View Order History

**Type:** Story
**Priority:** High
**Story Points:** 3

**As a** user,
**I want to** see a list of my past orders,
**So that** I can track what I've purchased.

**Acceptance Criteria:**
- [ ] Orders page shows all orders for the current session.
- [ ] Each order shows: Order ID, Total, Status, Date.
- [ ] Orders are sorted by most recent first.
- [ ] Status is displayed as a colored badge: placed (blue), delivered (green), cancelled (red), returned (grey).
- [ ] If no orders exist, a friendly message is shown.

**API Dependency:** `GET /api/orders/:sessionId`

---

### EC-402 — Cancel a Placed Order

**Type:** Story
**Priority:** High
**Story Points:** 3

**As a** user,
**I want to** cancel an order that hasn't been delivered yet,
**So that** I can get a refund if I change my mind.

**Acceptance Criteria:**
- [ ] A "Cancel" button is shown only for orders with status `placed`.
- [ ] Clicking "Cancel" shows a confirmation prompt.
- [ ] On confirmation, order status changes to `cancelled`.
- [ ] Refund is automatically added to the user's wallet.
- [ ] A wallet transaction record is created for the refund.
- [ ] The order list refreshes to show the updated status.

**API Dependency:** `POST /api/orders/:orderId/cancel`

---

### EC-403 — Simulate Order Delivery

**Type:** Story
**Priority:** Medium
**Story Points:** 1

**As a** tester/trainer,
**I want to** simulate an order being delivered,
**So that** I can test the return/refund flow without waiting for real delivery.

**Acceptance Criteria:**
- [ ] A "Simulate Delivery" button is shown for orders with status `placed`.
- [ ] Clicking it changes the order status to `delivered`.
- [ ] The button is clearly labeled as a simulation (for training purposes).
- [ ] The order list refreshes to show the updated status.

**API Dependency:** `POST /api/orders/:orderId/deliver`

---

### EC-404 — Return a Delivered Order

**Type:** Story
**Priority:** High
**Story Points:** 3

**As a** user,
**I want to** return an order that has been delivered,
**So that** I can get a refund if I'm not satisfied.

**Acceptance Criteria:**
- [ ] A "Return / Refund" button is shown only for orders with status `delivered`.
- [ ] Clicking it shows a confirmation prompt.
- [ ] On confirmation, order status changes to `returned`.
- [ ] Refund is automatically added to the user's wallet.
- [ ] A wallet transaction record is created for the refund.
- [ ] The order list refreshes to show the updated status.

**API Dependency:** `POST /api/orders/:orderId/return`

---

### EC-405 — Order Success Page

**Type:** Story
**Priority:** Medium
**Story Points:** 2

**As a** user,
**I want to** see a confirmation page after placing an order,
**So that** I know my order was successfully placed.

**Acceptance Criteria:**
- [ ] After successful checkout, user is redirected to a success page.
- [ ] Success page shows the Order ID.
- [ ] A "Continue Shopping" button navigates back to the product listing.
- [ ] Cart is cleared after successful checkout.
- [ ] Cart count in header resets to 0.

---

## EC-E5: Infrastructure & DevOps

**Goal:** Ensure the application can be started, stopped, and reset with simple commands.

---

### EC-501 — Docker Compose Setup

**Type:** Story
**Priority:** High
**Story Points:** 3

**As a** student/trainer,
**I want to** start the entire application with one command,
**So that** I don't need to manually configure services.

**Acceptance Criteria:**
- [ ] `docker compose up -d` starts all services: web, api, db.
- [ ] Web UI is accessible at `http://localhost:3000`.
- [ ] API is accessible at `http://localhost:8081`.
- [ ] Database is accessible at `localhost:5432`.
- [ ] API waits for DB to be healthy before starting (healthcheck).
- [ ] Services restart automatically on failure (`restart: always`).

---

### EC-502 — Database Initialization & Seeding

**Type:** Story
**Priority:** High
**Story Points:** 2

**As a** developer,
**I want to** have the database schema and seed data created automatically,
**So that** the app works immediately after `docker compose up`.

**Acceptance Criteria:**
- [ ] `db/init.sql` creates all required tables on first run.
- [ ] Tables created: `products`, `cart_items`, `orders`, `wallets`, `wallet_transactions`.
- [ ] Seed data includes at least 8 Upland products.
- [ ] Re-running does not fail or create duplicate data.

---

### EC-503 — API Health Check Endpoint

**Type:** Story
**Priority:** Medium
**Story Points:** 1

**As a** developer/tester,
**I want to** verify the API and database are running,
**So that** I can quickly diagnose connectivity issues.

**Acceptance Criteria:**
- [ ] `GET /health` returns `{ status: "ok", db: "connected" }` when healthy.
- [ ] Returns HTTP 200 on success.
- [ ] Returns HTTP 500 with error details if DB is unreachable.

---

### EC-504 — PowerShell Helper Scripts

**Type:** Story
**Priority:** Medium
**Story Points:** 2

**As a** student on Windows,
**I want to** have simple scripts to start, stop, and reset the environment,
**So that** I don't need to remember Docker commands.

**Acceptance Criteria:**
- [ ] `start.ps1`: Runs `docker compose up -d` and prints URLs.
- [ ] `reset.ps1`: Runs `docker compose down -v` then `docker compose up -d`.
- [ ] `verify_tools.ps1`: Checks Docker is installed and ports 3000/8081 are free.
- [ ] Scripts are in the `setup/windows/` directory.

---

## EC-E6: UI/UX & Navigation

**Goal:** Provide a clean, professional, and easy-to-navigate user interface.

---

### EC-601 — Application Navigation

**Type:** Story
**Priority:** High
**Story Points:** 2

**As a** user,
**I want to** navigate between different sections of the app,
**So that** I can access products, cart, orders, and wallet easily.

**Acceptance Criteria:**
- [ ] Header navigation links: Solutions, My Requests, Budget (Wallet), Quote Cart.
- [ ] Active page is visually indicated.
- [ ] Navigation works without page reload (single-page app behavior).
- [ ] Cart count is always visible in the header.

---

### EC-602 — Responsive Layout

**Type:** Story
**Priority:** Medium
**Story Points:** 2

**As a** user,
**I want to** use the app on different screen sizes,
**So that** it works well on both laptops and larger monitors.

**Acceptance Criteria:**
- [ ] Product grid adapts from 1 column (mobile) to 3+ columns (desktop).
- [ ] Cart items stack vertically on small screens.
- [ ] Navigation is readable on all screen sizes.
- [ ] No horizontal scrollbar on standard laptop screens (1280px+).

---

### EC-603 — Checkout Confirmation Modal

**Type:** Story
**Priority:** High
**Story Points:** 3

**As a** user,
**I want to** see a modal before confirming payment,
**So that** I don't accidentally place an order.

**Acceptance Criteria:**
- [ ] Modal appears over the page with a dark overlay.
- [ ] Modal shows financial summary: balance, deduction, remaining.
- [ ] Modal has "Confirm", "Cancel", and optionally "Add Funds" buttons.
- [ ] Clicking outside the modal or "Cancel" closes it.
- [ ] Modal is accessible (keyboard navigable).

---

## Story Summary

| Story ID | Title | Epic | Priority | Points |
|----------|-------|------|----------|--------|
| EC-101 | Display Product Listing | EC-E1 | High | 3 |
| EC-102 | Load Products from Database | EC-E1 | High | 2 |
| EC-103 | Seed Upland Software Products | EC-E1 | High | 1 |
| EC-201 | Add Item to Cart | EC-E2 | High | 3 |
| EC-202 | View Cart Contents | EC-E2 | High | 3 |
| EC-203 | Update Item Quantity in Cart | EC-E2 | High | 3 |
| EC-204 | Remove Item from Cart | EC-E2 | High | 2 |
| EC-205 | Display Cart Count in Header | EC-E2 | Medium | 1 |
| EC-301 | View Wallet Balance | EC-E3 | High | 2 |
| EC-302 | Add Funds to Wallet | EC-E3 | High | 2 |
| EC-303 | Checkout with Wallet Confirmation Modal | EC-E3 | High | 5 |
| EC-304 | Handle Insufficient Funds | EC-E3 | High | 2 |
| EC-305 | Log Wallet Transactions | EC-E3 | Medium | 2 |
| EC-401 | View Order History | EC-E4 | High | 3 |
| EC-402 | Cancel a Placed Order | EC-E4 | High | 3 |
| EC-403 | Simulate Order Delivery | EC-E4 | Medium | 1 |
| EC-404 | Return a Delivered Order | EC-E4 | High | 3 |
| EC-405 | Order Success Page | EC-E4 | Medium | 2 |
| EC-501 | Docker Compose Setup | EC-E5 | High | 3 |
| EC-502 | Database Initialization & Seeding | EC-E5 | High | 2 |
| EC-503 | API Health Check Endpoint | EC-E5 | Medium | 1 |
| EC-504 | PowerShell Helper Scripts | EC-E5 | Medium | 2 |
| EC-601 | Application Navigation | EC-E6 | High | 2 |
| EC-602 | Responsive Layout | EC-E6 | Medium | 2 |
| EC-603 | Checkout Confirmation Modal | EC-E6 | High | 3 |

**Total Story Points: 58**

---

## Definition of Done

A story is considered **Done** when:
1. ✅ Code is implemented and working locally.
2. ✅ All acceptance criteria are met.
3. ✅ API endpoint (if applicable) returns correct response codes.
4. ✅ UI reflects the expected behavior.
5. ✅ No console errors in the browser.
6. ✅ Feature works after `docker compose down -v && docker compose up -d` (fresh start).

---

## Out of Scope (for this training version)

- Real user authentication / login system.
- Real payment gateway (Stripe, PayPal, etc.).
- Email notifications.
- Product search or filtering.
- Admin panel for managing products.
- Multi-currency support.
- Real file/image uploads.
- Mobile app.
