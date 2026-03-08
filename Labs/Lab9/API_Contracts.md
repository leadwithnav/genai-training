# Ecommerce API Contracts

This document outlines the API contracts for the Ecommerce application, detailing endpoints, request structures, and expected responses.

Base URL: `http://localhost:8081`

---

## 1. Health Check
*   **Endpoint:** `/health`
*   **Method:** `GET`
*   **Description:** Checks the health status of the API and database connection.

### Response
*   **Status:** `200 OK`
*   **Body:**
```json
{
  "status": "ok",
  "timestamp": "2024-03-03T10:00:00.000Z"
}
```

---

## 2. Get All Products
*   **Endpoint:** `/api/products`
*   **Method:** `GET`
*   **Description:** Retrieves a list of all available products.

### Response
*   **Status:** `200 OK`
*   **Body:**
```json
[
  {
    "id": 1,
    "name": "Quantum Keyboard",
    "description": "Mechanical keyboard with quantum switches for instant actuation.",
    "price": "199.99",
    "image_url": "https://images.unsplash.com/photo-1595225476474-87563907a212?w=500&q=80"
  },
  {
    "id": 2,
    "name": "Neural Headset",
    "description": "AI-powered noise cancellation that adapts to your brainwaves.",
    "price": "299.99",
    "image_url": "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500&q=80"
  }
]
```

---

## 3. Get Product by ID
*   **Endpoint:** `/api/products/:id`
*   **Method:** `GET`
*   **Description:** Retrieves details for a specific product.

### Parameters
*   `id` (path): The unique identifier of the product.

### Response
*   **Status:** `200 OK`
*   **Body:**
```json
{
  "id": 1,
  "name": "Quantum Keyboard",
  "description": "Mechanical keyboard with quantum switches for instant actuation.",
  "price": "199.99",
  "image_url": "https://images.unsplash.com/photo-1595225476474-87563907a212?w=500&q=80"
}
```
*   **If not found:**
    *   **Status:** `404 Not Found`
    *   **Body:** `Product not found`

---

## 4. Get Cart Items
*   **Endpoint:** `/api/cart/:sessionId`
*   **Method:** `GET`
*   **Description:** Retrieves all items currently in the user's cart.

### Parameters
*   `sessionId` (path): The unique session identifier for the user.

### Response
*   **Status:** `200 OK`
*   **Body:**
```json
[
  {
    "id": 101,
    "product_id": 1,
    "quantity": 2,
    "name": "Quantum Keyboard",
    "price": "199.99",
    "image_url": "https://images.unsplash.com/photo-1595225476474-87563907a212?w=500&q=80"
  }
]
```

---

## 5. Add Item to Cart
*   **Endpoint:** `/api/cart`
*   **Method:** `POST`
*   **Description:** Adds a product to the cart or increments quantity if it already exists.

### Request Body
```json
{
  "sessionId": "sess_abc123",
  "productId": 1,
  "quantity": 1
}
```

### Response
*   **Status:** `200 OK`
*   **Body:**
```json
{
  "success": true
}
```

---

## 6. Update Cart Item Quantity
*   **Endpoint:** `/api/cart`
*   **Method:** `PUT`
*   **Description:** Updates the quantity of a specific product in the cart. If quantity is <= 0, the item is removed.

### Request Body
```json
{
  "sessionId": "sess_abc123",
  "productId": 1,
  "quantity": 3
}
```

### Response
*   **Status:** `200 OK`
*   **Body:**
```json
{
  "success": true
}
```
*   **If item not found:**
    *   **Status:** `404 Not Found`
    *   **Body:** `Item not found`

---

## 7. Remove Item from Cart
*   **Endpoint:** `/api/cart/:sessionId/item/:productId`
*   **Method:** `DELETE`
*   **Description:** Removes a specific product from the cart completely.

### Parameters
*   `sessionId` (path): User's session ID.
*   `productId` (path): Product ID to remove.

### Response
*   **Status:** `200 OK`
*   **Body:**
```json
{
  "success": true
}
```

---

## 8. Clear Cart
*   **Endpoint:** `/api/cart/:sessionId`
*   **Method:** `DELETE`
*   **Description:** Removes all items from the cart for the given session.

### Parameters
*   `sessionId` (path): User's session ID.

### Response
*   **Status:** `200 OK`
*   **Body:**
```json
{
  "success": true
}
```

---

## 9. Checkout
*   **Endpoint:** `/api/checkout`
*   **Method:** `POST`
*   **Description:** Processes the order, deducts total from wallet, and clears the cart.

### Request Body
```json
{
  "sessionId": "sess_abc123",
  "total": 199.99
}
```

### Response
*   **Status:** `201 Created`
*   **Body:**
```json
{
  "success": true,
  "orderId": 501,
  "message": "Order placed successfully"
}
```
*   **Error (Insufficient Funds):**
    *   **Status:** `400 Bad Request`
    *   **Body:**
    ```json
    {
      "success": false,
      "message": "Insufficient funds in wallet",
      "code": "INSUFFICIENT_FUNDS"
    }
    ```

---

## 10. Get User Orders
*   **Endpoint:** `/api/orders/:sessionId`
*   **Method:** `GET`
*   **Description:** Retrieves a history of orders for the user.

### Parameters
*   `sessionId` (path): User's session ID.

### Response
*   **Status:** `200 OK`
*   **Body:**
```json
[
  {
    "id": 501,
    "session_id": "sess_abc123",
    "total": "199.99",
    "status": "placed",
    "created_at": "2024-03-03T10:05:00.000Z"
  }
]
```

---

## 11. Cancel Order
*   **Endpoint:** `/api/orders/:orderId/cancel`
*   **Method:** `POST`
*   **Description:** Cancels an order if its status is 'placed' and refunds the amount to the wallet.

### Parameters
*   `orderId` (path): The ID of the order to cancel.

### Response
*   **Status:** `200 OK`
*   **Body:**
```json
{
  "success": true,
  "message": "Order cancelled and refunded to wallet"
}
```
*   **Error (Invalid Status):**
    *   **Status:** `400 Bad Request`
    *   **Body:** `Cannot cancel order unless status is placed`

---

## 12. Mark Order as Delivered (Simulated)
*   **Endpoint:** `/api/orders/:orderId/deliver`
*   **Method:** `POST`
*   **Description:** Updates the order status to 'delivered'.

### Parameters
*   `orderId` (path): The ID of the order.

### Response
*   **Status:** `200 OK`
*   **Body:**
```json
{
  "success": true,
  "message": "Order marked as delivered"
}
```

---

## 13. Return Order
*   **Endpoint:** `/api/orders/:orderId/return`
*   **Method:** `POST`
*   **Description:** Processes a return for an order and refunds the amount to the wallet.

### Parameters
*   `orderId` (path): The ID of the order to return.

### Response
*   **Status:** `200 OK`
*   **Body:**
```json
{
  "success": true,
  "message": "Order returned and refunded to wallet"
}
```
*   **Error (Already Processed):**
    *   **Status:** `400 Bad Request`
    *   **Body:** `Order already cancelled or returned`
