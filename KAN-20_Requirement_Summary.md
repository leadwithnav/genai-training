# KAN-20 Checkout API Requirement Summary

## Feature under test
Checkout API - Validate request and place order for logged-in users (CARD/UPI)

## In scope
*   **API Endpoint:** `POST /api/v1/checkout`
*   **Authentication:** Logged-in users only (`Authorization: Bearer <token>`)
*   **Payment Methods:** Card, UPI
*   **Validation:**
    *   Missing required fields
    *   Invalid/expired token
    *   Empty cart
    *   Quantity exceeding stock
    *   `clientTotal` mismatch with server-calculated total
*   **Functionality:**
    *   Create a single order upon valid request
    *   Idempotency handling (duplicate submission prevention)
    *   Standard API error responses
*   **Release:** 2.4

## Out of scope
*   Guest checkout
*   Cash on Delivery (COD) payment method
*   Deep integration adjustments with Payment Gateway Providers
*   Mobile application changes
*   Performance/load optimization
*   UI functional redesign

## Acceptance criteria
1.  **Successful Order:** Valid checkout request for logged-in user using CARD or UPI creates a single order successfully.
2.  **Field Validation:** Requests with missing required fields are rejected with a validation error.
3.  **Auth Validation:** Requests with an invalid or expired token are rejected.
4.  **Payment Method:** Unsupported payment methods (e.g., COD) are rejected.
5.  **Cart Validation:** Checkout with an empty cart is rejected.
6.  **Stock Validation:** Checkout with quantity exceeding available stock is rejected.
7.  **Total Validation:** `clientTotal` mismatch with server-calculated total is rejected.

## Business rules
*   **Payment Methods:** Only CARD and UPI are supported. COD is explicitly not supported in this release.
*   **Authentication:** User must be logged in to place an order.
*   **Data Integrity:** Server must validate the `clientTotal` against its own calculation to prevent price manipulation.
*   **Inventory:** Stock must be validated before confirming the order.
*   **Idempotency:** Repeated requests with the same idempotency key must be handled to prevent duplicate orders.
*   **Error Handling:** Must use a standard API error schema for client teams.

## Technical/API details
*   **Endpoint:** `POST /api/v1/checkout`
*   **Method:** `POST`
*   **Headers:**
    *   `Content-Type: application/json`
    *   `Authorization: Bearer <token>`
*   **Environment:** QA / Staging

## Sample data / payload / responses

> **Note:** Exact JSON schema structure is inferred from requirements as the sample image was not accessible.

### **Sample Request Payload**
```json
{
  "cartId": "c12345",
  "paymentMethod": "CARD",
  "clientTotal": 150.00,
  "currency": "USD",
  "idempotencyKey": "uuid-gen-1234-5678",
  "billingAddress": {
    "street": "123 Main St",
    "city": "Tech City",
    "zip": "10001"
  },
  "paymentDetails": {
    "cardNumber": "1234-5678-9012-3456",
    "expiry": "12/28",
    "cvv": "123"
  }
}
```

### **Success Response (201 Created)**
```json
{
  "orderId": "ord-98765",
  "status": "CONFIRMED",
  "message": "Order placed successfully"
}
```

### **Error Response (400 Bad Request - Validation Error)**
```json
{
  "error": "VALIDATION_ERROR",
  "message": "clientTotal mismatch",
  "details": {
    "clientTotal": 150.00,
    "serverTotal": 155.00
  }
}
```
