# GenAI E-commerce Store

This project is a mock e-commerce application designed for training software testers on Generative AI tools. It includes a frontend store, backend API, and database.

## Quick Start

1.  **Navigate to the directory**:
    ```bash
    cd ecommerce
    ```
2.  **Start the Application**:
    ```bash
    docker compose up -d --build
    ```
3.  **Access the App**:
    - **Storefront**: http://localhost:3000
    - **API**: http://localhost:8081
    - **API Health Check**: http://localhost:8081/health

4.  **Stop/Reset**:
    ```bash
    docker compose down -v
    ```

## Features for Testing

-   **Shopping Flux**: Browse products, add to cart, update quantity, remove items.
-   **Checkout**: Wallet-based checkout system with validation.
-   **Order Management**: View history, cancel orders, simulate delivery, return/refund.
-   **Wallet**: Add funds, view balance, transaction logging.
-   **Database**: Postgres with pre-seeded data.

## API Documentation

The API runs on port `8081` and supports the following endpoints:

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/products` | List all products |
| `GET` | `/api/cart/:sessionId` | Get cart contents |
| `POST` | `/api/cart` | Add item to cart |
| `PUT` | `/api/cart` | Update item quantity |
| `DELETE` | `/api/cart/:sessionId/item/:productId` | Remove item |
| `POST` | `/api/checkout` | Place order |
| `GET` | `/api/orders/:sessionId` | Get order history |
| `POST` | `/api/orders/:orderId/cancel` | Cancel order |
| `POST` | `/api/orders/:orderId/deliver` | Mark as delivered (Simulated) |
| `POST` | `/api/orders/:orderId/return` | Return order |
| `GET` | `/api/wallet/:sessionId` | Get wallet balance |
| `POST` | `/api/wallet/add` | Add funds |

## Testing

### Playwright (UI)
Locate tests in the `../playwright` folder (relative to repo root).

### Postman (API)
Locate collection in `../postman` folder.

### Performance
Locate scripts in `../performance` folder.

## Troubleshooting

-   **Port Conflicts**: This app uses ports `3000` and `8081`. Ensure they are free.
    -   *Note*: The `upland_workflow` project also uses port `3000`. Stop one before starting the other.
-   **Database**: Uses port `5432`.
